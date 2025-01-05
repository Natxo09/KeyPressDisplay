//
//  ContentView.swift
//  KeyPressDisplay
//
//  Created by Ignacio Palacio  on 5/1/25.
//

import SwiftUI
import Carbon
import AppKit

struct ContentView: View {
    @ObservedObject var settings: Settings
    @State private var keyPresses: [KeyPress] = []
    @State private var isDragging: Bool = false
    @State private var isCommandPressed: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if settings.orientation == .vertical {
                    VStack(spacing: settings.spacing) {
                        ForEach(keyPresses.suffix(settings.maxVisibleKeys)) { keyPress in
                            KeyPressView(keyPress: keyPress, settings: settings)
                        }
                    }
                } else {
                    HStack(spacing: settings.spacing) {
                        ForEach(keyPresses.suffix(settings.maxVisibleKeys)) { keyPress in
                            KeyPressView(keyPress: keyPress, settings: settings)
                        }
                    }
                }
            }
            .padding()
            .background(settings.showBackground ? settings.keyBackgroundColor : Color.clear)
            .cornerRadius(12)
            .opacity(isDragging ? 0.6 : settings.opacity)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(isCommandPressed ? 0.5 : 0), lineWidth: 2)
            )
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .frame(width: 200, height: 100)
        .background(Color.clear)
        .onAppear {
            setupKeyMonitoring()
            setupCommandKeyMonitoring()
        }
        .onDisappear {
            KeyEventMonitor.shared.stopMonitoring()
        }
        .allowsHitTesting(true)
    }
    
    private func setupKeyMonitoring() {
        KeyEventMonitor.shared.startMonitoring { key in
            print("Tecla presionada: \(key)")
            addKeyPress(key)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                SettingsWindowManager.shared.showSettings(settings: settings)
                return nil
            }
            return event
        }
    }
    
    private func setupCommandKeyMonitoring() {
        // Monitor para la tecla Command
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            isCommandPressed = event.modifierFlags.contains(.command)
            
            if let window = NSApplication.shared.windows.first {
                // Permitir clicks solo cuando Command está presionado
                window.ignoresMouseEvents = !isCommandPressed
                
                // Cambiar el cursor según corresponda
                if isCommandPressed {
                    NSCursor.openHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            return event
        }
    }
    
    private func addKeyPress(_ key: String) {
        DispatchQueue.main.async {
            let keyPress = KeyPress(key: key)
            self.keyPresses.append(keyPress)
            print("Teclas actuales: \(self.keyPresses.count)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.settings.keyDisplayDuration) {
                self.keyPresses.removeAll { $0.id == keyPress.id }
            }
        }
    }
}

struct KeyPressView: View {
    let keyPress: KeyPress
    @ObservedObject var settings: Settings
    
    private var displayText: String {
        // Si es un símbolo especial, no aplicar transformación
        if keyPress.key.first?.isLetter == false {
            return keyPress.key
        }
        
        switch settings.caseStyle {
        case .uppercase:
            return keyPress.key.uppercased()
        case .lowercase:
            return keyPress.key.lowercased()
        case .auto:
            return keyPress.key
        }
    }
    
    // Calcular el ancho mínimo basado en el contenido
    private var minWidth: CGFloat {
        let hasModifier = displayText.contains("+") || displayText.contains("⌘") || 
                         displayText.contains("⌥") || displayText.contains("⌃") || 
                         displayText.contains("⇧")
        if hasModifier {
            return 60  // Más ancho para combinaciones
        } else if displayText.count > 1 {
            return 45  // Para teclas especiales
        } else {
            return 30  // Para teclas simples
        }
    }
    
    var body: some View {
        Text(displayText)
            .font(.system(size: settings.fontSize))
            .foregroundColor(settings.keyTextColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)  // Reducido de 8 a 6
            .padding(.vertical, 4)
            .frame(minWidth: minWidth)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(settings.keyBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(settings.keyTextColor.opacity(0.2), lineWidth: 1)
            )
    }
}

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @State private var selectedScreen: NSScreen = NSScreen.main ?? NSScreen.screens[0]
    
    var body: some View {
        Form {
            Section("Visualización") {
                Stepper("Número de teclas: \(settings.maxVisibleKeys)", value: $settings.maxVisibleKeys, in: 1...10)
                
                HStack {
                    Text("Duración:")
                    Slider(value: $settings.keyDisplayDuration, in: 0.5...5.0, step: 0.5)
                    Text("\(settings.keyDisplayDuration, specifier: "%.1f")s")
                }
                
                HStack {
                    Text("Tamaño:")
                    Slider(value: $settings.fontSize, in: 12...32, step: 1)
                    Text("\(Int(settings.fontSize))")
                }
                
                HStack {
                    Text("Opacidad:")
                    Slider(value: $settings.opacity, in: 0.2...1.0)
                    Text("\(Int(settings.opacity * 100))%")
                }
                
                HStack {
                    Text("Espaciado:")
                    Slider(value: $settings.spacing, in: 0...20)
                    Text("\(Int(settings.spacing))")
                }
                
                Picker("Orientación:", selection: $settings.orientation) {
                    ForEach(KeyDisplayOrientation.allCases, id: \.self) { orientation in
                        Text(orientation.rawValue).tag(orientation)
                    }
                }
                
                ColorPicker("Color de fondo:", selection: $settings.keyBackgroundColor)
                ColorPicker("Color de texto:", selection: $settings.keyTextColor)
                
                Toggle("Mostrar fondo", isOn: $settings.showBackground)
                
                Picker("Estilo de texto:", selection: $settings.caseStyle) {
                    ForEach(CaseStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }
            
            Section("Posición") {
                // Selector de pantalla
                Picker("Pantalla:", selection: $selectedScreen) {
                    ForEach(NSScreen.screens, id: \.self) { screen in
                        HStack {
                            Text(screen.localizedName)
                            if screen == NSScreen.main {
                                Text(" (Principal)")
                            }
                        }
                        .tag(screen)
                    }
                }
                .onChange(of: selectedScreen) { screen in
                    moveToScreen(screen)
                }
                
                // Posiciones predefinidas
                HStack {
                    Text("Posición:")
                    Spacer()
                    Button("Superior Izquierda") { moveToPosition(.topLeft) }
                    Button("Superior Derecha") { moveToPosition(.topRight) }
                }
                
                HStack {
                    Spacer()
                    Button("Centro") { moveToPosition(.center) }
                }
                
                HStack {
                    Spacer()
                    Button("Inferior Izquierda") { moveToPosition(.bottomLeft) }
                    Button("Inferior Derecha") { moveToPosition(.bottomRight) }
                }
                
                // Ajuste fino
                VStack(alignment: .leading) {
                    Text("Ajuste fino:")
                    HStack {
                        Spacer()
                        Button("←") { adjustPosition(dx: -20, dy: 0) }
                        Button("↑") { adjustPosition(dx: 0, dy: 20) }
                        Button("↓") { adjustPosition(dx: 0, dy: -20) }
                        Button("→") { adjustPosition(dx: 20, dy: 0) }
                        Spacer()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("Vista previa") {
                PreviewView(settings: settings)
                    .frame(height: 200)
            }
        }
        .padding()
        .frame(width: 600)
        .onAppear {
            print("Pantallas disponibles: \(NSScreen.screens.count)")
            NSScreen.screens.enumerated().forEach { index, screen in
                print("Pantalla \(index + 1):")
                print("  - Frame: \(screen.frame)")
                print("  - Visible Frame: \(screen.visibleFrame)")
            }
            print("Pantalla actual: \(selectedScreen)")
            print("Posición actual: \(settings.position)")
        }
    }
    
    private enum Position {
        case topLeft, topRight, center, bottomLeft, bottomRight
    }
    
    private func moveToScreen(_ screen: NSScreen) {
        if let window = NSApplication.shared.windows.first {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            
            // Calcular nueva posición manteniendo la posición relativa
            let currentScreen = selectedScreen
            let currentFrame = currentScreen.visibleFrame
            let relativeX = (settings.position.x - currentFrame.minX) / currentFrame.width
            let relativeY = (settings.position.y - currentFrame.minY) / currentFrame.height
            
            let newX = screenFrame.minX + (screenFrame.width * relativeX)
            let newY = screenFrame.minY + (screenFrame.height * relativeY)
            
            // Actualizar posición
            settings.position = CGPoint(x: newX, y: newY)
            
            // Mover la ventana
            window.setFrame(NSRect(
                x: newX - windowSize.width/2,
                y: newY - windowSize.height/2,
                width: windowSize.width,
                height: windowSize.height
            ), display: true)
        }
    }
    
    private func moveToPosition(_ position: Position) {
        let screenFrame = selectedScreen.visibleFrame
        let padding: CGFloat = 20
        
        switch position {
        case .topLeft:
            settings.position = CGPoint(x: screenFrame.minX + padding, y: screenFrame.maxY - padding)
        case .topRight:
            settings.position = CGPoint(x: screenFrame.maxX - padding, y: screenFrame.maxY - padding)
        case .center:
            settings.position = CGPoint(x: screenFrame.midX, y: screenFrame.midY)
        case .bottomLeft:
            settings.position = CGPoint(x: screenFrame.minX + padding, y: screenFrame.minY + padding)
        case .bottomRight:
            settings.position = CGPoint(x: screenFrame.maxX - padding, y: screenFrame.minY + padding)
        }
    }
    
    private func adjustPosition(dx: CGFloat, dy: CGFloat) {
        let screenFrame = selectedScreen.visibleFrame
        let padding: CGFloat = 20
        let newX = settings.position.x + dx
        let newY = settings.position.y + dy
        
        // Mantener dentro de los límites de la pantalla
        settings.position = CGPoint(
            x: min(max(newX, screenFrame.minX + padding), screenFrame.maxX - padding),
            y: min(max(newY, screenFrame.minY + padding), screenFrame.maxY - padding)
        )
    }
}

struct PreviewView: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            
            if settings.orientation == .vertical {
                VStack(spacing: settings.spacing) {
                    previewKeys
                }
            } else {
                HStack(spacing: settings.spacing) {
                    previewKeys
                }
            }
        }
        .cornerRadius(8)
    }
    
    var previewKeys: some View {
        ForEach(0..<min(3, settings.maxVisibleKeys), id: \.self) { i in
            KeyPressView(
                keyPress: KeyPress(key: "Tecla \(i + 1)"),
                settings: settings
            )
        }
    }
}

#Preview {
    ContentView(settings: Settings())
}
