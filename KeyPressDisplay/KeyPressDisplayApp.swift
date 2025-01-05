//
//  KeyPressDisplayApp.swift
//  KeyPressDisplay
//
//  Created by Ignacio Palacio  on 5/1/25.
//

import SwiftUI

@main
struct KeyPressDisplayApp: App {
    @StateObject private var settings = Settings()
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
                .background(.clear)
                .onAppear {
                    configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 200, height: 100)
    }
    
    private func configureWindow() {
        if let window = NSApplication.shared.windows.first {
            // Configuración básica de la ventana
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.hasShadow = false
            window.isMovableByWindowBackground = true  // Permitir arrastrar
            
            // Ocultar botones de la ventana
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // Posicionar en la esquina inferior derecha
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                window.setFrame(NSRect(
                    x: screenFrame.maxX - 250,
                    y: screenFrame.minY + 50,
                    width: 200,
                    height: 100
                ), display: true)
            }
        }
    }
}
