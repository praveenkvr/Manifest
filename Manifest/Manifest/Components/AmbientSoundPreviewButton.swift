//
//  AmbientSoundPreviewButton.swift
//  Manifest
//
//  Used in both the Settings and Goal Detail sound pickers — `previewing` is
//  owned by the caller (one shared "what's currently playing" per sheet) so
//  starting a new preview naturally stops whichever one was playing before.
//

import SwiftUI

struct AmbientSoundPreviewButton: View {
    var option: AmbientSoundOption
    @Binding var previewing: AmbientSoundOption?

    var body: some View {
        let isPlaying = previewing == option
        Button {
            if isPlaying {
                AmbientAudioPlayer.shared.stop()
                previewing = nil
            } else {
                previewing = AmbientAudioPlayer.shared.start(option) ? option : nil
            }
        } label: {
            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.accent500)
        }
        .buttonStyle(.plain)
    }
}
