//
//  KeyPressDisplayApp.swift
//  KeyPressDisplay
//
//  Created by Ignacio Palacio  on 5/1/25.
//

import SwiftUI

extension NSWindow {
    func hideStandardButtons() {
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
}

@main
struct KeyPressDisplayApp: App {
    @StateObject private var settings = Settings()
    
    init() {
        // Solo logging de pantallas en init
        print("\n=== Información de Pantallas ===")
        print("Número total de pantallas: \(NSScreen.screens.count)")
        
        NSScreen.screens.enumerated().forEach { index, screen in
            print("\nPantalla \(index + 1):")
            print("  Frame completo:")
            print("    - Origen: (\(Int(screen.frame.origin.x)), \(Int(screen.frame.origin.y)))")
            print("    - Tamaño: \(Int(screen.frame.width)) x \(Int(screen.frame.height))")
            print("  Frame visible (sin Dock/MenuBar):")
            print("    - Origen: (\(Int(screen.visibleFrame.origin.x)), \(Int(screen.visibleFrame.origin.y)))")
            print("    - Tamaño: \(Int(screen.visibleFrame.width)) x \(Int(screen.visibleFrame.height))")
            
            if screen == NSScreen.main {
                print("  *** Esta es la pantalla principal ***")
            }
            
            // Información adicional de la pantalla
            print("  Nombre: \(screen.localizedName)")
            print("  Escala: \(screen.backingScaleFactor)x")
            
            if let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                print("  Display ID: \(displayID)")
                let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
                print("  Tipo: \(isBuiltIn ? "Integrada" : "Externa")")
                
                // Información adicional sobre la posición relativa
                let position: String
                if screen.frame.origin.x < 0 {
                    position = "A la izquierda de la pantalla principal"
                } else if screen.frame.origin.x > 0 {
                    position = "A la derecha de la pantalla principal"
                } else {
                    position = "Alineada con la pantalla principal"
                }
                print("  Posición: \(position)")
            }
        }
        print("\n=========================")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
                .background(.clear)
                .onAppear {
                    // Mover la inicialización de la posición aquí
                    if let screen = NSScreen.main {
                        let screenFrame = screen.visibleFrame
                        if settings.position == .zero {  // Solo si no hay posición guardada
                            settings.position = CGPoint(
                                x: screenFrame.maxX - 250,
                                y: screenFrame.minY + 100
                            )
                        }
                    }
                    configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 200, height: 100)
    }
    
    private func configureWindow() {
        if let window = NSApplication.shared.windows.first {
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.hasShadow = false
            window.isMovableByWindowBackground = true
            
            // Inicialmente ignorar eventos del mouse
            window.ignoresMouseEvents = true
            
            window.hideStandardButtons()
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            
            // Posicionar la ventana
            moveWindowToPosition(window: window, position: settings.position)
            
            // Observar cambios en la posición
            NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { _ in
                if window.isMoving {  // Solo actualizar si está siendo arrastrada
                    let newPosition = CGPoint(
                        x: window.frame.origin.x + window.frame.width/2,
                        y: window.frame.origin.y + window.frame.height/2
                    )
                    settings.position = newPosition
                    
                    // Guardar la pantalla actual
                    if let currentScreen = window.screen {
                        UserDefaults.standard.set(currentScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0, forKey: "lastScreenID")
                    }
                }
            }
            
            // Restaurar la última pantalla conocida
            if let lastScreenID = UserDefaults.standard.object(forKey: "lastScreenID") as? CGDirectDisplayID,
               let lastScreen = NSScreen.screens.first(where: { screen in
                   screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == lastScreenID
               }) {
                moveWindowToScreen(window: window, screen: lastScreen)
            }
        }
    }
    
    private func moveWindowToPosition(window: NSWindow, position: CGPoint) {
        window.setFrame(NSRect(
            x: position.x - 100,
            y: position.y - 50,
            width: 200,
            height: 100
        ), display: true)
    }
    
    private func moveWindowToScreen(window: NSWindow, screen: NSScreen) {
        let screenFrame = screen.visibleFrame
        let currentPosition = settings.position
        
        // Mantener la posición relativa en la nueva pantalla
        let currentScreen = window.screen ?? NSScreen.main ?? screen
        let relativeX = (currentPosition.x - currentScreen.visibleFrame.minX) / currentScreen.visibleFrame.width
        let relativeY = (currentPosition.y - currentScreen.visibleFrame.minY) / currentScreen.visibleFrame.height
        
        let newPosition = CGPoint(
            x: screenFrame.minX + (screenFrame.width * relativeX),
            y: screenFrame.minY + (screenFrame.height * relativeY)
        )
        
        settings.position = newPosition
        moveWindowToPosition(window: window, position: newPosition)
    }
}

// Extensión para NSWindow para detectar si está siendo arrastrada
private extension NSWindow {
    var isMoving: Bool {
        return NSEvent.modifierFlags.contains(.command)
    }
}
