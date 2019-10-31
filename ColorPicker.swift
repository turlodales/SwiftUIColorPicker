//
//  ColorPicker.swift
//  ColorPickers
//
//  Created by Kieran Brown on 10/31/19.
//  Copyright © 2019 Kieran Brown. All rights reserved.
//

import SwiftUI

struct ColorPicker: View {
    @GestureState var hueState: DragState = .inactive
    @GestureState var satBrightState: DragState = .inactive
    @State var hue: Double = 0.5
    @State var saturation: Double = 0.5
    @State var brightness: Double = 0.5
    var gridSize: CGSize = CGSize(width: 500, height: 300)
    var sliderSize: CGSize = CGSize(width: 500, height: 7)
    
    
    
    /// Prevent the draggable element from going over its limit
    func limitDisplacement(_ value: Double, _ limit: CGFloat, _ state: CGFloat) -> CGFloat {
        if CGFloat(value)*limit + state > limit {
            return limit
        } else if CGFloat(value)*limit + state < 0 {
            return 0
        } else {
            return CGFloat(value)*limit + state
        }
    }
    /// Prevent values like hue, saturation and brightness from being greater than 1 or less than 0
    func limitValue(_ value: Double, _ limit: CGFloat, _ state: CGFloat) -> Double {
        if value + Double(state/limit) > 1 {
            return 1
        } else if value + Double(state/limit) < 0 {
            return 0
        } else {
            return value + Double(state/limit)
        }
    }
    
    /// Labels for each of the Hue, Saturation and Brightness
    var labels: some View {
        VStack {
            Text("Hue: \(limitValue(self.hue, sliderSize.width, hueState.translation.width))")
            Text("Saturation: \(limitValue(self.saturation, gridSize.width, satBrightState.translation.width))")
            Text("Brightness: \(1-limitValue(self.brightness, gridSize.height, satBrightState.translation.height))")
        }
    }
    
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20).foregroundColor(Color(hue: limitValue(self.hue, sliderSize.width, hueState.translation.width),
                                                                         saturation: limitValue(self.saturation, gridSize.width, satBrightState.translation.width),
                                                                         brightness: 1-limitValue(self.brightness, gridSize.height, satBrightState.translation.height))).aspectRatio(1, contentMode: .fit)
                labels
            }
            VStack {
                satBrightnessGrid
                hueSlider
                
                }.frame(width: 500, height: 500).padding()
        }.frame(idealWidth: 750, maxWidth: .infinity, idealHeight: 750, maxHeight: .infinity)
    }
    
    
    // MARK: Hue Slider
    
    
    func makeHueColors(stepSize: Double) -> [Color] {
        stride(from: 0, to: 1, by: stepSize).map {
            Color(hue: $0, saturation: 1, brightness: 1)
        }
    }
    
    /// Creates the `Thumb` and adds the drag gesture to it.
    func generateHueThumb(proxy: GeometryProxy) -> some View {
        
        // This gesture sequence is also directly from apples "Composing SwiftUI Gestures"
        let longPressDrag = LongPressGesture(minimumDuration: 0.05)
            .sequenced(before: DragGesture())
            .updating($hueState) { value, state, transaction in
                switch value {
                // Long press begins.
                case .first(true):
                    state = .pressing
                // Long press confirmed, dragging may begin.
                case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                }
        }
        .onEnded { value in
            guard case .second(true, let drag?) = value else { return }
            
            self.hue = self.limitValue(self.hue, proxy.size.width, drag.translation.width)
            
        }
        
        
        // MARK: Customize Thumb Here
        // Add the gestures and visuals to the thumb
        return Circle().overlay(hueState.isDragging ? Circle().stroke(Color.white, lineWidth: 2) : nil)
            .foregroundColor(.white)
            .frame(width: 25, height: 25, alignment: .center)
            .position(x: limitDisplacement(self.hue, proxy.size.width, hueState.translation.width) , y: sliderSize.height/2)
            .animation(.interactiveSpring())
            .gesture(longPressDrag)
    }
    
    var hueSlider: some View {
        GeometryReader { (proxy: GeometryProxy) in
            LinearGradient(gradient: Gradient(colors: self.makeHueColors(stepSize: 0.05)),
                           startPoint: .leading, endPoint: .trailing).mask(Capsule()).frame(width: self.sliderSize.width, height: self.sliderSize.height).drawingGroup()
            .overlay(self.generateHueThumb(proxy: proxy))
        }
    }
    
    
    // MARK: Saturation and Brightness Grid
    
    
    func makeSatBrightColors(stepSize: Double) -> [Color] {
        stride(from: 0, to: 1, by: stepSize).map {
            Color(hue: limitValue(self.hue, self.sliderSize.width, hueState.translation.width), saturation: $0, brightness: 1-$0)
        }
    }
    
    /// Creates the `Handle` and adds the drag gesture to it.
    func generateSBHandle(proxy: GeometryProxy) -> some View {
        
        // This gesture sequence is also directly from apples "Composing SwiftUI Gestures"
        let longPressDrag = LongPressGesture(minimumDuration: 0.05)
            .sequenced(before: DragGesture())
            .updating($satBrightState) { value, state, transaction in
                switch value {
                // Long press begins.
                case .first(true):
                    state = .pressing
                // Long press confirmed, dragging may begin.
                case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                }
        }
        .onEnded { value in
            guard case .second(true, let drag?) = value else { return }
            
            self.saturation = self.limitValue(self.saturation, proxy.size.width, drag.translation.width)
            self.brightness = self.limitValue(self.brightness, proxy.size.height, drag.translation.height)
        }
        
        
        // MARK: Customize Handle Here
        // Add the gestures and visuals to the handle
        return Circle().overlay(satBrightState.isDragging ? Circle().stroke(Color.white, lineWidth: 2) : nil)
            .foregroundColor(.white)
            .frame(width: 25, height: 25, alignment: .center)
            .position(x: limitDisplacement(self.saturation, self.gridSize.width, self.satBrightState.translation.width) , y: limitDisplacement(self.brightness, self.gridSize.height, self.satBrightState.translation.height))
            .animation(.interactiveSpring())
            .gesture(longPressDrag)
    }
    
    var satBrightnessGrid: some View {
        GeometryReader { (proxy: GeometryProxy) in
            LinearGradient(gradient: Gradient(colors: self.makeSatBrightColors(stepSize: 0.05)), startPoint: .topLeading, endPoint: .bottomTrailing).frame(width: self.gridSize.width, height: self.gridSize.height).overlay(self.generateSBHandle(proxy: proxy))
        }
    }
}

