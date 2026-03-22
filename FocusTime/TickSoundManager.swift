import Foundation
import AVFoundation

final class TickSoundManager {
    static let shared = TickSoundManager()

    private var player: AVAudioPlayer?

    private init() {
        prepare()
    }

    private func prepare() {
        guard let url = Bundle.main.url(forResource: "tick", withExtension: "wav") else {
            print("找不到 tick.wav")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.numberOfLoops = -1
        } catch {
            print("滴答音初始化失败: \(error.localizedDescription)")
        }
    }

    func startLoop(volume: Double) {
        guard let player else { return }

        let clampedVolume = max(0, min(1, volume))
        player.volume = Float(clampedVolume)

        if !player.isPlaying {
            player.currentTime = 0
            player.play()
        }
    }

    func updateVolume(_ volume: Double) {
        let clampedVolume = max(0, min(1, volume))
        player?.volume = Float(clampedVolume)
    }

    func stopTick() {
        player?.stop()
        player?.currentTime = 0
    }
}
