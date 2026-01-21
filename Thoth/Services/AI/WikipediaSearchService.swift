//
//  WikipediaSearchService.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

/// Result from a search operation including cost data
struct SearchOperationResult {
    let results: [SearchResult]
    let estimatedTotal: Int
    let inputTokens: Int
    let outputTokens: Int
}

/// Service for AI-powered Wikipedia article discovery
class WikipediaSearchService {
    private let claudeService = ClaudeService()
    private let wikipediaService = WikipediaService()
    private let logger = Logger.shared
    
    // Batch size of 50 to avoid token limit truncation
    private let batchSize = 50
    
    // Max tokens for search responses
    private let searchMaxTokens = 8192
    
    /// Callback for progress updates
    var onProgressUpdate: ((SearchStep, String) -> Void)?
    
    // MARK: - Debug Logging (Direct to Console)
    
    private func debugLog(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("🔍 [SEARCH \(timestamp)] \(message)")
    }
    
    /// Perform initial search to estimate total results and get first batch
    func performInitialSearch(query: String) async throws -> SearchOperationResult {
        debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        debugLog("SEARCH START: \"\(query)\"")
        debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        debugLog("📋 Batch size: \(batchSize), Max tokens: \(searchMaxTokens)")
        
        // Step 1: Prepare the prompt
        await updateProgress(.preparingQuery, "Building search prompt...")
        let estimationPrompt = buildEstimationPrompt(query: query)
        debugLog("📝 Prompt length: \(estimationPrompt.count) characters")
        debugLog("📝 System prompt length: \(searchSystemPrompt.count) characters")
        
        // Step 2: Call Claude API with usage tracking
        await updateProgress(.contactingClaude, "Waiting for Claude response...")
        debugLog("🤖 Sending request to Claude API...")
        let startTime = Date()
        
        let completionResult: ClaudeCompletionResult
        do {
            completionResult = try await claudeService.generateCompletionWithUsage(
                prompt: estimationPrompt,
                system: searchSystemPrompt,
                maxTokens: searchMaxTokens
            )
            let elapsed = Date().timeIntervalSince(startTime)
            debugLog("✅ Claude responded in \(String(format: "%.1f", elapsed))s")
            debugLog("📄 Response length: \(completionResult.text.count) characters")
            debugLog("💰 Tokens: \(completionResult.inputTokens) in, \(completionResult.outputTokens) out")
            
            // Log first 500 chars of response for debugging
            let previewLength = min(500, completionResult.text.count)
            let preview = String(completionResult.text.prefix(previewLength))
            debugLog("📄 Response preview: \(preview)...")
            
        } catch {
            debugLog("❌ Claude API FAILED: \(error)")
            debugLog("❌ Error type: \(type(of: error))")
            debugLog("❌ Localized: \(error.localizedDescription)")
            logger.error("Claude API failed", details: error.localizedDescription)
            throw error
        }
        
        // Step 3: Parse the response
        await updateProgress(.parsingResponse, "Extracting article data...")
        debugLog("🔧 Parsing Claude response...")
        let parsed = parseSearchResponse(completionResult.text)
        
        debugLog("📊 Parse results:")
        debugLog("   • Estimated total: \(parsed.estimatedTotal)")
        debugLog("   • Articles found: \(parsed.articles.count)")
        debugLog("   • Has more: \(parsed.hasMore)")
        
        if parsed.articles.isEmpty {
            debugLog("⚠️ WARNING: No articles parsed from response!")
            debugLog("⚠️ This may indicate JSON truncation or parsing failure")
        } else {
            let sampleTitles = parsed.articles.prefix(5).map { $0.title }
            debugLog("📚 Sample articles: \(sampleTitles.joined(separator: ", "))")
        }
        
        // Step 4: Validate articles exist via Wikipedia API
        await updateProgress(.validatingArticles, "Checking \(parsed.articles.count) articles against Wikipedia...")
        debugLog("🔍 Validating \(parsed.articles.count) articles against Wikipedia API...")
        
        let validatedResults = await validateArticles(parsed.articles)
        
        debugLog("✅ Validation complete: \(validatedResults.count) valid articles")
        
        if validatedResults.isEmpty && !parsed.articles.isEmpty {
            debugLog("⚠️ WARNING: All articles failed validation! Sample failed titles:")
            for article in parsed.articles.prefix(5) {
                debugLog("   • \(article.title)")
            }
        }
        
        await updateProgress(.complete, "Found \(validatedResults.count) articles")
        
        debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        debugLog("SEARCH COMPLETE: \(validatedResults.count) validated articles")
        debugLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return SearchOperationResult(
            results: validatedResults,
            estimatedTotal: parsed.estimatedTotal,
            inputTokens: completionResult.inputTokens,
            outputTokens: completionResult.outputTokens
        )
    }
    
    /// Continue search to load more results
    func continueSearch(query: String, alreadyLoaded: [String], batchNumber: Int) async throws -> SearchOperationResult {
        debugLog("📥 Loading batch \(batchNumber + 1) for: \"\(query)\"")
        debugLog("   Already loaded: \(alreadyLoaded.count) articles")
        
        await updateProgress(.preparingQuery, "Preparing continuation request...")
        let continuationPrompt = buildContinuationPrompt(
            query: query,
            alreadyLoaded: alreadyLoaded,
            batchNumber: batchNumber
        )
        
        await updateProgress(.contactingClaude, "Requesting more articles from Claude...")
        let completionResult = try await claudeService.generateCompletionWithUsage(
            prompt: continuationPrompt,
            system: searchSystemPrompt,
            maxTokens: searchMaxTokens
        )
        
        debugLog("💰 Tokens: \(completionResult.inputTokens) in, \(completionResult.outputTokens) out")
        
        await updateProgress(.parsingResponse, "Processing response...")
        let parsed = parseSearchResponse(completionResult.text)
        debugLog("📊 Continuation parse: \(parsed.articles.count) articles")
        
        // Validate articles
        await updateProgress(.validatingArticles, "Validating \(parsed.articles.count) articles...")
        let validatedResults = await validateArticles(parsed.articles)
        
        await updateProgress(.complete, "Loaded \(validatedResults.count) more articles")
        debugLog("✅ Loaded \(validatedResults.count) more articles")
        
        return SearchOperationResult(
            results: validatedResults,
            estimatedTotal: 0, // Not relevant for continuation
            inputTokens: completionResult.inputTokens,
            outputTokens: completionResult.outputTokens
        )
    }
    
    @MainActor
    private func updateProgress(_ step: SearchStep, _ message: String) {
        debugLog("📍 Step: \(step.rawValue) - \(message)")
        onProgressUpdate?(step, message)
    }
    
    /// Validate that articles exist on Wikipedia
    private func validateArticles(_ articles: [(title: String, description: String)]) async -> [SearchResult] {
        var validResults: [SearchResult] = []
        var validCount = 0
        var invalidCount = 0
        
        let validationBatchSize = 20
        
        debugLog("🔍 Starting validation of \(articles.count) articles in batches of \(validationBatchSize)")
        
        for (batchIndex, batch) in articles.chunked(into: validationBatchSize).enumerated() {
            debugLog("   Validating batch \(batchIndex + 1)...")
            
            await withTaskGroup(of: (SearchResult?, Bool).self) { group in
                for article in batch {
                    group.addTask {
                        let exists = await self.articleExists(title: article.title)
                        if exists {
                            let result = SearchResult.fromTitle(article.title, description: article.description)
                            return (result, true)
                        }
                        return (nil, false)
                    }
                }
                
                for await (result, exists) in group {
                    if exists {
                        validCount += 1
                        if let result = result {
                            validResults.append(result)
                        }
                    } else {
                        invalidCount += 1
                    }
                }
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        debugLog("📊 Validation summary: \(validCount) valid, \(invalidCount) invalid")
        
        return validResults
    }
    
    /// Check if a Wikipedia article exists
    private func articleExists(title: String) async -> Bool {
        let encodedTitle = title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        
        let urlString = "\(AppConstants.Wikipedia.baseURL)?action=query&titles=\(encodedTitle)&format=json&formatversion=2"
        
        guard let url = URL(string: urlString) else {
            debugLog("   ⚠️ Invalid URL for title: \(title)")
            return false
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue(AppConstants.Wikipedia.userAgent, forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    return false
                }
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let query = json["query"] as? [String: Any],
               let pages = query["pages"] as? [[String: Any]] {
                if let firstPage = pages.first {
                    if firstPage["missing"] != nil {
                        return false
                    }
                    return true
                }
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let query = json["query"] as? [String: Any],
               let pages = query["pages"] as? [String: Any] {
                if pages.keys.contains("-1") {
                    return false
                }
                return !pages.isEmpty
            }
            
        } catch {
            return true
        }
        
        return false
    }
    
    // MARK: - Prompt Building
    
    private var searchSystemPrompt: String {
        """
        You are a Wikipedia research assistant. Your task is to identify Wikipedia articles that match a user's search query.
        
        Guidelines:
        - Focus on English Wikipedia articles only
        - Include both directly relevant articles and related topics
        - Provide accurate Wikipedia article titles (case-sensitive for first letter)
        - Give VERY brief descriptions (under 50 characters)
        - Article titles must match exactly how they appear on Wikipedia
        - Do NOT include disambiguation pages
        
        CRITICAL RULES:
        1. Respond with valid JSON only - no markdown, no code blocks
        2. Keep descriptions SHORT (under 50 chars) to avoid response truncation
        3. Complete the JSON structure - always close all brackets
        """
    }
    
    private func buildEstimationPrompt(query: String) -> String {
        """
        Search query: "\(query)"
        
        Task:
        1. Estimate total relevant Wikipedia articles for this query
        2. Return the first \(batchSize) most relevant article titles with SHORT descriptions
        
        IMPORTANT: Keep descriptions under 50 characters to avoid truncation!
        
        Respond with this exact JSON (no markdown):
        {"estimatedTotal": <number>, "reasoning": "<brief>", "articles": [{"title": "<Wikipedia title>", "description": "<under 50 chars>"}]}
        
        Example:
        {"estimatedTotal": 500, "reasoning": "Broad historical topic", "articles": [{"title": "Ancient Rome", "description": "Roman civilization 8th c BC-5th c AD"}]}
        
        Generate exactly \(batchSize) articles. Ensure valid JSON with all brackets closed.
        """
    }
    
    private func buildContinuationPrompt(query: String, alreadyLoaded: [String], batchNumber: Int) -> String {
        let loadedList = alreadyLoaded.prefix(50).joined(separator: ", ")
        
        return """
        Search query: "\(query)"
        Batch \(batchNumber + 1). Already provided (don't repeat): \(loadedList)...
        
        Return \(batchSize) MORE relevant Wikipedia articles with SHORT descriptions (under 50 chars).
        
        JSON format (no markdown):
        {"articles": [{"title": "<title>", "description": "<under 50 chars>"}], "hasMore": true/false}
        
        Ensure valid JSON with all brackets closed.
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseSearchResponse(_ response: String) -> (articles: [(title: String, description: String)], estimatedTotal: Int, hasMore: Bool) {
        debugLog("🔧 Parsing response...")
        
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = String(cleanedResponse.dropFirst(7))
        } else if cleanedResponse.hasPrefix("```") {
            cleanedResponse = String(cleanedResponse.dropFirst(3))
        }
        
        if cleanedResponse.hasSuffix("```") {
            cleanedResponse = String(cleanedResponse.dropLast(3))
        }
        
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        debugLog("🔧 Cleaned response length: \(cleanedResponse.count)")
        
        guard let jsonStart = cleanedResponse.firstIndex(of: "{") else {
            debugLog("❌ No JSON object found in response")
            return ([], 0, false)
        }
        
        let lastChar = cleanedResponse.last
        let jsonComplete = lastChar == "}" || lastChar == "]"
        
        if !jsonComplete {
            debugLog("⚠️ JSON appears truncated, attempting recovery...")
            cleanedResponse = attemptJSONRecovery(cleanedResponse)
        }
        
        if let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
            debugLog("🔧 Extracted JSON object, length: \(cleanedResponse.count)")
        }
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            debugLog("❌ Could not convert response to UTF-8 data")
            return ([], 0, false)
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                debugLog("✅ Successfully parsed JSON")
                debugLog("   Keys found: \(json.keys.joined(separator: ", "))")
                
                let estimatedTotal = json["estimatedTotal"] as? Int ?? 0
                let hasMore = json["hasMore"] as? Bool ?? (estimatedTotal > 0)
                
                if let reasoning = json["reasoning"] as? String {
                    debugLog("   Reasoning: \(reasoning)")
                }
                
                var articles: [(title: String, description: String)] = []
                
                if let articlesArray = json["articles"] as? [[String: Any]] {
                    debugLog("   Articles array count: \(articlesArray.count)")
                    
                    for (index, article) in articlesArray.enumerated() {
                        if let title = article["title"] as? String, !title.isEmpty {
                            let description = article["description"] as? String ?? ""
                            articles.append((title: title, description: description))
                            
                            if index < 3 {
                                debugLog("   Article \(index + 1): \(title)")
                            }
                        }
                    }
                } else {
                    debugLog("⚠️ No 'articles' array found in JSON")
                }
                
                return (articles, estimatedTotal, hasMore)
            } else {
                debugLog("❌ JSON is not a dictionary")
            }
        } catch {
            debugLog("❌ JSON parsing error: \(error.localizedDescription)")
            debugLog("❌ Attempting fallback parsing...")
            
            let fallbackArticles = extractArticlesManually(from: cleanedResponse)
            if !fallbackArticles.isEmpty {
                debugLog("✅ Fallback parsing recovered \(fallbackArticles.count) articles")
                return (fallbackArticles, fallbackArticles.count, true)
            }
        }
        
        return ([], 0, false)
    }
    
    private func attemptJSONRecovery(_ json: String) -> String {
        var recovered = json
        
        let openBraces = recovered.filter { $0 == "{" }.count
        let closeBraces = recovered.filter { $0 == "}" }.count
        let openBrackets = recovered.filter { $0 == "[" }.count
        let closeBrackets = recovered.filter { $0 == "]" }.count
        
        debugLog("   Brackets: { \(openBraces)/\(closeBraces) } [ \(openBrackets)/\(closeBrackets) ]")
        
        if let lastCompleteArticle = recovered.range(of: "\"}", options: .backwards) {
            recovered = String(recovered[..<lastCompleteArticle.upperBound])
        }
        
        let remainingBrackets = openBrackets - recovered.filter { $0 == "]" }.count
        let remainingBraces = openBraces - recovered.filter { $0 == "}" }.count
        
        for _ in 0..<remainingBrackets {
            recovered += "]"
        }
        for _ in 0..<remainingBraces {
            recovered += "}"
        }
        
        debugLog("   Recovery added \(remainingBrackets) ] and \(remainingBraces) }")
        
        return recovered
    }
    
    private func extractArticlesManually(from json: String) -> [(title: String, description: String)] {
        var articles: [(title: String, description: String)] = []
        
        let pattern = #"\{"title":\s*"([^"]+)",\s*"description":\s*"([^"]*)"\}"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let range = NSRange(json.startIndex..., in: json)
        let matches = regex.matches(in: json, options: [], range: range)
        
        for match in matches {
            if let titleRange = Range(match.range(at: 1), in: json),
               let descRange = Range(match.range(at: 2), in: json) {
                let title = String(json[titleRange])
                let description = String(json[descRange])
                articles.append((title: title, description: description))
            }
        }
        
        debugLog("   Manual extraction found \(articles.count) articles")
        return articles
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
