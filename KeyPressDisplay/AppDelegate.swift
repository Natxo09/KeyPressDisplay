import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    
    var settingsWindow: NSWindow?
    var settings: Settings?
    
    private override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Posicionar la ventana principal en la esquina inferior derecha
        if let window = NSApplication.shared.windows.first {
            let screenFrame = NSScreen.main?.visibleFrame ?? .zero
            let windowFrame = window.frame
            let newOrigin = NSPoint(
                x: screenFrame.maxX - windowFrame.width - 20,
                y: screenFrame.minY + 20
            )
            window.setFrameOrigin(newOrigin)
        }
    }
    
    @objc func showSettings() {
        guard let settings = settings else { return }
        
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
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
        }
        
        if let window = settingsWindow {
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        settingsWindow?.close()
    }
} 