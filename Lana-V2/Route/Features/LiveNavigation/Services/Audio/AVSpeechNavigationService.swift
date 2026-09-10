//
//  AVSpeechNavigationService.swift
//  Lana-V2
//

import AVFoundation
import Foundation

@MainActor
final class AVSpeechNavigationService: NavigationSpeaking {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenText = ""
    private var lastSpokenAt = Date.distantPast

    func speak(_ text: String) {
        let normalized = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalized.isEmpty else { return }
        guard normalized != lastSpokenText
                || Date().timeIntervalSince(lastSpokenAt) > 2 else {
            return
        }

        configureAudioSession()
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: normalized)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1
        utterance.voice = AVSpeechSynthesisVoice(
            language: Locale.current.language.languageCode?.identifier
        ) ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)

        lastSpokenText = normalized
        lastSpokenAt = Date()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            // Navigation remains usable when another audio session owns output.
        }
    }
}
