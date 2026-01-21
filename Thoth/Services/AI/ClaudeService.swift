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
    
    // MARK: - Direct Console Logging
    
    private func debugLog(_ message: String) {
        print("🤖 [CLAUDE] \(message)")
    }
    
    // MARK: - API Key Validation
    
    /// Test if the API key is valid by making a minimal request
    func validateAPIKey() async -> (isValid: Bool, error: String?) {
        debugLog("Testing API key validity...")
        
        guard let apiKey = try? KeychainManager.shared.retrieve(for: .anthropic) else {
            debugLog("No API key found in keychain")
            return (false, "No API key configured")
        }
        
        debugLog("API key found (length: \(apiKey.count) chars)")
        
        // Make a minimal test request
        let testRequest = ClaudeRequest(
            model: AppConstants.Claude.model,
            maxTokens: 10,
            messages: [
                ClaudeMessage(role: "user", content: "Say 'OK'")
            ],
            system: nil
        )
        
        guard let url = URL(string: AppConstants.Claude.baseURL) else {
            return (false, "Invalid API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(AppConstants.Claude.apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.timeoutInterval = 30 // Short timeout for validation
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(testRequest)
            
            debugLog("Sending validation request...")
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Invalid response")
            }
            
            debugLog("Validation response status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                debugLog("✅ API key is valid!")
                return (true, nil)
            case 401:
                debugLog("❌ Invalid API key (401)")
                return (false, "Invalid API key")
            case 403:
                debugLog("❌ Access forbidden (403)")
                return (false, "Access forbidden - check API key permissions")
            case 429:
                debugLog("⚠️ Rate limited but key is valid")
                return (true, nil) // Key is valid, just rate limited
            default:
                if let responseString = String(data: data, encoding: .utf8) {
                    debugLog("Unexpected response: \(responseString)")
                }
                return (false, "Unexpected status code: \(httpResponse.statusCode)")
            }
            
        } catch {
            debugLog("❌ Validation error: \(error.localizedDescription)")
            return (false, error.localizedDescription)
        }
    }
    
    // MARK: - Completion Generation
    
    func generateCompletion(
        prompt: String,
        system: String? = nil,
        maxTokens: Int? = nil,
        retryCount: Int = 0
    ) async throws -> String {
        // Get API key
        guard let apiKey = try KeychainManager.shared.retrieve(for: .anthropic) else {
            debugLog("❌ No API key found!")
            throw AIError.noAPIKey
        }
        
        // Use provided maxTokens or fall back to default
        let tokenLimit = maxTokens ?? AppConstants.Claude.maxTokens
        
        if retryCount == 0 {
            debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            debugLog("Starting API request")
            debugLog("  Prompt length: \(prompt.count) chars")
            debugLog("  System prompt: \(system != nil ? "\(system!.count) chars" : "none")")
            debugLog("  Max tokens: \(tokenLimit)")
            debugLog("  Model: \(AppConstants.Claude.model)")
            debugLog("  Timeout: \(AppConstants.Claude.timeout)s")
            logger.info("Sending request to Claude API (\(prompt.count) chars, max tokens: \(tokenLimit))")
        } else {
            debugLog("Retry attempt \(retryCount)/\(AppConstants.Defaults.maxRetries)")
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
            debugLog("❌ Invalid API URL!")
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
        
        debugLog("Request body size: \(urlRequest.httpBody?.count ?? 0) bytes")
        debugLog("Sending request to: \(url.absoluteString)")
        logger.info("Request size: \(urlRequest.httpBody?.count ?? 0) bytes")
        
        do {
            // Make request
            let startTime = Date()
            debugLog("⏳ Waiting for response...")
            
            let (data, response) = try await session.data(for: urlRequest)
            
            let duration = Date().timeIntervalSince(startTime)
            debugLog("Response received in \(String(format: "%.1f", duration))s")
            debugLog("Response data size: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                debugLog("❌ Response is not HTTPURLResponse!")
                throw AIError.invalidResponse
            }
            
            debugLog("HTTP Status: \(httpResponse.statusCode)")
            logger.info("Claude API response: \(httpResponse.statusCode) (took \(String(format: "%.1f", duration))s)")
            
            // Handle response
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                
                // Try to decode the response
                do {
                    let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
                    
                    debugLog("✅ Successfully decoded response")
                    debugLog("  Input tokens: \(claudeResponse.usage.inputTokens)")
                    debugLog("  Output tokens: \(claudeResponse.usage.outputTokens)")
                    
                    logger.info("Tokens used: \(claudeResponse.usage.inputTokens) in, \(claudeResponse.usage.outputTokens) out")
                    
                    guard let firstContent = claudeResponse.content.first else {
                        debugLog("❌ No content in response!")
                        throw AIError.invalidResponse
                    }
                    
                    debugLog("Response text length: \(firstContent.text.count) chars")
                    debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    return firstContent.text
                    
                } catch {
                    debugLog("❌ Failed to decode response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        debugLog("Raw response: \(responseString.prefix(500))...")
                    }
                    throw AIError.invalidResponse
                }
                
            case 401:
                debugLog("❌ Invalid API key (401)")
                throw AIError.invalidAPIKey
                
            case 429:
                debugLog("⚠️ Rate limited (429)")
                // Rate limited - retry with backoff
                if retryCount < AppConstants.Defaults.maxRetries {
                    let delay = AppConstants.Defaults.retryDelay * Double(retryCount + 1)
                    debugLog("Retrying in \(Int(delay))s...")
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
                debugLog("❌ Server error (\(httpResponse.statusCode))")
                // Server error - retry
                if retryCount < AppConstants.Defaults.maxRetries {
                    let delay = AppConstants.Defaults.retryDelay * Double(retryCount + 1)
                    debugLog("Retrying in \(Int(delay))s...")
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
                debugLog("❌ Unexpected status code: \(httpResponse.statusCode)")
                // Try to get error message from response
                if let responseString = String(data: data, encoding: .utf8) {
                    debugLog("Error response: \(responseString)")
                }
                
                let decoder = JSONDecoder()
                if let errorData = try? decoder.decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    logger.error("API error: \(errorMessage)")
                }
                throw AIError.unexpectedError(httpResponse.statusCode)
            }
            
        } catch let error as AIError {
            debugLog("❌ AIError: \(error)")
            // Already an AIError, rethrow
            throw error
            
        } catch {
            debugLog("❌ Network/Other error: \(error)")
            debugLog("  Error type: \(type(of: error))")
            debugLog("  Description: \(error.localizedDescription)")
            
            // Network or other error - retry if possible
            if retryCount < AppConstants.Defaults.maxRetries {
                let delay = AppConstants.Defaults.retryDelay * Double(retryCount + 1)
                debugLog("Retrying in \(Int(delay))s...")
                logger.warning("Network error, retrying in \(Int(delay))s...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await generateCompletion(
                    prompt: prompt,
                    system: system,
                    maxTokens: maxTokens,
                    retryCount: retryCount + 1
                )
            } else {
                debugLog("❌ Failed after \(retryCount) retries")
                logger.error("Request failed after \(retryCount) retries: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // MARK: - Completion with Token Usage
    
    /// Generate completion and return both text and token usage for cost tracking
    func generateCompletionWithUsage(
        prompt: String,
        system: String? = nil,
        maxTokens: Int? = nil
    ) async throws -> ClaudeCompletionResult {
        // Get API key
        guard let apiKey = try KeychainManager.shared.retrieve(for: .anthropic) else {
            throw AIError.noAPIKey
        }
        
        let tokenLimit = maxTokens ?? AppConstants.Claude.maxTokens
        
        debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        debugLog("Starting API request (with usage tracking)")
        debugLog("  Prompt length: \(prompt.count) chars")
        debugLog("  Max tokens: \(tokenLimit)")
        
        let request = ClaudeRequest(
            model: AppConstants.Claude.model,
            maxTokens: tokenLimit,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ],
            system: system
        )
        
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
        
        let startTime = Date()
        let (data, response) = try await session.data(for: urlRequest)
        let duration = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        debugLog("Response received in \(String(format: "%.1f", duration))s, status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.unexpectedError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
        
        guard let firstContent = claudeResponse.content.first else {
            throw AIError.invalidResponse
        }
        
        debugLog("✅ Tokens: \(claudeResponse.usage.inputTokens) in, \(claudeResponse.usage.outputTokens) out")
        debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return ClaudeCompletionResult(
            text: firstContent.text,
            inputTokens: claudeResponse.usage.inputTokens,
            outputTokens: claudeResponse.usage.outputTokens
        )
    }
}
