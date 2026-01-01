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
        panel.allowedContentTypes = [.plainText, .text]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                self.urlInput = content
            } catch {
                Logger.shared.error("Failed to read file", details: error.localizedDescription)
            }
        }
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
    
    func clear() {
        urlInput = ""
        validURLs = []
        invalidURLs = []
        currentExtractionIndex = 0
    }
}
