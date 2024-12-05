//
//  MainMenuView.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 21.10.2024.
//

import SwiftUI
import RealityKit
import UIKit

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

struct MainMenuView: View {
    @ObservedObject var gameSettings: GameSettings
    @State private var isARReady: Bool = false
    @State private var isLoading: Bool = false

    private let backgroundColor = Color.black.opacity(0.7)
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let blurRadius = UIScreen.main.bounds.width / 80 // Blur mai redus pentru performanță

    var body: some View {
        ZStack {
            if !gameSettings.isGameStarted {
                if isLoading {
                    VStack {
                        Text("Loading AR...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                } else {
                    ARViewContainer()
                        .blur(radius: blurRadius)
                        .edgesIgnoringSafeArea(.all)
                        .environmentObject(gameSettings)
                }

                GeometryReader { geometry in
                    VStack {
                        Text("Tower Tumble 🎯")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding(.bottom, 50)
                        Button(action: {
                            feedbackGenerator.impactOccurred()

                            // Începe preîncărcarea AR
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                prepareARView()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 1.0)) {
                                        isARReady = true
                                        isLoading = false
                                        gameSettings.isGameStarted = true
                                    }
                                }
                            }
                        }) {
                            Text("Play")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(backgroundColor)
                }
            } else if isARReady {
                ContentView(gameSettings: gameSettings)
            }
        }
    }

    // Funcție pentru a pregăti ARView în mod sigur pe firul principal
    func prepareARView() {
        // Inițializează ARView pe firul principal pentru a-l preîncărca fără blocări semnificative
        let _ = ARView(frame: .zero)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(gameSettings: GameSettings())
    }
}
