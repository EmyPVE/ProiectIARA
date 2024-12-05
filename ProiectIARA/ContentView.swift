//
//  ContentView.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 21.10.2024.
//

import SwiftUI
import RealityKit
import ARKit
import simd
import Combine

class GameSettings: ObservableObject {
    @Published var isGameStarted: Bool = false
    @Published var towerAnchor: AnchorEntity? = nil
    @Published var hasPlacedCubes: Bool = false
    @Published var showWaitingMessage: Bool = true
    @Published var showTowerAlreadyPlacedMessage: Bool = false
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3(self.columns.3.x, self.columns.3.y, self.columns.3.z)
    }
}

struct ContentView: View {
    @ObservedObject var gameSettings: GameSettings

    var body: some View {
        ZStack {
            if gameSettings.isGameStarted {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)
                    .environmentObject(gameSettings)
                    .onAppear {
                        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    }

                VStack {
                    // Butonul Back și Mesajul "Tower Already Placed" în aceeași linie
                    HStack {
                        Button(action: {
                            // Tranziție lină la revenirea la meniul principal
                            withAnimation(.easeInOut(duration: 1.0)) {
                                gameSettings.isGameStarted = false
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        .padding(.leading, 20)

                        Spacer()

                        if gameSettings.showTowerAlreadyPlacedMessage {
                            Text("Tower already placed.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(10)
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                        }
                    }

                    // Mesajul pentru Waiting în partea de sus, sub butonul Back
                    if gameSettings.showWaitingMessage {
                        Text("Waiting for player to place the tower.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.top, 10) // Lasă puțin spațiu sub buton și mesajul Tower Already Placed
                            .transition(.opacity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    // No action required here, the animation runs indefinitely
                                }
                            }
                    }

                    Spacer() // Lasă restul spațiului disponibil pentru a aduce mesajele și butonul sus
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var gameSettings: GameSettings

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        let swipeGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSwipe))
        swipeGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(swipeGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if gameSettings.isGameStarted && !context.coordinator.isSceneSetUp {
            context.coordinator.isSceneSetUp = true
            context.coordinator.setupScene(in: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(gameSettings: gameSettings)
    }

    class Coordinator: NSObject {
        @ObservedObject var gameSettings: GameSettings
        var isSceneSetUp: Bool = false
        var cancellableSet: Set<AnyCancellable> = []

        init(gameSettings: GameSettings) {
            self.gameSettings = gameSettings
        }
        
        func setupScene(in arView: ARView) {
            guard let towerAnchor = gameSettings.towerAnchor else { return }
            
            do {
                let skyboxResource = try EnvironmentResource.load(named: "light.skybox")
                arView.environment.lighting.resource = skyboxResource
            } catch {
                print("Eroare: Nu s-a putut încărca skybox-ul din light.skybox")
            }
            
            let cubeAnchor = towerAnchor
            placeCubes(on: cubeAnchor)
            arView.scene.addAnchor(cubeAnchor)
            DispatchQueue.main.async {
                self.gameSettings.hasPlacedCubes = true
                self.gameSettings.showWaitingMessage = false
            }
            
            let ball = createBall(radius: 0.05)
            ball.physicsBody = PhysicsBodyComponent(massProperties: .init(mass: 0.5), material: .default, mode: .dynamic)
            ball.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.05)])
            ball.position = [0, 0.05, -0.2]
            let ballAnchor = AnchorEntity(world: [0, 0.05, -0.2])
            ballAnchor.addChild(ball)
            arView.scene.addAnchor(ballAnchor)
        }

        func placeCubes(on anchor: AnchorEntity) {
            for i in 0..<3 {
                let cube = createCube(size: 0.1)
                cube.position = [Float(i) * 0.15 - 0.15, 0, -0.1]
                anchor.addChild(cube)
            }
            for i in 0..<2 {
                let cube = createCube(size: 0.1)
                cube.position = [Float(i) * 0.15 - 0.075, 0.1, -0.1]
                anchor.addChild(cube)
            }
            let topCube = createCube(size: 0.1)
            topCube.position = [0, 0.2, -0.1]
            anchor.addChild(topCube)
        }

        func createCube(size: Float) -> ModelEntity {
            let cube = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            cube.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
            cube.collision = CollisionComponent(shapes: [.generateBox(size: [size, size, size])])
            return cube
        }

        func createBall(radius: Float) -> ModelEntity {
            let ball = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: .red, isMetallic: true)])
            ball.physicsBody = PhysicsBodyComponent(massProperties: .init(mass: 0.5), material: .default, mode: .dynamic)
            ball.collision = CollisionComponent(shapes: [.generateSphere(radius: radius)])
            ball.name = "ball"
            return ball
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            if gameSettings.hasPlacedCubes || !gameSettings.isGameStarted {
                gameSettings.showTowerAlreadyPlacedMessage = true
                return
            }
            let tapLocation = gesture.location(in: arView)
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            if let result = results.first {
                let anchor = AnchorEntity(world: result.worldTransform.position)
                gameSettings.towerAnchor = anchor
                arView.scene.addAnchor(anchor)
                setupScene(in: arView)
            }
        }

        @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            guard let ball = arView.scene.findEntity(named: "ball") as? ModelEntity else { return }
            
            if gesture.state == .ended {
                let velocity = gesture.velocity(in: arView)
                let swipeDirection = SIMD3<Float>(
                    Float(-velocity.x) * 0.0001,
                    0,
                    Float(-velocity.y) * 0.0001
                )
                ball.physicsBody?.mode = .dynamic
                ball.applyLinearImpulse(swipeDirection, relativeTo: nil)
            }
        }
    }
}
