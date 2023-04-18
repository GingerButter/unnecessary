//
//  ListeningMode.swift
//  AudioProject
//
//  Created by Yuni Park on 4/3/23.
//
import SwiftUI
import Foundation
import AVFoundation
import Combine
import SoundAnalysis

struct ListeningMode: View {
    @Binding var tabSelection: Int
    // @State var popUpReady = false
    @StateObject var audioRecorder = AudioRecorder(tabSelection: .constant(3))
    @State var isRecording = false
    @EnvironmentObject var sheetManagerListen: SheetManager
    @State private var showPopUp: Bool = false
    

    var body: some View {
        VStack {
            GeometryReader{geometry in
                Button(action: toggleRecording) {
                    ZStack{
                        Text(isRecording ? "Stop Recording" : "Start Recording")
                            .foregroundColor(.white)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color(red: 0.36, green: 0.66, blue: 0.87, opacity: 1.0), Color(red: 0.33, green: 0.77, blue: 0.44, opacity: 1.0),]), startPoint: .topTrailing, endPoint: .bottomLeading))
                            .cornerRadius(8)
                            .font(.system(size: 32))
                            .frame(width: geometry.size.width * 0.8, height: geometry.size.height*0.2)
                    }
                        
                }
                .position(x:geometry.size.width*0.5, y:geometry.size.height*0.5)
//                .background(.radialGradient(colors: [.white, .gray], center: .center, startRadius: 100, endRadius: 700))
                .cornerRadius(8)
                
            }
        }
//        .sheet(isPresented: $showPopUp) {
//            PopUpView(recList: audioRecorder.recommendation, didClose: {
//                audioRecorder.popUpReady = false
//                showPopUp = false
//            })
//        }
        .onChange(of: audioRecorder.popUpReady) {value in
            if(value){
                withAnimation{
                    sheetManagerListen.present()
                }
            }
        }

        .overlay(alignment: .center) {
            if sheetManagerListen.action.isPresented {

                PopUpView(recList: $audioRecorder.recommendation, tabSelection: $tabSelection, audioRecorder: audioRecorder, didClose: {
                    audioRecorder.popUpReady = false;
                    sheetManagerListen.dismiss()
                })
            }
        }
        .padding()
    }
    
    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
        } else {
            audioRecorder.startRecording()
        }
        isRecording.toggle()
    }
    
}

struct PopUpView: View {
    let didClose: () -> Void
    @Binding private var recList: [String]
    @Binding var tabSelection: Int
    @ObservedObject private var audioRecorder: AudioRecorder
    @EnvironmentObject var sheetManager: SheetManager
    @EnvironmentObject var soundsList: SoundsList
    @EnvironmentObject var sheetManagerListen: SheetManager
    private var nature = Set(["Brook", "Wind", "Birds", "Waves"])
    
    
    init(recList: Binding<[String]>, tabSelection: Binding<Int>, audioRecorder: AudioRecorder, didClose: @escaping () -> Void){
        self._recList = recList
        self._tabSelection = tabSelection
        self.audioRecorder = audioRecorder
        self.didClose = didClose
        print("recList")
        print(self.recList)
    }
    
    private func getColor(color: String) -> Color{
        let baseColour: Color
        switch color {
        case "White": baseColour = Color.gray
        case "Purple": baseColour = Color.purple
        case "Blue": baseColour = Color.blue
        case "Red": baseColour = Color.red
        case "Orange": baseColour = Color.orange
        case "Pink": baseColour = Color.pink
        case "Yellow": baseColour = Color.yellow
        case "Green": baseColour = Color.green
        case "Brown": baseColour = Color.brown
        default: baseColour = Color.clear
        }
        return baseColour
    }
    
    var body: some View{
        
        VStack {
            Text("Recommendation")
            ForEach(recList.indices, id: \.self){ index in
                Text(recList[index])
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(getColor(color: recList[index]).opacity(0.8))
                        .frame(width: 200))
                    .font(.title)
                    .padding()
            }
            Button(action: {
                self.tabSelection = 1
                sheetManager.dismiss()
                audioRecorder.popUpReady = false;
                sheetManagerListen.dismiss()
                for color in recList {
                    streamAudioFile(soundsList: soundsList, color: color, state: .on, volume: 0.5)
                    // TODO: display the buttons as they should
                }
            }){
                Text("GO")
            }
        }
        .frame(width: 240, height: 160)
        .padding()
        .multilineTextAlignment(.center)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.2), radius: 3))
        .transition(.move(edge: .leading))
        .overlay(alignment: .topTrailing) {
            close
        }
        .transition(.move(edge: .bottom))
    }
    
}

private extension PopUpView {
    var close: some View {
        Button {
            didClose()
        } label: {
            Image(systemName: "xmark")
                .symbolVariant(.circle.fill)
                .font(
                    .system(size: 35,
                            weight: .bold,
                            design: .rounded)
                )
                .foregroundStyle(.gray.opacity(0.4))
                .padding(8)
        }
    }
}
