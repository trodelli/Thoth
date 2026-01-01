//
//  URLValidator.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

struct URLValidator {
    static func validate(_ urlString: String) throws -> URL {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard let url = URL(string: trimmed) else {
            throw ValidationError.invalidURL(trimmed)
        }
        
        return try validate(url)
    }
    
    static func validate(_ url: URL) throws -> URL {
        guard let host = url.host,
              host.contains("wikipedia.org") else {
            throw ValidationError.notWikipedia(url)
        }
        
        guard url.pathComponents.count >= 3,
              url.pathComponents[1] == "wiki" else {
            throw ValidationError.missingWikiPath(url)
        }
        
        return url
    }
    
    static func extractArticleTitle(from url: URL) -> String? {
        guard url.pathComponents.count >= 3,
              url.pathComponents[1] == "wiki" else {
            return nil
        }
        
        let title = url.pathComponents[2]
        return title.removingPercentEncoding ?? title
    }
    
    static func parseURLs(_ input: String) -> (valid: [URL], invalid: [String]) {
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var valid: [URL] = []
        var invalid: [String] = []
        
        for line in lines {
            do {
                let url = try validate(line)
                if !valid.contains(url) { // Prevent duplicates
                    valid.append(url)
                }
            } catch {
                invalid.append(line)
            }
        }
        
        return (valid, invalid)
    }
    
    // MARK: - URL Auto-Detection & Normalization

    /// Auto-detect and normalize Wikipedia URLs or article titles
    static func normalizeInput(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Already a full URL
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return normalizeWikipediaURL(trimmed)
        }
        
        // Wikipedia URL without protocol
        if trimmed.hasPrefix("en.wikipedia.org") || trimmed.hasPrefix("wikipedia.org") {
            return normalizeWikipediaURL("https://\(trimmed)")
        }
        
        // Article title - convert to URL
        if !trimmed.isEmpty && !trimmed.contains("/") {
            return buildWikipediaURL(from: trimmed)
        }
        
        return nil
    }

    /// Normalize Wikipedia URLs (handle mobile, different formats)
    private static func normalizeWikipediaURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Convert mobile URLs to desktop
        if components?.host == "en.m.wikipedia.org" {
            components?.host = "en.wikipedia.org"
        }
        
        // Ensure proper path format
        if let path = components?.path, path.hasPrefix("/wiki/") {
            return components?.url?.absoluteString
        }
        
        return nil
    }

    /// Build Wikipedia URL from article title
    private static func buildWikipediaURL(from title: String) -> String {
        // Replace spaces with underscores
        let formatted = title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        
        return "https://en.wikipedia.org/wiki/\(formatted)"
    }

    /// Auto-detect and parse multiple inputs (mix of URLs and titles)
    static func parseFlexibleInput(_ input: String) -> [URL] {
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var urls: [URL] = []
        
        for line in lines {
            if let normalized = normalizeInput(line),
               let url = URL(string: normalized),
               let validURL = try? validate(url) {
                urls.append(validURL)
            }
        }
        
        return urls
    }
    
}
