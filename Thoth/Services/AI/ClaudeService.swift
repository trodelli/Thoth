//
//  ClaudeService.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

class ClaudeService {
    private let session: URLSession
    private let logger = Logger.shared
    
    init(session: URLSession? = nil) {
        if let session = session {
            self.session = session
        } else {
            // Create custom session with longer timeout
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = AppConstants.Claude.timeout
            configuration.timeoutIntervalForResource = AppConstants.Claude.timeout * 2
            self.session = URLSession(configuration: configuration)
        }
    }
    
    func generateCompletion(
        prompt: String,
        system: String? = nil,
        maxTokens: Int? = nil,
        retryCount: Int = 0
    ) async throws -> String {
        // Get API key
        guard let apiKey = try KeychainManager.shared.retrieve(for: .anthropic) else {
            throw AIError.noAPIKey
        }
        
        // Use provided maxTokens or fall back to default
        let tokenLimit = maxTokens ?? AppConstants.Claude.maxTokens
        
        if retryCount == 0 {
            logger.info("Sending request to Claude API (\(prompt.count) chars, max tokens: \(tokenLimit))")
        } else {
            logger.info("Retry attempt \(retryCount)/\(AppConstants.Defaults.maxRetries)")
        }
        
        // Build request
        let request = ClaudeRequest(
            model: AppConstants.Claude.model,
            maxTokens: tokenLimit,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ],
            system: system
        )
        
        // Create URL request
        guard let url = URL(string: AppConstants.Claude.baseURL) else {
            throw AIError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(AppConstants.Claude.apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.timeoutInterval = AppConstants.Claude.timeout
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        logger.info("Request size: \(urlRequest.httpBody?.count ?? 0) bytes")
        
        do {
            // Make request
            let startTime = Date()
            let (data, response) = try await session.data(for: urlRequest)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            logger.info("Claude API response: \(httpResponse.statusCode) (took \(String(format: "%.1f", duration))s)")
            
            // Handle response
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
                
                logger.info("Tokens used: \(claudeResponse.usage.inputTokens) in, \(claudeResponse.usage.outputTokens) out")
                
                guard let firstContent = claudeResponse.content.first else {
                    throw AIError.invalidResponse
                }
                
                return firstContent.text
                
            case 401:
                throw AIError.invalidAPIKey
                
            case 429:
                // Rate limited - retry with backoff
                if retryCount < AppConstants.Defaults.maxRetries {
                    let delay = AppConstants.Defaults.retryDelay * Double(retryCount + 1)
                    logger.warning("Rate limited, retrying in \(Int(delay))s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await generateCompletion(
                        prompt: prompt,
                        system: system,
                        maxTokens: maxTokens,
                        retryCount: retryCount + 1
                    )
                } else {
                    throw AIError.rateLimited
                }
                
            case 500...599:
                // Server error - retry
                if retryCount < AppConstants.Defaults.maxRetries {
                    let delay = AppConstants.Defaults.retryDelay * Double(retryCount + 1)
                    logger.warning("Server error, retrying in \(Int(delay))s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await generateCompletion(
                        prompt: prompt,
                        system: system,
                        maxTokens: maxTokens,
                        retryCount: retryCount + 1
                    )
                } else {
                    throw AIError.serverError
                }
                
            default:
                // Try to get error message from response
                let decoder = JSONDecoder()
                if let errorData = try? decoder.decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    logger.error("API error: \(errorMessage)")
                }
                throw AIError.unexpectedError(httpResponse.statusCode)
            }
            
        } catch let error as AIError {
            // Already an AIError, rethrow
            throw error
            
        } catch {
            // Network or other error - retry if possible
            if retryCount < AppConstants.Defaults.maxRetries {
                let delay = AppConstants.Defaults.retryDelay * Double(retryCount + 1)
                logger.warning("Network error, retrying in \(Int(delay))s...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await generateCompletion(
                    prompt: prompt,
                    system: system,
                    maxTokens: maxTokens,
                    retryCount: retryCount + 1
                )
            } else {
                logger.error("Request failed after \(retryCount) retries: \(error.localizedDescription)")
                throw error
            }
        }
    }
}
