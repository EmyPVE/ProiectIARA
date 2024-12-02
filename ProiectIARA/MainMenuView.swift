//
//  MainMenuView.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 02.12.2024.
//
import SwiftUI

struct MainMenuView: View {
    @State private var selectedMode: GameMode?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Alege modul de joc")
                    .font(.largeTitle)
                    .padding()

                // Button for tabletop mode
                NavigationLink(value: GameMode.tabletop) {
                    Text("Joacă pe masă")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Button for room-scale mode
                NavigationLink(value: GameMode.roomScale) {
                    Text("Joacă în cameră")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationDestination(for: GameMode.self) { mode in
                ContentView(isTabletopMode: mode == .tabletop)
            }
        }
    }
}

// Enum to represent game modes
enum GameMode: Hashable {
    case tabletop
    case roomScale
}

