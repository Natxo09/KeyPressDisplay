import Foundation

struct KeyPress: Identifiable {
    let id = UUID()
    let key: String
    let timestamp: Date
    
    init(key: String) {
        self.key = key
        self.timestamp = Date()
    }
} 