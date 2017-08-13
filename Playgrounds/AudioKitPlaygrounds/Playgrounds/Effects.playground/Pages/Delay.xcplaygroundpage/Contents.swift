//: ## Delay
//: Exploring the powerful effect of repeating sounds after
//: varying length delay times and feedback amounts
import AudioKitPlaygrounds
import AudioKit

let file = try AKAudioFile(readFileName: playgroundAudioFiles[0])

let player = try AKAudioPlayer(file: file)
player.looping = true

var delay = AKDelay(player)
delay.time = 0.01 // seconds
delay.feedback = 0.9 // Normalized Value 0 - 1
delay.dryWetMix = 0.6 // Normalized Value 0 - 1

AudioKit.output = delay
AudioKit.start()
player.play()

class PlaygroundView: AKPlaygroundView {

    var timeSlider: AKPropertySlider?
    var feedbackSlider: AKPropertySlider?
    var lowPassCutoffFrequencySlider: AKPropertySlider?
    var dryWetMixSlider: AKPropertySlider?

    override func setup() {
        addTitle("Delay")

        addSubview(AKResourcesAudioFileLoaderView(player: player, filenames: playgroundAudioFiles))

        timeSlider = AKPropertySlider(property: "Time", value: delay.time) { sliderValue in
            delay.time = sliderValue
        }
        addSubview(timeSlider)

        feedbackSlider = AKPropertySlider(property: "Feedback", value: delay.feedback) { sliderValue in
            delay.feedback = sliderValue
        }
        addSubview(feedbackSlider)

        lowPassCutoffFrequencySlider = AKPropertySlider(property: "Low Pass Cutoff",
                                                        value: delay.lowPassCutoff,
                                                        range: 0 ... 22_050
        ) { sliderValue in
            delay.lowPassCutoff = sliderValue
        }
        addSubview(lowPassCutoffFrequencySlider)

        dryWetMixSlider = AKPropertySlider(property: "Mix", value: delay.dryWetMix) { sliderValue in
            delay.dryWetMix = sliderValue
        }
        addSubview(dryWetMixSlider)

        let presets = ["Short", "Dense Long", "Electric Circuits"]
        addSubview(AKPresetLoaderView(presets: presets) { preset in
            switch preset {
            case "Short":
                delay.presetShortDelay()
            case "Dense Long":
                delay.presetDenseLongDelay()
            case "Electric Circuits":
                delay.presetElectricCircuitsDelay()
            default:
                break
            }
            self.updateUI()
        })
    }

    func updateUI() {
        timeSlider?.value = delay.time
        feedbackSlider?.value = delay.feedback
        lowPassCutoffFrequencySlider?.value = delay.lowPassCutoff
        dryWetMixSlider?.value = delay.dryWetMix
    }

}

import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = PlaygroundView()
