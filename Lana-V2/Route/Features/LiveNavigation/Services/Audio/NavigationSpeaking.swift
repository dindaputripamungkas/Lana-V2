//
//  NavigationSpeaking.swift
//  Lana-V2
//

@MainActor
protocol NavigationSpeaking {
    func speak(_ text: String)
    func stop()
}
