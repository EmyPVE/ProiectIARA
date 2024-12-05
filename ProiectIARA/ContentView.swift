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

    func resetGame() {
        self.isGameStarted = false
        self.towerAnchor = nil
        self.hasPlacedCubes = false
        self.showWaitingMessage = true
        self.showTowerAlreadyPlacedMessage = false
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension simd_float4 {
    var xyz: SIMD3<Float> {
        SIMD3(x, y, z)
    }
}

struct ContentView: View {
    @EnvironmentObject var gameSettings: GameSettings

    var body: some View {
        if gameSettings.isGameStarted {
            ZStack {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    }

                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                gameSettings.resetGame()
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

                    if gameSettings.showWaitingMessage {
                        Text("Waiting for player to place the tower.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.top, 10)
                            .transition(.opacity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {}
                            }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .environmentObject(gameSettings)
        } else {
            MainMenuView()
                .environmentObject(gameSettings)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var gameSettings: GameSettings

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // Add gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)

        let swipeGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSwipe))
        swipeGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(swipeGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // No updates needed for now
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(gameSettings: gameSettings)
    }

    class Coordinator: NSObject {
        @ObservedObject var gameSettings: GameSettings
        var isSceneSetUp: Bool = false
        var arView: ARView?

        init(gameSettings: GameSettings) {
            self.gameSettings = gameSettings
        }

        func setupScene(in arView: ARView) {
            self.arView = arView

            guard let towerAnchor = gameSettings.towerAnchor else { return }

            // Place cubes on the anchor
            placeCubes(on: towerAnchor)
            arView.scene.addAnchor(towerAnchor)
            DispatchQueue.main.async {
                self.gameSettings.hasPlacedCubes = true
                self.gameSettings.showWaitingMessage = false
            }

            // Add invisible ground plane under the cubes
            let groundPlaneWidth: Float = 1.0
            let groundPlaneDepth: Float = 1.5

            let groundPlane = ModelEntity(mesh: .generatePlane(width: groundPlaneWidth, depth: groundPlaneDepth))

            // Set the plane's material to be transparent
            let transparentMaterial = SimpleMaterial(color: .clear, isMetallic: false)
            groundPlane.model?.materials = [transparentMaterial]

            groundPlane.physicsBody = PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .static
            )

            // Collision component
            groundPlane.collision = CollisionComponent(
                shapes: [.generateBox(size: [groundPlaneWidth, 0.001, groundPlaneDepth])]
            )

            // Position the plane so that it extends slightly behind the tower
            groundPlane.position = [0, 0, groundPlaneDepth / 2 - 0.05] // Adjust the position as needed

            // Add the plane as a child of the tower anchor
            towerAnchor.addChild(groundPlane)

            // Create the ball and place it in front of the camera
            createAndPlaceBall(in: arView)

            isSceneSetUp = true
        }

        func placeCubes(on anchor: AnchorEntity) {
            for i in 0..<3 {
                let cube = createCube(size: 0.1)
                cube.position = [Float(i) * 0.15 - 0.15, 0.05, 0]
                anchor.addChild(cube)
            }
            for i in 0..<2 {
                let cube = createCube(size: 0.1)
                cube.position = [Float(i) * 0.15 - 0.075, 0.15, 0]
                anchor.addChild(cube)
            }
            let topCube = createCube(size: 0.1)
            topCube.position = [0, 0.25, 0]
            anchor.addChild(topCube)
        }

        func createCube(size: Float) -> ModelEntity {
            let cube = ModelEntity(
                mesh: .generateBox(size: size),
                materials: [SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)]
            )
            cube.physicsBody = PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .dynamic
            )
            cube.collision = CollisionComponent(
                shapes: [.generateBox(size: [size, size, size])]
            )
            return cube
        }

        func createBall(radius: Float) -> ModelEntity {
            let ball = ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [SimpleMaterial(color: .red, roughness: 0.3, isMetallic: true)]
            )
            ball.physicsBody = PhysicsBodyComponent(
                massProperties: .init(mass: 0.1),
                material: .default,
                mode: .kinematic // Initially kinematic to stay in place
            )
            ball.collision = CollisionComponent(
                shapes: [.generateSphere(radius: radius)]
            )
            return ball
        }

        func createAndPlaceBall(in arView: ARView) {
            let ball = createBall(radius: 0.05)
            ball.name = "ball"
            if let cameraTransform = arView.session.currentFrame?.camera.transform {
                let forward = normalize(-cameraTransform.columns.2.xyz)
                let cameraPosition = cameraTransform.position
                var ballPosition = cameraPosition + forward * 0.1
                ballPosition.y -= 0.05 // Place the ball slightly lower
                ball.position = ballPosition
            }

            let ballAnchor = AnchorEntity(world: ball.position)
            ballAnchor.addChild(ball)
            arView.scene.addAnchor(ballAnchor)
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
                // Get the camera's forward direction
                if let cameraTransform = arView.session.currentFrame?.camera.transform {
                    let forward = normalize(-cameraTransform.columns.2.xyz)
                    let forceMagnitude: Float = 3 // Adjusted force to slow down the ball
                    let force = forward * forceMagnitude

                    ball.physicsBody?.mode = .dynamic
                    ball.physicsBody?.massProperties.mass = 0.5
                    ball.applyLinearImpulse(force, relativeTo: nil)
                }
            }
        }
    }
}
