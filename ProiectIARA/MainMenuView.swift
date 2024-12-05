//
//  MainMenuView.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 21.10.2024.
//

import SwiftUI
import RealityKit
import ARKit

struct MainMenuView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @State private var isARReady: Bool = false
    @State private var isLoading: Bool = false

    private let backgroundColor = Color.black.opacity(0.7)
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let blurRadius = UIScreen.main.bounds.width / 80 // Reduced blur for performance

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
                    // Blurred AR camera background
                    BackgroundARViewContainer()
                        .blur(radius: blurRadius)
                        .edgesIgnoringSafeArea(.all)
                }

                GeometryReader { geometry in
                    VStack {
                        Text("Tower Tumble 🎯")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding(.bottom, 50)
                        Button(action: {
                            feedbackGenerator.impactOccurred()

                            // Start preloading AR
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // Preload AR resources if necessary
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
                // The AR game view
                ContentView()
                    .environmentObject(gameSettings)
            }
        }
    }
}

struct BackgroundARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session for background
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.environmentTexturing = .automatic
        arView.session.run(config)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // No updates needed for now
    }
}
