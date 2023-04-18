//
//  AudioRecorder.swift
//  AudioProject
//
//  Created by Andy Jin on 4/4/23.
//
import Foundation
import AVFoundation
import CoreML
import Combine
import SoundAnalysis
import SwiftUI

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false;
    @Published var tabSelection: Binding<Int>?;
    // @Published var popUpReady: Binding<Bool>;
    @Published var popUpReady = false;
    private var audioRecorder: AVAudioRecorder!;
    private var audioFilename: URL?;
    private var audioPlayer: AVPlayer?;
    private var analysisResults: [String] = []
    private var PEOPLE: Set = ["speech", "singing", "singing_bowl", "shout", "sigh", "crowd", "cough", "applause"]
    private var KEYBOARD: Set = ["typewriter", "typing", "typing_computer_keyboard", "click"]
    private var PIPE: Set = ["tick", "thump_stud", "tap", "slap_smack", "saw", "printer", "knock", "hammer", "engine_knocking", "engine_starting", "engine_idling", "engine", "drum", "drum_kit", "drawer_open_close", "applause", "air_conditioner"]
    @Published public var recommendation: [String] = ["Yellow"] //Doesn't block noises so only plays when no other distraction is present
    
    init(tabSelection: Binding<Int>? = nil) {
        self.tabSelection = tabSelection;
        // self.popUpReady = popUpReady;
    }
    
    class ResultObserver: NSObject, SNResultsObserving {
        var collectedResults = [String]()
        
        func request(_ request: SNRequest, didProduce result: SNResult) {
            // Downcast the result to a classification result.
            guard let result = result as? SNClassificationResult else  { return }

            // Get the prediction with the highest confidence.
            guard let classification = result.classifications.first else { return }

            // Get the starting time.
            let timeInSeconds = result.timeRange.start.seconds

            // Convert the time to a human-readable string.
//            let formattedTime = String(format: "%.2f", timeInSeconds)
//            print("Analysis result for audio at time: \(formattedTime)")

            // Convert the confidence to a percentage string.
            let percent = classification.confidence * 100.0
            let percentString = String(format: "%.2f%%", percent)
            
            if (percent > 40) {
                collectedResults.append(classification.identifier)
            }

            // Print the classification's name (label) with its confidence.
            print("\(classification.identifier): \(percentString) confidence.\n")
        }


        /// Notifies the observer when a request generates an error.
        func request(_ request: SNRequest, didFailWithError error: Error) {
            print("The analysis failed: \(error.localizedDescription)")
        }

        /// Notifies the observer when a request is complete.
        func requestDidComplete(_ request: SNRequest) {
            print("The request completed successfully!")
        }
    }
    
    func handleAnalysisResults(_ results: [String]) {
        
        DispatchQueue.main.async {
            if results.isEmpty {
                print("No results or an error occurred during analysis.")
            } else {
                print("Analysis results:")
                for result in results {
                    print(result)
                }
            }
            self.analysisResults = results
            //self.playMasker();
            print(self.analysisResults)
            for result in self.analysisResults {
                if (self.KEYBOARD.contains(result)) {
                    self.recommendation = ["Brown"]
                }
            }
            for result in self.analysisResults {
                if (self.PIPE.contains(result)) {
                    self.recommendation = ["Pink", "Brown"]
                }
            }
            for result in self.analysisResults {
                if (self.PEOPLE.contains(result)) {
                    self.recommendation = ["White", "Bird"]
                }
            }
//            if (self.analysisResults.isEmpty) {
//                self.recommendation = ["Blue"]
//            }
            print(self.recommendation)
            self.popUpReady = true
        }


    }

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

            isRecording = true
            print("Started recording")
        } catch let error {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }
    func stopRecording() {
        stop(completion: handleAnalysisResults)
        // tabSelection.wrappedValue = 1
    }

    func stop(completion: @escaping ([String]) -> Void) {
        audioRecorder.stop()
        isRecording = false
        print("Stopped recording")

        let version1 = SNClassifierIdentifier.version1
        print(version1)
        let request = try? SNClassifySoundRequest(classifierIdentifier: version1)
        guard let classifyRequest = request else {
            print("Failed to create sound analysis request.")
            completion([])
            return
        }
        let resultObserver = ResultObserver()
        do {

            let analyzer = try SNAudioFileAnalyzer(url: audioFilename!)
            try analyzer.add(classifyRequest, withObserver: resultObserver)
            DispatchQueue.global().async {
                analyzer.analyze { error in
                   
                    if !error {
                        print(error)
                        completion([])
                    }
                    else{
                        completion(resultObserver.collectedResults)
                    }
                    

                }
            }
            
        } catch {
            print("stop recording error")
        }
        
    }


    func playMasker() {
        print(analysisResults)
        for result in analysisResults {
            if (KEYBOARD.contains(result)) {
                recommendation = ["Brown"]
            }
        }
        for result in analysisResults {
            if (PIPE.contains(result)) {
                recommendation = ["Pink", "Brown"]
            }
        }
        for result in analysisResults {
            if (PEOPLE.contains(result)) {
                recommendation = ["White", "Bird"]
            }
        }
//        if (analysisResults.isEmpty) {
//            recommendation = ["Blue"]
//        }
        print(recommendation)
        self.popUpReady = true
        
        
    }

    func playAudio(from url: String) {
        if let audioURL = URL(string: url) {
            audioPlayer = AVPlayer(url: audioURL)
            audioPlayer?.play()
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths)
        return paths[0]
    }
    
    func switchTab() {
        
    }

}
