//  ContentView.swift

import SwiftUI
import RealityKit
import ARKit
import simd
import Combine
import UIKit

class GameSettings: ObservableObject {
    @Published var isGameStarted: Bool = false
    @Published var towerAnchor: AnchorEntity? = nil
    @Published var hasPlacedCans: Bool = false
    @Published var showWaitingMessage: Bool = true
    @Published var showTowerAlreadyPlacedMessage: Bool = false
    @Published var score: Int = 0
    @Published var ballsRemaining: Int = 3
    @Published var isGameOver: Bool = false
    @Published var gameResult: String? = nil
    @Published var showInstructionCard: Bool = false

    func resetGame() {
        self.isGameStarted = false
        self.towerAnchor?.removeFromParent()
        self.towerAnchor = nil
        self.hasPlacedCans = false
        self.showWaitingMessage = true
        self.showTowerAlreadyPlacedMessage = false
        self.score = 0
        self.ballsRemaining = 3
        self.isGameOver = false
        self.gameResult = nil
    }

    func startNewGame() {
        self.towerAnchor?.removeFromParent()
        self.towerAnchor = nil
        self.hasPlacedCans = false
        self.showWaitingMessage = true
        self.showTowerAlreadyPlacedMessage = false
        self.score = 0
        self.ballsRemaining = 3
        self.isGameOver = false
        self.gameResult = nil
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

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(gameSettings: gameSettings)
    }

    class Coordinator: NSObject {
        @ObservedObject var gameSettings: GameSettings
        var isSceneSetUp: Bool = false
        var arView: ARView?
        var cans: [ModelEntity] = []
        var subscriptions = Set<AnyCancellable>()
        var initialBallPosition: SIMD3<Float>?
        
        // Dimensiuni puțin mai mari: 0.001
        let canHeight: Float = 0.001
        let canDiameter: Float = 1.0

        // *** Adăugat: Template pentru mingă ***
        let ballTemplate: ModelEntity

        init(gameSettings: GameSettings) {
            self.gameSettings = gameSettings
            
            // *** Adăugat: Încărcare model mingă o singură dată ***
            self.ballTemplate = try! Entity.loadModel(named: "tennisball")
            let originalBounds = ballTemplate.visualBounds(relativeTo: nil)
            let scaleY = canHeight / originalBounds.extents.y
            let scaleX = canDiameter / originalBounds.extents.x
            let scaleZ = canDiameter / originalBounds.extents.z
            let scaleFactor = min(scaleX, scaleY, scaleZ)
            ballTemplate.scale = [scaleFactor, scaleFactor, scaleFactor]

            ballTemplate.physicsBody = PhysicsBodyComponent(
                massProperties: .init(mass: 0.005),
                material: .default,
                mode: .kinematic
            )
            ballTemplate.collision = CollisionComponent(
                shapes: [.generateSphere(radius: 0.001)]
            )
            ballTemplate.name = "ballTemplate" // Nume distinct pentru template
            
            super.init()
            
            _ = AudioManager.shared
        }

        func setupScene(in arView: ARView) {
            self.arView = arView
            guard let towerAnchor = gameSettings.towerAnchor else { return }

            placeCans(on: towerAnchor)
            arView.scene.addAnchor(towerAnchor)
            DispatchQueue.main.async {
                self.gameSettings.hasPlacedCans = true
                self.gameSettings.showWaitingMessage = false
            }

            let groundPlaneWidth: Float = 0.4
            let groundPlaneDepth: Float = 0.4
            let groundPlaneHeight: Float = 0.02
            let collisionHeight: Float = 0.005 // 5 mm

            let groundPlaneMesh = MeshResource.generateBox(size: [groundPlaneWidth, groundPlaneHeight, groundPlaneDepth])
            let groundPlaneMaterial = SimpleMaterial(color: .lightGray, isMetallic: false)
            let groundPlane = ModelEntity(mesh: groundPlaneMesh, materials: [groundPlaneMaterial])

            groundPlane.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
            
            // *** Modificat: Ajustarea formei de coliziune a groundPlane ***
            groundPlane.collision = CollisionComponent(
                shapes: [.generateBox(size: [groundPlaneWidth, collisionHeight, groundPlaneDepth])]
            )

            // *** Modificat: Ajustarea poziției groundPlane pentru noua formă de coliziune ***
            // Setează poziția corectă pe axa Y și elimină deplasarea pe axa Z
            // Formula: groundPlane.position.y = firstLayerY - (collisionHeight / 2)
            let firstLayerY = groundPlaneHeight + canHeight / 2 // 0.02 + 0.0005 = 0.0205
            groundPlane.position = [0, firstLayerY - (collisionHeight / 2), 0] // [0, 0.0205 - 0.0025, 0] = [0, 0.018, 0]
            towerAnchor.addChild(groundPlane)

            arView.scene.subscribe(to: SceneEvents.Update.self) { event in
                self.update(event: event)
            }.store(in: &self.subscriptions)

            // După 0.5s plasăm mingea
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.createAndPlaceBall(in: arView)
            }

            // După 0.2s, toate conservele devin dinamice
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                for can in self.cans {
                    can.physicsBody?.mode = .dynamic
                }
            }

            isSceneSetUp = true
        }

        func update(event: SceneEvents.Update) {
            var cansToRemove: [ModelEntity] = []
            for can in cans {
                if can.position(relativeTo: nil).y < -1.5 {
                    cansToRemove.append(can)
                }
            }
            for can in cansToRemove {
                if let index = self.cans.firstIndex(of: can) {
                    self.cans.remove(at: index)
                    can.removeFromParent()
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

        func placeCans(on anchor: AnchorEntity) {
            let groundPlaneHeight: Float = 0.02
            let spacing: Float = 0.1 // 10 cm spațiu vertical între straturi

            // Calcularea pozițiilor pe axa Y
            let firstLayerY = groundPlaneHeight + canHeight / 2
            let secondLayerY = firstLayerY + canHeight + spacing
            let thirdLayerY = secondLayerY + canHeight + spacing

            // Poziții orizontale pentru fiecare strat (metri)
            let positionsBottom: [Float] = [-0.1, 0.0, 0.1] // 10 cm la stânga, centru, 10 cm la dreapta
            let positionsMid: [Float] = [-0.05, 0.05] // 5 cm la stânga și 5 cm la dreapta
            let positionTop: Float = 0.0 // Centru

            func createCan() -> ModelEntity {
                let can = try! Entity.loadModel(named: "can")
                let originalBounds = can.visualBounds(relativeTo: nil)
                let scaleY = canHeight / originalBounds.extents.y
                let scaleX = canDiameter / originalBounds.extents.x
                let scaleZ = canDiameter / originalBounds.extents.z
                let scaleFactor = min(scaleX, scaleY, scaleZ)
                can.scale = [scaleFactor, scaleFactor, scaleFactor]

                let bounding = can.visualBounds(relativeTo: can)
                can.physicsBody = PhysicsBodyComponent(
                    massProperties: .init(mass: 0.5),
                    material: .default,
                    mode: .kinematic
                )
                can.collision = CollisionComponent(
                    shapes: [ShapeResource.generateBox(size: bounding.extents)]
                )

                return can
            }

            // 3 conserve la baza
            for i in 0..<positionsBottom.count {
                let can = createCan()
                can.position = [positionsBottom[i], firstLayerY, 0]
                anchor.addChild(can)
                cans.append(can)
            }

            // 2 conserve în mijloc
            for i in 0..<positionsMid.count {
                let can = createCan()
                can.position = [positionsMid[i], secondLayerY, 0]
                anchor.addChild(can)
                cans.append(can)
            }

            // 1 conservă în vârf
            let topCan = createCan()
            topCan.position = [positionTop, thirdLayerY, 0]
            anchor.addChild(topCan)
            cans.append(topCan)
        }

        // *** Modificat: Create Ball prin clonare ***
        func createBall() -> ModelEntity {
            // Clonează template-ul mingii în loc să încarci din nou modelul
            let ball = ballTemplate.clone(recursive: true)
            ball.name = "ball" // Nume pentru identificare
            return ball
        }

        func createBallEntity(at position: SIMD3<Float>) -> AnchorEntity {
            let ball = createBall()
            ball.position = position

            let ballAnchor = AnchorEntity(world: position)
            ballAnchor.addChild(ball)
            return ballAnchor
        }

        func createAndPlaceBall(in arView: ARView) {
            guard self.gameSettings.ballsRemaining > 0 else { return }
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

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            if gameSettings.hasPlacedCans || !gameSettings.isGameStarted {
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
                    let direction = normalize(position - cameraPosition)
                    position = cameraPosition + direction * 0.5
                }
                let anchor = AnchorEntity(world: position)
                gameSettings.towerAnchor = anchor
                arView.scene.addAnchor(anchor)
                setupScene(in: arView)

                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }

        @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            guard let ball = arView.scene.findEntity(named: "ball") as? ModelEntity else { return }

            if gesture.state == .ended {
                if let cameraTransform = arView.session.currentFrame?.camera.transform {
                    let forward = normalize(-cameraTransform.columns.2.xyz)
                    // Mingea mai lentă
                    let forceMagnitude: Float = 0.001
                    let force = forward * forceMagnitude
                    ball.physicsBody?.mode = .dynamic
                    ball.physicsBody?.massProperties = .init(mass: 0.001)
                    ball.applyLinearImpulse(force, relativeTo: nil)

                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

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
    }
}
