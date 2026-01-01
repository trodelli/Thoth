//
//  Logger.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation
import Combine

enum LogLevel: String, CaseIterable {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
    
    var icon: String {
        switch self {
        case .info: return "ℹ️"
        case .success: return "✅"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

struct LogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String
    let details: String?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        details: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.details = details
    }
}

class Logger: ObservableObject {
    static let shared = Logger()
    
    @Published var entries: [LogEntry] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private let queue = DispatchQueue(label: "com.theway.thoth.logger", qos: .utility)
    
    private init() {}
    
    func log(_ level: LogLevel, _ message: String, details: String? = nil) {
        let entry = LogEntry(level: level, message: message, details: details)
        
        // Use queue to safely update published property
        queue.async { [weak self] in
            DispatchQueue.main.async {
                self?.entries.append(entry)
            }
        }
        
        // Also print to console during development
        #if DEBUG
        let timestamp = dateFormatter.string(from: entry.timestamp)
        print("[\(timestamp)] \(level.icon) \(message)")
        if let details = details {
            print("    Details: \(details)")
        }
        #endif
    }
    
    func info(_ message: String, details: String? = nil) {
        log(.info, message, details: details)
    }
    
    func success(_ message: String, details: String? = nil) {
        log(.success, message, details: details)
    }
    
    func warning(_ message: String, details: String? = nil) {
        log(.warning, message, details: details)
    }
    
    func error(_ message: String, details: String? = nil) {
        log(.error, message, details: details)
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.entries.removeAll()
        }
    }
    
    func entries(for levels: Set<LogLevel>) -> [LogEntry] {
        entries.filter { levels.contains($0.level) }
    }
}
