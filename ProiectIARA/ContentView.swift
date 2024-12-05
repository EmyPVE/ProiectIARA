//  ContentView.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 21.10.2024.

import SwiftUI
import RealityKit
import ARKit
import simd
import Combine
import UIKit

class GameSettings: ObservableObject {
    @Published var isGameStarted: Bool = false
    @Published var towerAnchor: AnchorEntity? = nil
    @Published var hasPlacedCubes: Bool = false
    @Published var showWaitingMessage: Bool = true
    @Published var showTowerAlreadyPlacedMessage: Bool = false
    @Published var score: Int = 0
    @Published var ballsRemaining: Int = 3
    @Published var isGameOver: Bool = false
    @Published var gameResult: String? = nil
    @Published var showInstructionCard: Bool = false

    func resetGame() {
        // Reset variables and go back to MainMenuView
        self.isGameStarted = false
        self.towerAnchor?.removeFromParent()
        self.towerAnchor = nil
        self.hasPlacedCubes = false
        self.showWaitingMessage = true
        self.showTowerAlreadyPlacedMessage = false
        self.score = 0
        self.ballsRemaining = 3
        self.isGameOver = false
        self.gameResult = nil
    }

    func startNewGame() {
        // Reset variables but stay in ContentView
        self.towerAnchor?.removeFromParent()
        self.towerAnchor = nil
        self.hasPlacedCubes = false
        self.showWaitingMessage = true
        self.showTowerAlreadyPlacedMessage = false
        self.score = 0
        self.ballsRemaining = 3
        self.isGameOver = false
        self.gameResult = nil
        // isGameStarted remains true
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
    @State private var showInstructionsCard: Bool = true

    var body: some View {
        if gameSettings.isGameStarted {
            ZStack {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)

                // Layer pentru instrucțiuni
                if showInstructionsCard {
                    Color.black.opacity(0.5) // Fundal semitransparent pentru focus pe card
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Ascunde cardul la primul tap
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showInstructionsCard = false
                            }
                        }

                    VStack {
                        Spacer()

                        // RoundedRectangle cu textul centralizat
                        VStack(spacing: 20) {
                            HStack{
                                Image(systemName: "hand.tap")
                                    .symbolEffect(.bounce.down.byLayer, options: .repeat(.periodic(delay: 0.5)))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("to place the tower.")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            HStack{
                                Image(systemName: "hand.draw")
                                    .symbolEffect(.pulse)
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(" to throw the ball.")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(30)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(radius: 10)

                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity)
                }

                // UI-ul principal
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

                    Spacer()

                    // Scorul și mingile rămase rămân în partea de jos
                    if !showInstructionsCard && !gameSettings.isGameOver {
                        VStack {
                            Text("Score: \(gameSettings.score)")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)

                            Text("Balls Remaining: \(gameSettings.ballsRemaining)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 20)
                    }
                }

                // Mesajul de final al jocului
                if gameSettings.isGameOver {
                    VStack(spacing: 30) {
                        if let result = gameSettings.gameResult {
                            Text(result)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(result == "You won!" ? .green : .red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                gameSettings.startNewGame()
                            }
                        }) {
                            HStack {
                                Text("Restart Game")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                    .symbolEffect(.rotate.clockwise.byLayer, options: .repeat(.periodic(delay: 0.5)))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                Capsule()
                                    .fill(.green)
                                    .shadow(radius: 10)
                            )

                        }
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .transition(.scale)
                }
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
        var cubes: [ModelEntity] = [] {
            didSet {
                if cubes.count > 10 {
                    let removedCubes = cubes.prefix(cubes.count - 10)
                    removedCubes.forEach { $0.removeFromParent() }
                    cubes = Array(cubes.suffix(10))
                }
            }
        }
        var subscriptions = Set<AnyCancellable>()
        var initialBallPosition: SIMD3<Float>?

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

            // Add visible ground plane under the cubes
            let groundPlaneWidth: Float = 0.4 // Reduced width to make platform smaller
            let groundPlaneDepth: Float = 0.4 // Reduced depth to make platform smaller
            let groundPlaneHeight: Float = 0.02 // 2 cm thick

            let groundPlaneMesh = MeshResource.generateBox(size: [groundPlaneWidth, groundPlaneHeight, groundPlaneDepth])
            let groundPlaneMaterial = SimpleMaterial(color: .lightGray, isMetallic: false)
            let groundPlane = ModelEntity(mesh: groundPlaneMesh, materials: [groundPlaneMaterial])

            groundPlane.physicsBody = PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .static
            )

            // Collision component
            groundPlane.collision = CollisionComponent(
                shapes: [.generateBox(size: [groundPlaneWidth, groundPlaneHeight, groundPlaneDepth])]
            )

            // Position the plane so that its top is at y = 0
            groundPlane.position = [0, groundPlaneHeight / 2, 0]

            // Add the plane as a child of the tower anchor
            towerAnchor.addChild(groundPlane)

            // Subscribe to scene updates
            arView.scene.subscribe(to: SceneEvents.Update.self) { event in
                self.update(event: event)
            }.store(in: &self.subscriptions)

            // Create the ball and place it in front of the camera
            createAndPlaceBall(in: arView)

            isSceneSetUp = true
        }

        func update(event: SceneEvents.Update) {
            var cubesToRemove: [ModelEntity] = []
            for cube in cubes {
                if cube.position(relativeTo: nil).y < -0.5 { // Updated threshold to -0.5 to remove cubes much lower
                    cubesToRemove.append(cube)
                }
            }
            for cube in cubesToRemove {
                if let index = self.cubes.firstIndex(of: cube) {
                    self.cubes.remove(at: index)
                    cube.removeFromParent()
                    DispatchQueue.main.async {
                        self.gameSettings.score += 1

                        // Verifică dacă scorul a ajuns la 6 și setează jocul ca fiind câștigat
                        if self.gameSettings.score == 6 {
                            self.gameSettings.isGameOver = true
                            self.gameSettings.gameResult = "You won!"
                        }
                    }
                }
            }
        }


        func placeCubes(on anchor: AnchorEntity) {
            let cubeSize: Float = 0.1
            let groundPlaneHeight: Float = 0.02
            let firstLayerY = groundPlaneHeight + cubeSize / 2 // 0.02 + 0.05 = 0.07
            let secondLayerY = firstLayerY + cubeSize // 0.07 + 0.1 = 0.17
            let thirdLayerY = secondLayerY + cubeSize // 0.17 + 0.1 = 0.27

            for i in 0..<3 {
                let cube = createCube(size: cubeSize)
                cube.position = [Float(i) * 0.15 - 0.15, firstLayerY, 0] // Positioned cubes on top of the ground plane
                anchor.addChild(cube)
            }
            for i in 0..<2 {
                let cube = createCube(size: cubeSize)
                cube.position = [Float(i) * 0.15 - 0.075, secondLayerY, 0] // Positioned cubes on top of the ground plane
                anchor.addChild(cube)
            }
            let topCube = createCube(size: cubeSize)
            topCube.position = [0, thirdLayerY, 0] // Positioned top cube on top of the ground plane
            anchor.addChild(topCube)
        }

        func createCube(size: Float) -> ModelEntity {
            let cube = ModelEntity(
                mesh: .generateBox(size: size),
                materials: [SimpleMaterial(color: .systemMint, roughness: 1, isMetallic: true)]
            )
            cube.physicsBody = PhysicsBodyComponent(
                massProperties: .init(mass: 1.0), // Increased mass to make cubes heavier
                material: .default,
                mode: .dynamic
            )
            cube.collision = CollisionComponent(
                shapes: [.generateBox(size: [size, size, size])]
            )
            self.cubes.append(cube)
            return cube
        }

        func createBall(radius: Float) -> ModelEntity {
            let ball = ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [SimpleMaterial(color: .orange, roughness: 0.3, isMetallic: true)]
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
            guard self.gameSettings.ballsRemaining > 0 else { return }
            if let existingBall = arView.scene.findEntity(named: "ball") {
                existingBall.removeFromParent()
            }
            let ball = createBall(radius: 0.05)
            ball.name = "ball"
            var ballPosition: SIMD3<Float>
            if let initialPosition = self.initialBallPosition {
                ballPosition = initialPosition
            } else if let cameraTransform = arView.session.currentFrame?.camera.transform {
                let forward = normalize(-cameraTransform.columns.2.xyz)
                let cameraPosition = cameraTransform.position
                ballPosition = cameraPosition + forward * 0.1
                ballPosition.y += 0.005 // Place the ball slightly higher by 0.5 cm
                self.initialBallPosition = ballPosition
            } else {
                ballPosition = [0, 0, 0] // default position
            }
            ball.position = ballPosition

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
                var position = result.worldTransform.position
                let cameraPosition = arView.cameraTransform.translation
                let distance = simd_distance(cameraPosition, position)
                if distance < 0.5 {
                    // Move the anchor further away
                    let direction = normalize(position - cameraPosition)
                    position = cameraPosition + direction * 0.5
                }
                let anchor = AnchorEntity(world: position)
                gameSettings.towerAnchor = anchor
                arView.scene.addAnchor(anchor)
                setupScene(in: arView)

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }

        @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            guard let ball = arView.scene.findEntity(named: "ball") as? ModelEntity else { return }

            if gesture.state == .ended {
                // Get the camera's forward direction
                if let cameraTransform = arView.session.currentFrame?.camera.transform {
                    let forward = normalize(-cameraTransform.columns.2.xyz)
                    let forceMagnitude: Float = 2.5 // Adjusted force to slow down the ball
                    let force = forward * forceMagnitude

                    ball.physicsBody?.mode = .dynamic
                    ball.physicsBody?.massProperties.mass = 0.5
                    ball.applyLinearImpulse(force, relativeTo: nil)

                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                    // Decrease ballsRemaining
                    DispatchQueue.main.async {
                        self.gameSettings.ballsRemaining -= 1
                        if self.gameSettings.ballsRemaining > 0 {
                            // Create new ball after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.createAndPlaceBall(in: arView)
                            }
                        } else {
                            // Delay the game over result to allow for final cube falls
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self.gameSettings.isGameOver = true
                                self.gameSettings.gameResult = self.gameSettings.score == 6
 ? "You won!" : "You lost!"
                            }
                        }
                    }
                }
            }
        }
    }
}
