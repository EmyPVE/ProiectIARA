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
import UIKit
import AVFoundation // Importă AVFoundation pentru gestionarea sunetelor

// MARK: - GameSettings

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

    // Reset the game state
    func resetGame() {
        self.isGameStarted = false
    }

    // Start a new game
    func startNewGame() {
        self.resetGame()
        self.isGameStarted = true
    }
}

// MARK: - SIMD Extensions

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

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @State private var showInstructionsCard: Bool = true

    var body: some View {
        if gameSettings.isGameStarted {
            ZStack {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)

                // Instructions Overlay
                if showInstructionsCard {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showInstructionsCard = false
                            }
                        }

                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            HStack {
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
                            HStack {
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

                // UI Overlays
                VStack {
                    HStack {
                        // Reset Button
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

                        // Tower Already Placed Message
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

                    // Score and Balls Remaining
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

                // Game Over Overlay
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
                                    .fill(Color.green)
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
            // Main Menu View
            MainMenuView()
                .environmentObject(gameSettings)
        }
    }

    // MARK: - ARViewContainer

    struct ARViewContainer: UIViewRepresentable {
        @EnvironmentObject var gameSettings: GameSettings

        func makeUIView(context: Context) -> ARView {
            let arView = ARView(frame: .zero)

            // Configure AR Session
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            arView.session.run(config)

            // Add Gesture Recognizers
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap))
            arView.addGestureRecognizer(tapGesture)

            let swipeGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSwipe))
            swipeGesture.maximumNumberOfTouches = 1
            arView.addGestureRecognizer(swipeGesture)

            context.coordinator.arView = arView

            return arView
        }

        func updateUIView(_ uiView: ARView, context: Context) {
            // Setup or cleanup the scene based on game state
            if gameSettings.isGameStarted && !context.coordinator.isSceneSetUp {
                context.coordinator.setupScene(in: uiView)
            } else if !gameSettings.isGameStarted && context.coordinator.isSceneSetUp {
                context.coordinator.cleanupScene()
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(gameSettings: gameSettings)
        }

        // MARK: - Coordinator

        class Coordinator: NSObject {
            @ObservedObject var gameSettings: GameSettings
            var isSceneSetUp: Bool = false
            weak var arView: ARView?
            var cubes: [ModelEntity] = []
            var subscriptions = Set<AnyCancellable>()
            var initialBallPosition: SIMD3<Float>?

            // Ball Template
            let ballTemplate: ModelEntity

            // MARK: - Audio Players
            var backgroundMusicPlayer: AVAudioPlayer?
            var throwSoundPlayer: AVAudioPlayer?
            var ballHitSoundPlayer: AVAudioPlayer?
            var cubeHitSoundPlayer: AVAudioPlayer?

            init(gameSettings: GameSettings) {
                self.gameSettings = gameSettings

                // Load ball model once
                self.ballTemplate = try! Entity.loadModel(named: "tennisball")
                let ballDiameter: Float = 0.09
                ballTemplate.scale = [ballDiameter, ballDiameter, ballDiameter]

                ballTemplate.physicsBody = PhysicsBodyComponent(
                    massProperties: .init(mass: 0.0015),
                    material: .default,
                    mode: .kinematic
                )
                ballTemplate.collision = CollisionComponent(
                    shapes: [.generateSphere(radius: ballDiameter)]
                )
                ballTemplate.name = "ballTemplate" // Unique name for template

                super.init()

                // Setup Audio Players
                setupAudioPlayers()

                // Setup Combine Subscriptions
                setupSubscriptions()
            }

            deinit {
                subscriptions.forEach { $0.cancel() }
            }

            // MARK: - Setup Audio Players

            private func setupAudioPlayers() {
                // Setup Background Music
                if let bgMusicURL = Bundle.main.url(forResource: "elevador-de-sonhos", withExtension: "mp3") {
                    do {
                        backgroundMusicPlayer = try AVAudioPlayer(contentsOf: bgMusicURL)
                        backgroundMusicPlayer?.numberOfLoops = -1 // Infinite loop
                        backgroundMusicPlayer?.volume = 0.5
                        backgroundMusicPlayer?.prepareToPlay()
                        backgroundMusicPlayer?.play()
                        print("Background music started.")
                    } catch {
                        print("Error loading background music: \(error)")
                    }
                } else {
                    print("Background music file 'elevador-de-sonhos.mp3' not found.")
                }

                // Setup Throw Sound
                if let throwSoundURL = Bundle.main.url(forResource: "throwSound", withExtension: "mp3") {
                    do {
                        throwSoundPlayer = try AVAudioPlayer(contentsOf: throwSoundURL)
                        throwSoundPlayer?.volume = 1.0
                        throwSoundPlayer?.prepareToPlay()
                        print("Throw sound loaded.")
                    } catch {
                        print("Error loading throw sound: \(error)")
                    }
                } else {
                    print("Throw sound file 'throwSound.mp3' not found.")
                }

                // Setup Ball Hit Sound
                if let ballHitSoundURL = Bundle.main.url(forResource: "ballHitSound", withExtension: "mp3") {
                    do {
                        ballHitSoundPlayer = try AVAudioPlayer(contentsOf: ballHitSoundURL)
                        ballHitSoundPlayer?.volume = 1.0
                        ballHitSoundPlayer?.prepareToPlay()
                        print("Ball hit sound loaded.")
                    } catch {
                        print("Error loading ball hit sound: \(error)")
                    }
                } else {
                    print("Ball hit sound file 'ballHitSound.mp3' not found.")
                }

                // Setup Cube Hit Sound
                if let cubeHitSoundURL = Bundle.main.url(forResource: "cubeHitSound", withExtension: "mp3") {
                    do {
                        cubeHitSoundPlayer = try AVAudioPlayer(contentsOf: cubeHitSoundURL)
                        cubeHitSoundPlayer?.volume = 1.0
                        cubeHitSoundPlayer?.prepareToPlay()
                        print("Cube hit sound loaded.")
                    } catch {
                        print("Error loading cube hit sound: \(error)")
                    }
                } else {
                    print("Cube hit sound file 'cubeHitSound.mp3' not found.")
                }
            }

            // MARK: - Setup Combine Subscriptions

            private func setupSubscriptions() {
                // Listen for game reset
                gameSettings.$isGameStarted
                    .sink { [weak self] isStarted in
                        if !isStarted {
                            self?.cleanupScene()
                        }
                    }
                    .store(in: &subscriptions)
            }

            // MARK: - Scene Setup

            func setupScene(in arView: ARView) {
                guard let towerAnchor = gameSettings.towerAnchor else { return }

                placeCubes(on: towerAnchor)
                arView.scene.addAnchor(towerAnchor)
                DispatchQueue.main.async {
                    self.gameSettings.hasPlacedCubes = true
                    self.gameSettings.showWaitingMessage = false
                }

                // Ground Plane Setup
                let groundPlaneWidth: Float = 0.4
                let groundPlaneDepth: Float = 0.4
                let groundPlaneHeight: Float = 0.02
                let collisionHeight: Float = 0.005 // 5 mm

                let groundPlaneMesh = MeshResource.generateBox(size: [groundPlaneWidth, groundPlaneHeight, groundPlaneDepth])
                let groundPlaneMaterial = SimpleMaterial(color: .gray, isMetallic: false)
                let groundPlane = ModelEntity(mesh: groundPlaneMesh, materials: [groundPlaneMaterial])

                groundPlane.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)

                // Collision Shape Adjustment
                groundPlane.collision = CollisionComponent(
                    shapes: [.generateBox(size: [groundPlaneWidth, collisionHeight, groundPlaneDepth])]
                )

                // Position Ground Plane
                groundPlane.position = [0, 0, 0]
                towerAnchor.addChild(groundPlane)

                // Subscribe to Scene Updates
                arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                    self?.update(event: event)
                }.store(in: &subscriptions)

                // Subscribe to Collision Events
                arView.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
                    self?.handleCollision(event: event)
                }.store(in: &subscriptions)

                // Place Ball After Delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.createAndPlaceBall(in: arView)
                }

                // Make Cubes Dynamic After Delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    for cube in self.cubes {
                        cube.physicsBody?.mode = .dynamic
                    }
                }

                isSceneSetUp = true
            }

            // MARK: - Scene Cleanup

            func cleanupScene() {
                guard let arView = arView else { return }

                // Remove Tower Anchor and Its Children
                if let towerAnchor = gameSettings.towerAnchor {
                    arView.scene.removeAnchor(towerAnchor)
                    gameSettings.towerAnchor = nil
                }

                // Remove All Cubes
                for cube in cubes {
                    cube.removeFromParent()
                }
                cubes.removeAll()

                // Remove All Ball Entities
                if let ballAnchor = arView.scene.findEntity(named: "ball")?.anchor {
                    arView.scene.removeAnchor(ballAnchor)
                }

                // Reset Initial Ball Position
                resetBallPosition()

                // Reset Game Settings
                DispatchQueue.main.async {
                    self.gameSettings.score = 0
                    self.gameSettings.ballsRemaining = 3
                    self.gameSettings.isGameOver = false
                    self.gameSettings.gameResult = nil
                    self.gameSettings.hasPlacedCubes = false
                    self.gameSettings.showWaitingMessage = true
                    self.gameSettings.showTowerAlreadyPlacedMessage = false
                }

                isSceneSetUp = false
            }

            // MARK: - Ball Position Reset

            func resetBallPosition() {
                self.initialBallPosition = nil
            }

            // MARK: - Update Loop

            func update(event: SceneEvents.Update) {
                guard arView != nil else { return }
                var cubesToRemove: [ModelEntity] = []

                for cube in cubes {
                    if cube.position(relativeTo: nil).y < -1.5 {
                        cubesToRemove.append(cube)
                    }
                }

                for cube in cubesToRemove {
                    if let index = self.cubes.firstIndex(of: cube) {
                        self.cubes.remove(at: index)
                        cube.removeFromParent()
                        DispatchQueue.main.async {
                            self.gameSettings.score += 1
                            if self.gameSettings.score == 6 {
                                self.gameSettings.isGameOver = true
                                self.gameSettings.gameResult = "You won!"
                            }
                        }
                    }
                }
            }

            // MARK: - Cube Placement

            func placeCubes(on anchor: AnchorEntity) {
                let groundPlaneHeight: Float = 0.0 // Ground plane is at Y=0
                let spacing: Float = 0.1 // 10 cm vertical spacing between layers

                // Calculate Y positions accounting for half of the cube being below ground
                let firstLayerY = groundPlaneHeight + 0.05 // Base layer
                let secondLayerY = firstLayerY + cubeHeight + spacing
                let thirdLayerY = secondLayerY + cubeHeight + spacing

                // Horizontal positions for each layer (meters)
                let positionsBottom: [Float] = [-0.1, 0.0, 0.1] // 10 cm left, center, 10 cm right
                let positionsMid: [Float] = [-0.05, 0.05] // 5 cm left and 5 cm right
                let positionTop: Float = 0.0 // Center

                // Create and Place Cubes
                // 3 cubes at the base
                for i in 0..<positionsBottom.count {
                    let cube = createCube()
                    cube.position = [positionsBottom[i], firstLayerY, 0]
                    anchor.addChild(cube)
                    cubes.append(cube)
                }

                // 2 cubes in the middle
                for i in 0..<positionsMid.count {
                    let cube = createCube()
                    cube.position = [positionsMid[i], secondLayerY, 0]
                    anchor.addChild(cube)
                    cubes.append(cube)
                }

                // 1 cube at the top
                let topCube = createCube()
                topCube.position = [positionTop, thirdLayerY, 0]
                anchor.addChild(topCube)
                cubes.append(topCube)
            }

            // Helper Method to Create a Cube
            func createCube() -> ModelEntity {
                let cube = try! Entity.loadModel(named: "cube.usdz")
                let originalBounds = cube.visualBounds(relativeTo: nil)
                let scaleY = cubeHeight / originalBounds.extents.y
                let scaleX = cubeDiameter / originalBounds.extents.x
                let scaleZ = cubeDiameter / originalBounds.extents.z
                let scaleFactor = min(scaleX, scaleY, scaleZ)
                cube.scale = [scaleFactor, scaleFactor, scaleFactor]

                let bounding = cube.visualBounds(relativeTo: cube)
                cube.physicsBody = PhysicsBodyComponent(
                    massProperties: .init(mass: 0.05),
                    material: .default,
                    mode: .dynamic
                )
                cube.collision = CollisionComponent(
                    shapes: [ShapeResource.generateBox(size: bounding.extents)]
                )

                // Assign a unique name to each cube
                cube.name = "cube_\(UUID().uuidString)"

                return cube
            }

            // MARK: - Ball Creation and Placement

            // Create Ball by Cloning the Template
            func createBall() -> ModelEntity {
                let ball = ballTemplate.clone(recursive: true)
                ball.name = "ball" // Unique name for identification
                return ball
            }

            // Create Ball Anchor Entity at a Specific Position
            func createBallEntity(at position: SIMD3<Float>) -> AnchorEntity {
                let ball = createBall()
                ball.position = position

                let ballAnchor = AnchorEntity(world: position)
                ballAnchor.addChild(ball)
                return ballAnchor
            }

            // Create and Place Ball in the Scene
            func createAndPlaceBall(in arView: ARView) {
                guard self.gameSettings.ballsRemaining > 0 else { return }

                // Remove Existing Ball if Any
                if let existingBall = arView.scene.findEntity(named: "ball") {
                    existingBall.removeFromParent()
                }

                let ball = createBall()
                var ballPosition: SIMD3<Float>

                if let initialPosition = self.initialBallPosition {
                    ballPosition = initialPosition
                } else if let cameraTransform = arView.session.currentFrame?.camera.transform {
                    let forward = normalize(-cameraTransform.columns.2.xyz)
                    let cameraPosition = cameraTransform.position
                    ballPosition = cameraPosition + forward * 0.1
                    ballPosition.y += 0.005
                    self.initialBallPosition = ballPosition
                } else {
                    ballPosition = [0, 0, 0]
                }

                ball.position = ballPosition

                let ballAnchor = AnchorEntity(world: ball.position)
                ballAnchor.addChild(ball)
                arView.scene.addAnchor(ballAnchor)
            }

            // MARK: - Gesture Handlers

            // Handle Tap Gesture to Place Tower
            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                guard let arView = gesture.view as? ARView else { return }

                // Prevent placing multiple towers
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

                    // Ensure the tower is placed at a reasonable distance
                    if distance < 0.5 {
                        let direction = normalize(position - cameraPosition)
                        position = cameraPosition + direction * 0.5
                    }

                    // Create and Add Tower Anchor
                    let anchor = AnchorEntity(world: position)
                    gameSettings.towerAnchor = anchor
                    arView.scene.addAnchor(anchor)
                    setupScene(in: arView)

                    // Haptic Feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }

            // Handle Swipe Gesture to Throw Ball
            @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
                guard let arView = gesture.view as? ARView else { return }
                guard let ball = arView.scene.findEntity(named: "ball") as? ModelEntity else { return }

                if gesture.state == .ended {
                    if let cameraTransform = arView.session.currentFrame?.camera.transform {
                        let forward = normalize(-cameraTransform.columns.2.xyz)
                        // Apply a slower force
                        let forceMagnitude: Float = 0.0007
                        let force = forward * forceMagnitude
                        ball.physicsBody?.mode = .dynamic
                        ball.physicsBody?.massProperties = .init(mass: 0.001)
                        ball.applyLinearImpulse(force, relativeTo: nil)

                        // Play Throw Sound
                        throwSoundPlayer?.play()

                        // Haptic Feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()

                        // Update Game State
                        DispatchQueue.main.async {
                            self.gameSettings.ballsRemaining -= 1
                            if self.gameSettings.ballsRemaining > 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.createAndPlaceBall(in: arView)
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.gameSettings.isGameOver = true
                                    self.gameSettings.gameResult = self.gameSettings.score == 6 ? "You won!" : "You lost!"
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Collision Handling

            func handleCollision(event: CollisionEvents.Began) {
                guard arView != nil else { return }

                let entityA = event.entityA
                let entityB = event.entityB

                // Check if the collision involves the ball
                if entityA.name == "ball" || entityB.name == "ball" {
                    _ = entityA.name == "ball" ? entityA : entityB
                    let otherEntity = entityA.name == "ball" ? entityB : entityA

                    // Play ball hit sound
                    if otherEntity is ModelEntity { // Ensure it's a physical object
                        ballHitSoundPlayer?.play()
                    }
                }

                // Check if the collision involves any cube
                if entityA.name.starts(with: "cube_") || entityB.name.starts(with: "cube_") {
                    _ = entityA.name.starts(with: "cube_") ? entityA : entityB
                    let otherEntity = entityA.name.starts(with: "cube_") ? entityB : entityA

                    // Play cube hit sound
                    if otherEntity is ModelEntity { // Ensure it's a physical object
                        cubeHitSoundPlayer?.play()
                    }
                }
            }

            // MARK: - Constants

            let cubeHeight: Float = 0.0008 // Adjusted to 0.8 meters
            let cubeDiameter: Float = 1.0
        }
    }
}
