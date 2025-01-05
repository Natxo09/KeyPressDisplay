import SwiftUI
import AppKit

class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var settingsWindow: NSWindow?
    
    private init() {}
    
    func showSettings(settings: Settings) {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "Preferencias"
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
            
            let hostingView = NSHostingView(
                rootView: SettingsView(settings: settings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            settingsWindow?.contentView = hostingView
            
            print("Ventana de configuración creada")
        }
        
        if let window = settingsWindow {
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
                print("Ventana de configuración mostrada")
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func closeSettings() {
        settingsWindow?.close()
    }
} 