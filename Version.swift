//
//  Version.swift
//  Thoth
//
//  Created by theway.ink on January 1, 2026.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum AppVersion {
    static let version = "1.0.0"
    static let build = "1"
    static let name = "Thoth"
    static let tagline = "AI-Powered Wikipedia Article Extraction & Summarization"
    static let copyright = "© 2025 theway.ink"
    
    static var fullVersion: String {
        "\(version) (\(build))"
    }
    
    static var displayName: String {
        "\(name) v\(version)"
    }
}
