import Foundation

#if os(macOS)
import AppKit
#endif

final class SystemSoundManager {
    static let shared = SystemSoundManager()

    #if os(macOS)
    private var currentSound: NSSound?
    #endif

    private init() {}

    func playSystemSound(named name: String, loop: Bool = false) {
        #if os(macOS)
        stopSound()

        guard name != "None" else { return }

        guard let sound = NSSound(named: NSSound.Name(name)) else {
            print("找不到系统声音: \(name)")
            return
        }

        sound.loops = loop
        currentSound = sound
        sound.play()
        #endif
    }

    func stopSound() {
        #if os(macOS)
        currentSound?.stop()
        currentSound = nil
        #endif
    }
}
