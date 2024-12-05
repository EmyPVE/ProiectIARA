//
//  AudioManager.swift
//  ProiectIARA
//
//  Created by Emanuel Prelipcean on 05.12.2024.
//
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?

    private init() {
        print("AudioManager a fost inițializat")
        configureAudioSession()
        playMusic()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Eroare la configurarea AudioSession: \(error.localizedDescription)")
        }
    }

    func playMusic() {
        guard let path = Bundle.main.path(forResource: "elevador-de-sonhos", ofType: "mp3") else {
            print("Fișierul audio nu a fost găsit.")
            return
        }

        print("Calea fișierului audio este: \(path)")

        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop infinit
            audioPlayer?.play()
        } catch {
            print("Eroare la redarea muzicii: \(error.localizedDescription)")
        }
    }
}

