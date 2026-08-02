//
//  AmbientAudioPlayer.swift
//  Manifest
//
//  Loops one of the four bundled tracks (Sounds/*.m4a) — see
//  AmbientSoundOption.swift for sourcing/licensing. Also used for the
//  Settings/Goal Detail "preview" buttons, not just the ritual itself —
//  `currentOption` lets the UI show which row (if any) is currently playing.
//

import AVFoundation

final class AmbientAudioPlayer {
    static let shared = AmbientAudioPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private(set) var currentOption: AmbientSoundOption?

    private init() {
        engine.attach(player)
    }

    /// Returns whether playback actually started — callers (the preview
    /// buttons) shouldn't show a "playing" state if this comes back false.
    @discardableResult
    func start(_ option: AmbientSoundOption) -> Bool {
        stop()
        let resolved = option.resolved
        guard let url = Bundle.main.url(forResource: resolved.fileName, withExtension: "m4a"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil else {
            print("[AmbientAudioPlayer] couldn't load \(resolved.fileName)")
            return false
        }

        engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)

        do {
            // .ambient respects the physical silent switch — silently mutes
            // with no error if the phone is on silent, which reads as
            // "nothing happens" with no indication why. .playback is the
            // correct category for audio the user explicitly chose to hear.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("[AmbientAudioPlayer] failed to start engine: \(error)")
            return false
        }

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = 0.5 // the tracks are mastered at full volume — too loud as a background layer at 1.0
        player.play()
        currentOption = option
        return true
    }

    func stop() {
        guard currentOption != nil else { return }
        player.stop()
        engine.stop()
        currentOption = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
