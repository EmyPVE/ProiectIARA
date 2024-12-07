//
//  AppDelegate.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 21.10.2024.
//

import SwiftUI

@main
struct ProiectIARAApp: App {
    @StateObject var gameSettings = GameSettings()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(gameSettings)
        }
    }
}
