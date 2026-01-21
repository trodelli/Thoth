//
//  InputViewModel.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class InputViewModel: ObservableObject {
    @Published var urlInput: String = ""
    @Published var validURLs: [URL] = []
    @Published var invalidURLs: [String] = []
    @Published var isExtracting = false
    @Published var currentExtractionIndex = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $urlInput
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateURLs()
            }
            .store(in: &cancellables)
    }
    
    private func validateURLs() {
        // Try the newer parseURLs method first
        let result = URLValidator.parseURLs(urlInput)
        validURLs = result.valid
        invalidURLs = result.invalid
    }
    
    func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text, .json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                
                // Check if it's a JSON file from search export
                if url.pathExtension.lowercased() == "json" {
                    self.importFromJSON(content)
                } else {
                    // Handle plain text, markdown, or txt files
                    self.importFromText(content)
                }
            } catch {
                Logger.shared.error("Failed to read file", details: error.localizedDescription)
            }
        }
    }
    
    /// Import URLs from plain text or markdown content
    private func importFromText(_ content: String) {
        // Extract URLs from the content (handles both plain URLs and markdown links)
        var extractedURLs: [String] = []
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comment lines and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Check for markdown links: [title](url)
            if let markdownMatch = trimmed.range(of: #"\[.*?\]\((https?://[^\)]+)\)"#, options: .regularExpression) {
                let urlRange = trimmed.range(of: #"https?://[^\)]+"#, options: .regularExpression, range: markdownMatch)
                if let urlRange = urlRange {
                    extractedURLs.append(String(trimmed[urlRange]))
                }
            }
            // Check for plain URLs
            else if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                // Extract just the URL (in case there's trailing content)
                if let urlEnd = trimmed.firstIndex(of: " ") {
                    extractedURLs.append(String(trimmed[..<urlEnd]))
                } else {
                    extractedURLs.append(trimmed)
                }
            }
            // Check for Wikipedia article titles (no URL prefix)
            else if !trimmed.contains("://") && !trimmed.isEmpty {
                // Could be an article title - let URLValidator handle it
                extractedURLs.append(trimmed)
            }
        }
        
        // Add extracted URLs to input
        if !extractedURLs.isEmpty {
            addURLs(extractedURLs)
            Logger.shared.success("Imported \(extractedURLs.count) URLs from file")
        } else {
            // Fall back to raw content
            urlInput = content
        }
    }
    
    /// Import URLs from JSON export format
    private func importFromJSON(_ content: String) {
        guard let data = content.data(using: .utf8) else {
            urlInput = content
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let articles = json["articles"] as? [[String: Any]] {
                
                var urls: [String] = []
                for article in articles {
                    if let url = article["url"] as? String {
                        urls.append(url)
                    }
                }
                
                if !urls.isEmpty {
                    addURLs(urls)
                    Logger.shared.success("Imported \(urls.count) URLs from JSON")
                    return
                }
            }
        } catch {
            Logger.shared.warning("Could not parse as JSON, treating as plain text")
        }
        
        // Fall back to text import
        importFromText(content)
    }
    
    func setInput(_ text: String) {
        urlInput = text
    }
    
    func addRecentURL(_ url: URL) {
        // Add URL to input if not already present
        let urlString = url.absoluteString
        if !urlInput.contains(urlString) {
            if !urlInput.isEmpty && !urlInput.hasSuffix("\n") {
                urlInput += "\n"
            }
            urlInput += urlString
        }
    }
    
    /// Add multiple URLs to the input (from search results)
    func addURLs(_ urls: [URL]) {
        addURLs(urls.map { $0.absoluteString })
    }
    
    /// Add multiple URL strings to the input
    func addURLs(_ urlStrings: [String]) {
        // Filter out URLs already in input
        let existingURLs = Set(urlInput.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
        
        let newURLs = urlStrings.filter { url in
            !existingURLs.contains(url.lowercased())
        }
        
        guard !newURLs.isEmpty else {
            Logger.shared.info("All URLs already in input")
            return
        }
        
        // Append new URLs
        var newInput = urlInput
        if !newInput.isEmpty && !newInput.hasSuffix("\n") {
            newInput += "\n"
        }
        newInput += newURLs.joined(separator: "\n")
        
        urlInput = newInput
        
        Logger.shared.success("Added \(newURLs.count) URLs to extraction queue")
    }
    
    func clear() {
        urlInput = ""
        validURLs = []
        invalidURLs = []
        currentExtractionIndex = 0
    }
}
