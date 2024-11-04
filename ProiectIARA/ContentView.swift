//
//  ContentView.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 21.10.2024.
//

import SwiftUI
import RealityKit
import ARKit

class CubeSettings: ObservableObject {
    @Published var color: UIColor = .white
}

struct ContentView: View {
    @StateObject private var cubeSettings = CubeSettings()

    var body: some View {
        ARViewContainer(cubeSettings: cubeSettings)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var cubeSettings: CubeSettings
    let arView = ARView(frame: .zero)

    func makeUIView(context: Context) -> ARView {
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // Configure tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)

        // Configure pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan))
        arView.addGestureRecognizer(panGesture)
        
        // Create a cube model
        let cube = createCube()
        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(cube)
        arView.scene.addAnchor(anchor)

        // Set the model entity in the coordinator
        context.coordinator.modelEntity = cube
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // No additional updates required here
    }
    
    func createCube() -> ModelEntity {
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: cubeSettings.color, roughness: 0.15, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = [0, 0.05, 0]  // Set the initial position of the cube
        
        // Enable tap interactions
        model.generateCollisionShapes(recursive: true)
        
        return model
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ARViewContainer
        var modelEntity: ModelEntity?
        private let fixedHeight: Float = 0.05  // Înălțimea fixă la care vrem să păstrăm cubul
        
        // Variabile pentru a salva poziția inițială a cubului și a gestului
        private var initialPosition: SIMD3<Float>?
        private var initialGesturePoint: CGPoint?

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? ARView, let model = modelEntity else { return }
            
            // Detect where the user tapped
            let tapLocation = gesture.location(in: view)
            if let tappedEntity = view.entity(at: tapLocation) as? ModelEntity, tappedEntity == model {
                // Generate a random color
                let randomColor = UIColor(
                    red: CGFloat.random(in: 0...1),
                    green: CGFloat.random(in: 0...1),
                    blue: CGFloat.random(in: 0...1),
                    alpha: 1.0
                )
                
                // Create a new material with the random color
                let newMaterial = SimpleMaterial(color: randomColor, roughness: 0.15, isMetallic: false)

                // Update the model's materials
                model.model?.materials = [newMaterial]
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView, let model = modelEntity else { return }

            let tapLocation = gesture.location(in: view)

            switch gesture.state {
            case .began:
                // Salvăm poziția inițială a cubului și punctul inițial al gestului
                initialPosition = model.position
                initialGesturePoint = tapLocation
            case .changed:
                guard let initialPosition = initialPosition, let initialGesturePoint = initialGesturePoint else { return }
                
                // Calculează deplasarea
                let translation = gesture.translation(in: view)
                
                // Obținem transformarea camerei
                let cameraTransform = view.cameraTransform
                
                // Calculăm direcția de mișcare
                let forward = SIMD3<Float>(cameraTransform.rotation.act(SIMD3<Float>(0, 0, -1))) // înainte
                let right = SIMD3<Float>(cameraTransform.rotation.act(SIMD3<Float>(1, 0, 0))) // dreapta

                // Ajustează factorul de scalare pentru a schimba viteza de mișcare
                let scaleFactor: Float = 0.001  // Ajustare a vitezei mișcării
                
                // Actualizăm poziția cubului
                model.position = initialPosition + (forward * -Float(translation.y) * scaleFactor) + (right * Float(translation.x) * scaleFactor)
                
                // Păstrează înălțimea fixă
                model.position.y = fixedHeight
            case .ended, .cancelled:
                // Resetăm variabilele
                initialPosition = nil
                initialGesturePoint = nil
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}

