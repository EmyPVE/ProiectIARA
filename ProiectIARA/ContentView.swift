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

class GameSettings: ObservableObject {
    @Published var isGameStarted: Bool = false
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3(self.columns.3.x, self.columns.3.y, self.columns.3.z)
    }
}

struct ContentView: View {
    var isTabletopMode: Bool

    var body: some View {
        ARViewContainer(isTabletopMode: isTabletopMode)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    var isTabletopMode: Bool
    let arView = ARView(frame: .zero)

    func makeUIView(context: Context) -> ARView {
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        // Add gesture recognizer for swipe
        let swipeGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSwipe))
        arView.addGestureRecognizer(swipeGesture)

        // Set up the scene based on mode
        context.coordinator.setupScene(in: arView, isTabletopMode: isTabletopMode)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        override init() {
                super.init()
            }
        
        func setupScene(in arView: ARView, isTabletopMode: Bool) {
            // Încărcare skybox
            do {
                let skyboxResource = try EnvironmentResource.load(named: "light.skybox")
                arView.environment.lighting.resource = skyboxResource
            } catch {
                print("Eroare: Nu s-a putut încărca skybox-ul din light.skybox")
            }
            
            // Eliminăm reflexiile suplimentare prin reducerea intensității luminii implicite
            arView.environment.lighting.intensityExponent = 0.0

            // Ancorare pe planul orizontal detectat
            let planeAnchor = AnchorEntity(plane: .horizontal)
            planeAnchor.position.z -= 0.125
            arView.scene.addAnchor(planeAnchor)
            
            // Colizor invizibil
            let invisibleCollider = ModelEntity(mesh: .generatePlane(width: 1.0, depth: 1.0))
            let material = semiTransparentShader(0.0) // Material invizibil
            invisibleCollider.model?.materials = [material]
            
            invisibleCollider.physicsBody = PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .static
            )
            invisibleCollider.collision = CollisionComponent(
                shapes: [.generateBox(size: [1.0, 0.00001, 1.0])]
            )
            planeAnchor.addChild(invisibleCollider)
            
            func semiTransparentShader(_ value: Float) -> RealityFoundation.Material {
                var material = PhysicallyBasedMaterial()
                material.baseColor = .init(tint: .clear) // Fără culoare vizibilă
                material.blending = .transparent(opacity: .init(floatLiteral: value)) // Setăm transparența
                return material
            }


            let cubeSize: Float = isTabletopMode ? 0.05 : 0.1
            let spacing: Float = cubeSize * 0.4 // Distanță între cuburi
            let ballRadius: Float = isTabletopMode ? 0.025 : 0.07
            let ballPosition: SIMD3<Float> = isTabletopMode ? [0, 0.1, 0.2] : [0, cubeSize, -0.5]

            // Poziții pentru piramida de cuburi
            let pyramidPositions: [[SIMD3<Float>]] = [
                [SIMD3(-cubeSize - spacing, cubeSize / 2, 0), SIMD3(0, cubeSize / 2, 0), SIMD3(cubeSize + spacing, cubeSize / 2, 0)], // Bază
                [SIMD3(-cubeSize / 2 - spacing / 2, cubeSize + cubeSize / 2, 0), SIMD3(cubeSize / 2 + spacing / 2, cubeSize + cubeSize / 2, 0)], // Mijloc
                [SIMD3(0, 2 * cubeSize + cubeSize / 2, 0)] // Vârf
            ]

            // Creăm cuburile
            for row in pyramidPositions {
                for position in row {
                    let cube = ModelEntity(mesh: .generateBox(size: cubeSize), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                    cube.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
                    cube.collision = CollisionComponent(shapes: [.generateBox(size: [cubeSize, cubeSize, cubeSize])])
                    cube.position = position
                    planeAnchor.addChild(cube)
                }
            }

            // Adăugăm mingea
            let ball = ModelEntity(mesh: .generateSphere(radius: ballRadius), materials: [SimpleMaterial(color: .red, isMetallic: true)])
            ball.position = ballPosition
            ball.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
            ball.collision = CollisionComponent(shapes: [.generateSphere(radius: ballRadius)])
            ball.name = "ball"

            let ballAnchor = AnchorEntity(plane: .horizontal)
            ballAnchor.addChild(ball)
            arView.scene.addAnchor(ballAnchor)
        }



        func createCube(size: Float) -> ModelEntity {
            let cube = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            cube.physicsBody = PhysicsBodyComponent(massProperties: .default,
                                                    material: .default,
                                                    mode: .static)
            cube.collision = CollisionComponent(shapes: [.generateBox(size: [size, size, size])])
            return cube
        }

        func createBall(radius: Float) -> ModelEntity {
            let ball = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: .red, isMetallic: true)])
            ball.collision = CollisionComponent(shapes: [.generateSphere(radius: radius)])
            ball.name = "ball" // Give the ball a name for identification
            return ball
        }

        @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            
            // Găsim mingea
            guard let ball = arView.scene.findEntity(named: "ball") as? ModelEntity else { return }
            
            if gesture.state == .ended {
                // Traducem mișcarea swipe-ului în forță aplicată mingii
                let translation = gesture.translation(in: arView)
                let swipeDirection = SIMD3<Float>(
                    Float(-translation.x) * 0.001, // Direcția X
                    0,                            // Nu aplicăm forță pe Y
                    Float(-translation.y) * 0.001 // Direcția Z
                )
                ball.physicsBody?.mode = .dynamic
                ball.applyLinearImpulse(simd_normalize(swipeDirection) * 0.02, relativeTo: nil)
            }
        }
    }
}
