//
//  AddHapticsView.swift
//  HapticsPalette
//
//  Created by Issac Penn on 3/15/20.
//  Copyright © 2020 Issac Penn. All rights reserved.
//

import SwiftUI
import CoreHaptics

struct AddHapticsView: View {
    private let types = ["Transient", "Continuous", "Pause"]
    @Binding var engine: CHHapticEngine!
    @State private var selection = "Transient"
    @State private var relativeTime = "0"
    @State private var duration = "0.5"
    @State private var intensity = 0.5
    @State private var sharpness = 0.5
    @State private var attackTime = 0.0
    @State private var decayTime = 0.0
    @State private var sustained = true
    @State private var releaseTime = 0.0
    @State private var continuousPreview = false
    @State private var hapticEvent: CHHapticEvent!
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        Picker("Type", selection: $selection) {
                            ForEach(types, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(SegmentedPickerStyle())
                        
                        HStack {
                            Text("Intensity")
                            Slider(value: $intensity, in: 0.0...1.0, onEditingChanged: self.continuousPreview)
                            Text("\(intensity, specifier:"%.02f")")
                        }
                        HStack {
                            Text("Sharpness")
                            Slider(value: $sharpness, in: 0.0...1.0, onEditingChanged: self.continuousPreview)
                            Text("\(sharpness, specifier:"%.02f")")
                        }
                        HStack {
                            Text("Relative Time (seconds)")
                                .layoutPriority(1)
                                .padding(.trailing, 8)
                            TextField("", text: $relativeTime, onCommit: { self.continuousPreview() })
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Duration (seconds)")
                                .layoutPriority(1)
                                .padding(.trailing, 8)
                            TextField("", text: $duration, onCommit: { self.continuousPreview() })
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section (header: Text("ENVELOPE PARAMETERS")) {
                        HStack {
                            Text("Attack Time")
                            Slider(value: $attackTime, in: -1.0...1.0, onEditingChanged: self.continuousPreview)
                            Text("\(attackTime, specifier:"%.02f")")
                        }
                        HStack {
                            Text("Decay Time")
                            Slider(value: $decayTime, in: -1.0...1.0, onEditingChanged: self.continuousPreview)
                            Text("\(decayTime, specifier:"%.02f")")
                        }
                        HStack {
                            Toggle("Sustained", isOn: $sustained)
                                .onTapGesture {
                                    self.continuousPreview()
                            }
                        }
                        HStack {
                            Text("Release Time")
                            Slider(value: $releaseTime, in: -1.0...1.0, onEditingChanged: self.continuousPreview)
                            Text("\(releaseTime, specifier:"%.02f")")
                        }
                    }
                    
                    Section (header: Text("PREVIEW"), footer: Text("Automatically plays haptic preview each time you change a parameter.")) {
                        Toggle("Continuous Preview", isOn: $continuousPreview)
                    }
                    
                }
                
                HStack {
                    Button("Preview") {
                        self.previewHaptics()
                    }
                    Spacer()
                    Button("Add") {
                        
                    }
                    .font(Font.body.weight(.medium))
                }
                .padding(.horizontal)
                
                
            }
            .navigationBarTitle(Text("Add Haptics"), displayMode: .large)
            .navigationBarItems(leading: Button("Cancel"){
                self.presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func createHapticEvent() {
        let eventType: CHHapticEvent.EventType
        switch selection {
        case "Transient":
            eventType = .hapticTransient
        case "Continuous":
            eventType = .hapticContinuous
        default:
            eventType = .hapticTransient
        }
        
        let parameters = [CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(self.intensity)),
                          CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(self.sharpness)),
                          CHHapticEventParameter(parameterID: .attackTime, value: Float(self.attackTime)),
                          CHHapticEventParameter(parameterID: .decayTime, value: Float(self.decayTime)),
                          CHHapticEventParameter(parameterID: .sustained, value: Float(self.sustained ? 1.0 : 0.0)),
                          CHHapticEventParameter(parameterID: .releaseTime, value: Float(self.releaseTime))
        ]
        
        let relativeTime = Double(self.relativeTime) ?? 0.0
        let duration = Double(self.duration) ?? 1.0
        
        let hapticEvent = CHHapticEvent(eventType: eventType, parameters: parameters, relativeTime: relativeTime, duration: duration)
        self.hapticEvent = hapticEvent
    }
    
    func previewHaptics() {
        self.createHapticEvent()
        do {
            let pattern = try CHHapticPattern(events: [self.hapticEvent], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to create palyer: \(error)")
        }
    }
    
    func continuousPreview(isStartingChanging: Bool = false) {
        if self.continuousPreview && !isStartingChanging {
            self.previewHaptics()
        }
    }
}

struct AddHapticsView_Previews: PreviewProvider {
    static var previews: some View {
        let engine = Binding.constant(try? CHHapticEngine())
        return AddHapticsView(engine: engine)
    }
}

// implementing scroll/touch to dismiss keyboard
class AnyGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}

extension SceneDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
