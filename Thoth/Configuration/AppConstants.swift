//
//  AppConstants.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum AppConstants {
    static let appName = "Thoth"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    static let creatorName = "theway.ink"
    static let creatorURL = URL(string: "https://theway.ink")!
    static let copyright = "© 2025 theway.ink. All rights reserved."
    
    enum Wikipedia {
        static let baseURL = "https://en.wikipedia.org/w/api.php"
        static let userAgent = "Thoth/1.0 (Wikipedia Extraction Tool; theway.ink)"
        static let defaultDelay: TimeInterval = 1.0
    }
    
    enum Claude {
        static let baseURL = "https://api.anthropic.com/v1/messages"
        static let apiVersion = "2023-06-01"
        static let model = "claude-sonnet-4-20250514"
        static let maxTokens = 4096 // For general use
        static let summaryMaxTokens = 1600 // CHANGED: Allow longer summaries
        static let timeout: TimeInterval = 240.0 // 4 minutes
    }
    
    enum Defaults {
        static let summaryRatio: Double = 0.5  // Default 50%
        static let minSummaryRatio: Double = 0.4  // Min 40%
        static let maxSummaryRatio: Double = 0.7  // Max 70% (was 0.8)
        static let maxBatchSize = 200
        static let maxTableRows = 500
        static let requestDelay: TimeInterval = 1.0
        
        // NEW: Recent articles
        static let maxRecentArticles: Int = 5
        
        // NEW: Retry settings
        static let maxRetries: Int = 3
        static let retryDelay: TimeInterval = 2.0
    }
    
    enum Storage {
        static let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("Thoth")
        static let recoveryFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".thoth/session_recovery.json")
    }
}
