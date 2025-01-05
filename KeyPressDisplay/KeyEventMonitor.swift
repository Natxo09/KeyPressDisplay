import AppKit

class KeyEventMonitor {
    static let shared = KeyEventMonitor()
    
    private var monitor: Any?
    private var localMonitor: Any?
    
    // Diccionario para simplificar teclas especiales
    private let specialKeySymbols = [
        "Command": "⌘",
        "Option": "⌥",
        "Control": "⌃",
        "Shift": "⇧",
        "Return": "↵",
        "Delete": "⌫",
        "Escape": "⎋",
        "Space": "␣",
        "Tab": "⇥"
    ]
    
    func startMonitoring(callback: @escaping (String) -> Void) {
        print("Iniciando monitoreo de teclas")
        
        // Monitor local para teclas cuando la app tiene foco
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            print("Evento local detectado: \(event.type)")
            self.handleKeyEvent(event, callback: callback)
            return event
        }
        
        // Monitor global para teclas cuando la app no tiene foco
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            print("Evento global detectado: \(event.type)")
            self.handleKeyEvent(event, callback: callback)
        }
        
        print("Monitores configurados")
    }
    
    private func handleKeyEvent(_ event: NSEvent, callback: @escaping (String) -> Void) {
        var keyString = ""
        let modifiers = event.modifierFlags
        
        // Detectar teclas modificadoras
        if event.type == .flagsChanged {
            if modifiers.contains(.command) { keyString = "⌘" }
            if modifiers.contains(.option) { keyString = "⌥" }
            if modifiers.contains(.control) { keyString = "⌃" }
            if modifiers.contains(.shift) { keyString = "⇧" }
            
            if !keyString.isEmpty {
                DispatchQueue.main.async {
                    callback(keyString)
                }
            }
            return
        }
        
        // Detectar teclas normales
        if let characters = event.charactersIgnoringModifiers {
            // Añadir modificadores
            if modifiers.contains(.command) { keyString += "⌘+" }
            if modifiers.contains(.option) { keyString += "⌥+" }
            if modifiers.contains(.control) { keyString += "⌃+" }
            if modifiers.contains(.shift) { keyString += "⇧+" }
            
            // Manejar teclas especiales
            switch event.keyCode {
            case 36: keyString += "↵"
            case 49: keyString += "␣"
            case 51: keyString += "⌫"
            case 53: keyString += "⎋"
            case 123: keyString += "←"
            case 124: keyString += "→"
            case 125: keyString += "↓"
            case 126: keyString += "↑"
            case 48: keyString += "⇥"
            default:
                // Para teclas normales, respetar mayúsculas/minúsculas según el estado real
                let isShiftPressed = modifiers.contains(.shift)
                let isCapsLockOn = modifiers.contains(.capsLock)
                let shouldBeUppercase = isShiftPressed != isCapsLockOn
                
                keyString += shouldBeUppercase ? characters.uppercased() : characters.lowercased()
            }
            
            print("Tecla normal detectada: \(keyString)")
            DispatchQueue.main.async {
                callback(keyString)
            }
        }
    }
    
    func stopMonitoring() {
        print("Deteniendo monitoreo de teclas")
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
} 