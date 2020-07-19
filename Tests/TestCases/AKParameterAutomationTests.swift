//
//  AKParameterAutomationTests.swift
//  iOSTestSuiteTests
//
//  Created by Taylor Holliday on 7/16/20.
//  Copyright © 2020 AudioKit. All rights reserved.
//

import XCTest
import AudioKit

class AKParameterAutomationTests: AKTestCase {

    func observerTest(automation: [AKParameterAutomationPoint], sampleTime: Float64) -> ([AUParameterAddress], [AUValue]) {

        let address = AUParameterAddress(42)

        var addresses: [AUParameterAddress] = []
        var values: [AUValue] = []

        let scheduleParameterBlock: AUScheduleParameterBlock = { (sampleTime, frameCount, address, value) in
            addresses.append(address)
            values.append(value)
        }

        let observer: AURenderObserver = automation.withUnsafeBufferPointer { automationPtr in
            AKParameterAutomationGetRenderObserver(address,
                                                   scheduleParameterBlock,
                                                   44100,
                                                   0, // start time
                                                   automationPtr.baseAddress!,
                                                   automation.count)
        }

        var timeStamp = AudioTimeStamp()
        timeStamp.mSampleTime = sampleTime

        observer(.unitRenderAction_PreRender, &timeStamp, 256, 0)

        return (addresses, values)
    }

    func testSimpleAutomation() throws {

        let automationPoints = [ AKParameterAutomationPoint(targetValue: 880, startTime: 0, rampDuration: 1.0) ]

        let (addresses, values) = observerTest(automation: automationPoints, sampleTime: 0)

        // order is: taper, skew, offset, value
        XCTAssertEqual(addresses, [ (UInt64(1)<<63) | 42,
                                    (UInt64(1)<<62) | 42,
                                    (UInt64(1)<<61) | 42,
                                    42])
        XCTAssertEqual(values, [1.0, 0.0, 0.0, 880.0])
    }

    func testPastAutomation() {

        let automationPoints = [ AKParameterAutomationPoint(targetValue: 880, startTime: 0, rampDuration: 0.1) ]

        let (addresses, values) = observerTest(automation: automationPoints, sampleTime: 44100)

        // If the automation is in the past, the value should be set to the final value.
        XCTAssertEqual(addresses, [42])
        XCTAssertEqual(values, [880.0])
    }

    func testPastAutomationTwo() {

        let automationPoints = [ AKParameterAutomationPoint(targetValue: 880, startTime: 0, rampDuration: 0.1),
                                 AKParameterAutomationPoint(targetValue: 440, startTime: 0.1, rampDuration: 0.1) ]

        let (addresses, values) = observerTest(automation: automationPoints, sampleTime: 44100)

        // If the automation is in the past, the value should be set to the final value.
        XCTAssertEqual(addresses, [42, 42])
        XCTAssertEqual(values, [880.0, 440.0])

    }

    func testFutureAutomation() {

        let automationPoints = [ AKParameterAutomationPoint(targetValue: 880, startTime: 1, rampDuration: 0.1) ]

        let (addresses, values) = observerTest(automation: automationPoints, sampleTime: 0)

        // If the automation is in the future, we should not get anything.
        XCTAssertEqual(addresses, [])
        XCTAssertEqual(values, [])
    }

    func testRecord() {

        let osc = AKOscillator(waveform: AKTable(.square), frequency: 400, amplitude: 0.0)
        AKManager.output = osc
        try! AKManager.start()
        osc.start()

        var values:[AUValue] = []

        osc.$frequency.recordAutomation { (event) in
            values.append(event.value)
        }

        RunLoop.main.run(until: Date().addingTimeInterval(1.0))

        osc.frequency = 800

        RunLoop.main.run(until: Date().addingTimeInterval(1.0))

        XCTAssertEqual(values, [800])

        osc.$frequency.stopRecording()

        osc.frequency = 500

        RunLoop.main.run(until: Date().addingTimeInterval(1.0))

        XCTAssertEqual(values, [800])
    }

    func testReplaceAutomation() {

        {
            let points = [ AKParameterAutomationPoint(targetValue: 440, startTime: 0, rampDuration: 0.1),
                           AKParameterAutomationPoint(targetValue: 880, startTime: 1, rampDuration: 0.1),
                           AKParameterAutomationPoint(targetValue: 440, startTime: 2, rampDuration: 0.1)]

            let events: [(Double, AUValue)] = [ (0.5, 100), (1.5, 200) ]

            let newPoints = AKReplaceAutomation(points: points,
                                                newPoints: events,
                                                startTime: 0.25,
                                                stopTime: 1.75)

            let expected = [ AKParameterAutomationPoint(targetValue: 440, startTime: 0, rampDuration: 0.1),
                             AKParameterAutomationPoint(targetValue: 100, startTime: 0.5, rampDuration: 0.01),
                             AKParameterAutomationPoint(targetValue: 200, startTime: 1.5, rampDuration: 0.01),
                             AKParameterAutomationPoint(targetValue: 440, startTime: 2, rampDuration: 0.1)]

            XCTAssertEqual(newPoints.count, 4)
            XCTAssertEqual(newPoints, expected)
        }();


        {
            let points = [ AKParameterAutomationPoint(targetValue: 440, startTime: 0, rampDuration: 0.1),
                           AKParameterAutomationPoint(targetValue: 880, startTime: 1, rampDuration: 0.1),
                           AKParameterAutomationPoint(targetValue: 440, startTime: 2, rampDuration: 0.1)]

            let events: [(Double, AUValue)] = [ ]

            let newPoints = AKReplaceAutomation(points: points,
                                                newPoints: events,
                                                startTime: 0,
                                                stopTime: 2)

            XCTAssertEqual(newPoints, [])
        }();

        {
            let points: [AKParameterAutomationPoint] = [ ]

            let events: [(Double, AUValue)] = [ (0.5, 100), (1.5, 200) ]

            let newPoints = AKReplaceAutomation(points: points,
                                                newPoints: events,
                                                startTime: 0,
                                                stopTime: 2)

            let expected = [ AKParameterAutomationPoint(targetValue: 100, startTime: 0.5, rampDuration: 0.01),
                             AKParameterAutomationPoint(targetValue: 200, startTime: 1.5, rampDuration: 0.01)]

            XCTAssertEqual(newPoints, expected)
        }()
    }
}