//
//  AIEnhancementService.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

class AIEnhancementService {
    private let claudeService = ClaudeService()
    private let logger = Logger.shared
    
    func enhance(parsed: ParsedWikipediaContent, targetRatio: Double) async throws -> AIEnhancementResult {
        logger.info("Starting AI enhancement for: \(parsed.title)")
        
        // Build context from parsed content
        let fullText = buildFullText(from: parsed)
        let targetWordCount = Int(Double(parsed.wordCount) * targetRatio)
        
        // Generate summary
        let summary = try await generateSummary(
            title: parsed.title,
            fullText: fullText,
            targetWordCount: targetWordCount
        )
        
        // NEW: Quality control validation
        let summaryWordCount = summary.split(separator: " ").count
        let actualRatio = Double(summaryWordCount) / Double(parsed.wordCount)
        let targetRatioPercent = Int(targetRatio * 100)
        let actualRatioPercent = Int(actualRatio * 100)

        // Log quality metrics
        logger.info("Summary quality: \(summaryWordCount) words (\(actualRatioPercent)% of original, target was \(targetRatioPercent)%)")

        // Warn if severely under target (less than 30% of target)
        if actualRatio < (targetRatio * 0.3) {
            logger.warning("Summary significantly shorter than target: \(actualRatioPercent)% vs \(targetRatioPercent)% target")
        }
        
        // Classify article type
        let articleType = try await classifyArticle(
            title: parsed.title,
            summary: summary,
            categories: parsed.categories
        )
        
        // Extract key facts
        let keyFacts = try await extractKeyFacts(
            title: parsed.title,
            fullText: fullText,
            infobox: parsed.infobox
        )
        
        // Extract temporal context
        let dates = try await extractDates(
            title: parsed.title,
            fullText: fullText
        )
        
        // Extract geographic context
        let locations = try await extractLocations(
            title: parsed.title,
            fullText: fullText
        )
        
        // Extract related topics
        let relatedTopics = try await extractRelatedTopics(
            title: parsed.title,
            categories: parsed.categories,
            summary: summary
        )
        
        logger.success("AI enhancement complete")
        
        return AIEnhancementResult(
            summary: summary,
            articleType: articleType,
            keyFacts: keyFacts,
            dates: dates,
            locations: locations,
            relatedTopics: relatedTopics
        )
    }
    
    // MARK: - Enhancement with Token Tracking
    
    /// Enhanced version that also returns token usage for cost tracking
    func enhanceWithTokens(
        parsed: ParsedWikipediaContent,
        targetRatio: Double,
        onProgressUpdate: ((ExtractionStep) -> Void)? = nil
    ) async throws -> (result: AIEnhancementResult, tokens: TokenUsage) {
        logger.info("Starting AI enhancement for: \(parsed.title)")
        
        // Build context from parsed content
        let fullText = buildFullText(from: parsed)
        let targetWordCount = Int(Double(parsed.wordCount) * targetRatio)
        
        // Step 1: Generate summary
        onProgressUpdate?(.generatingSummary)
        let summary = try await generateSummary(
            title: parsed.title,
            fullText: fullText,
            targetWordCount: targetWordCount
        )
        
        // Quality control validation
        let summaryWordCount = summary.split(separator: " ").count
        let actualRatio = Double(summaryWordCount) / Double(parsed.wordCount)
        let targetRatioPercent = Int(targetRatio * 100)
        let actualRatioPercent = Int(actualRatio * 100)
        logger.info("Summary quality: \(summaryWordCount) words (\(actualRatioPercent)% of original, target was \(targetRatioPercent)%)")
        
        if actualRatio < (targetRatio * 0.3) {
            logger.warning("Summary significantly shorter than target: \(actualRatioPercent)% vs \(targetRatioPercent)% target")
        }
        
        // Step 2: Classify article type
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay for UI update
        onProgressUpdate?(.classifyingArticle)
        let articleType = try await classifyArticle(
            title: parsed.title,
            summary: summary,
            categories: parsed.categories
        )
        
        // Step 3: Extract key facts
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay for UI update
        onProgressUpdate?(.extractingKeyFacts)
        let keyFacts = try await extractKeyFacts(
            title: parsed.title,
            fullText: fullText,
            infobox: parsed.infobox
        )
        
        // Step 4: Extract temporal context
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay for UI update
        onProgressUpdate?(.extractingDates)
        let dates = try await extractDates(
            title: parsed.title,
            fullText: fullText
        )
        
        // Step 5: Extract geographic context
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay for UI update
        onProgressUpdate?(.extractingLocations)
        let locations = try await extractLocations(
            title: parsed.title,
            fullText: fullText
        )
        
        // Step 6: Extract related topics
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay for UI update
        onProgressUpdate?(.extractingTopics)
        let relatedTopics = try await extractRelatedTopics(
            title: parsed.title,
            categories: parsed.categories,
            summary: summary
        )
        
        logger.success("AI enhancement complete")
        
        let result = AIEnhancementResult(
            summary: summary,
            articleType: articleType,
            keyFacts: keyFacts,
            dates: dates,
            locations: locations,
            relatedTopics: relatedTopics
        )
        
        // Estimate tokens (rough: ~4 chars per token)
        let inputChars = fullText.count
        let outputChars = summary.count
        let estimatedInputTokens = inputChars / 4
        let estimatedOutputTokens = outputChars / 4
        
        let tokens = TokenUsage(
            inputTokens: estimatedInputTokens,
            outputTokens: estimatedOutputTokens
        )
        
        return (result, tokens)
    }
    
    // MARK: - Summary Generation
    
    private func generateSummary(title: String, fullText: String, targetWordCount: Int) async throws -> String {
        // Smart length requirements based on article size
        let minWordCount: Int
        let maxWordCount: Int
        
        // For short articles, use different thresholds
        if targetWordCount < 500 {
            // Short articles: be more lenient
            minWordCount = Int(Double(targetWordCount) * 0.5)  // 50% minimum
            maxWordCount = Int(Double(targetWordCount) * 1.5)  // 150% maximum
        } else {
            // Long articles: enforce 30% minimum quality control
            minWordCount = Int(Double(targetWordCount) * 0.3)  // 30% minimum
            maxWordCount = Int(Double(targetWordCount) * 1.2)  // 120% maximum
        }
        
        let prompt = """
        Create a comprehensive, detailed summary of the Wikipedia article about "\(title)".
        
        CRITICAL LENGTH REQUIREMENTS:
        - Target length: \(targetWordCount) words
        - Minimum acceptable: \(minWordCount) words  
        - Maximum acceptable: \(maxWordCount) words
        - Your summary MUST be between \(minWordCount) and \(maxWordCount) words
        
        CONTENT REQUIREMENTS:
        - Preserve important details, context, and nuance
        - Include key examples and supporting information
        - Maintain academic/scholarly depth
        - Cover all major sections and themes
        - Keep historical context and background
        - DO NOT oversimplify complex concepts
        - Reduce redundancy but preserve substance
        
        STYLE GUIDELINES:
        - Use clear, accessible academic language
        - Maintain encyclopedic tone
        - Structure content logically with clear paragraphs
        - Focus on factual accuracy
        
        Article text (first 15,000 characters):
        \(String(fullText.prefix(15000)))
        
        Provide ONLY the summary with NO preamble, explanation, or meta-commentary.
        Remember: Your summary must be AT LEAST \(minWordCount) words to preserve sufficient detail.
        """
        
        let system = """
        You are an expert at creating comprehensive, detailed summaries of Wikipedia articles.
        You preserve important information, context, and nuance while eliminating only redundancy.
        You ALWAYS meet the specified word count targets to ensure adequate detail preservation.
        You write in an encyclopedic style suitable for academic reference.
        """
        
        return try await claudeService.generateCompletion(
            prompt: prompt,
            system: system,
            maxTokens: AppConstants.Claude.summaryMaxTokens
        )
    }
    
    // MARK: - Article Classification
    
    private func classifyArticle(title: String, summary: String, categories: [String]) async throws -> ArticleType {
        let prompt = """
        Classify this Wikipedia article into ONE of these categories:
        - Person: Biographical articles about individuals
        - Place: Geographic locations (cities, countries, landmarks)
        - Event: Historical events, battles, incidents
        - Concept: Abstract ideas, philosophies, theories
        - Theory: Scientific or academic theories
        - Organization: Companies, institutions, groups
        - Object: Physical objects, artifacts, inventions
        - Work: Creative works (books, films, art)
        - Period: Historical time periods, eras
        - Other: Anything that doesn't fit above
        
        Article: "\(title)"
        Summary: \(summary)
        Categories: \(categories.prefix(5).joined(separator: ", "))
        
        Respond with ONLY the category name (e.g., "Person" or "Place"), nothing else.
        """
        
        let response = try await claudeService.generateCompletion(prompt: prompt)
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Map response to ArticleType
        switch cleaned.lowercased() {
        case "person": return .person
        case "place": return .place
        case "event": return .event
        case "concept": return .concept
        case "theory": return .theory
        case "organization": return .organization
        case "object": return .object
        case "work": return .work
        case "period": return .period
        default: return .other
        }
    }
    
    // MARK: - Key Facts Extraction
    
    private func extractKeyFacts(title: String, fullText: String, infobox: Infobox?) async throws -> [KeyFact] {
        var prompt = """
        Extract the 5-10 most important key facts about "\(title)".
        
        Format each fact as:
        Key: Value
        
        Example:
        Born: 551 BCE
        Occupation: Philosopher
        Known for: Founding Confucianism
        
        """
        
        // Include infobox data if available
        if let infobox = infobox {
            prompt += "\nInfobox data:\n"
            for field in infobox.fields.prefix(15) {
                prompt += "\(field.key): \(field.value)\n"
            }
        }
        
        prompt += """
        
        Article excerpt:
        \(fullText.prefix(3000))
        
        Provide only the key facts in the format shown, one per line.
        """
        
        let response = try await claudeService.generateCompletion(prompt: prompt)
        
        // Parse response into KeyFact objects
        return parseKeyFacts(from: response)
    }
    
    // MARK: - Date Extraction
    
    private func extractDates(title: String, fullText: String) async throws -> [DateEvent] {
        let prompt = """
        Extract important dates and events related to "\(title)".
        
        Format each as:
        Date | Event | Year
        
        Example:
        551 BCE | Birth | -551
        479 BCE | Death | -479
        
        Article excerpt:
        \(fullText.prefix(3000))
        
        Provide only the dates in the format shown, one per line. Use negative years for BCE dates.
        """
        
        let response = try await claudeService.generateCompletion(prompt: prompt)
        
        return parseDateEvents(from: response)
    }
    
    // MARK: - Location Extraction
    
    private func extractLocations(title: String, fullText: String) async throws -> [Location] {
        let prompt = """
        Extract important locations related to "\(title)".
        
        Format each as:
        Name | Type | Modern Name (if different)
        
        Types: city, region, country, landmark, historical_name
        
        Example:
        Lu state | region | Shandong, China
        Qufu | city | Qufu
        
        Article excerpt:
        \(fullText.prefix(3000))
        
        Provide only the locations in the format shown, one per line.
        """
        
        let response = try await claudeService.generateCompletion(prompt: prompt)
        
        return parseLocations(from: response)
    }
    
    // MARK: - Related Topics
    
    private func extractRelatedTopics(title: String, categories: [String], summary: String) async throws -> [String] {
        let prompt = """
        Based on this article about "\(title)", suggest 5-10 related topics that readers might be interested in.
        
        Categories: \(categories.prefix(5).joined(separator: ", "))
        Summary: \(summary.prefix(500))
        
        Provide only the topic names, one per line, no explanations.
        """
        
        let response = try await claudeService.generateCompletion(prompt: prompt)
        
        return response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(10)
            .map { String($0) }
    }
    
    // MARK: - Helper Methods
    
    private func buildFullText(from parsed: ParsedWikipediaContent) -> String {
        var text = parsed.firstParagraph + "\n\n"
        
        // Adaptive section inclusion based on article length
        let sectionCount: Int
        let contentLimit: Int?
        
        if parsed.wordCount < 3000 {
            // Short articles: include all sections, full content
            sectionCount = parsed.sections.count
            contentLimit = nil  // No limit
        } else if parsed.wordCount < 10000 {
            // Medium articles: 10 sections, generous limit
            sectionCount = 10
            contentLimit = 1500
        } else {
            // Long articles: 15 sections, moderate limit
            sectionCount = 15
            contentLimit = 1000
        }
        
        // Add section content
        for section in parsed.sections.prefix(sectionCount) {
            text += "## \(section.title)\n"
            if let limit = contentLimit {
                text += String(section.content.prefix(limit)) + "\n\n"
            } else {
                text += section.content + "\n\n"
            }
        }
        
        // Add infobox for key facts
        if let infobox = parsed.infobox {
            text += "\n## Key Information\n"
            for field in infobox.fields.prefix(20) {
                text += "\(field.key): \(field.value)\n"
            }
        }
        
        return text
    }
    
    private func parseKeyFacts(from response: String) -> [KeyFact] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var facts: [KeyFact] = []
        
        for line in lines {
            let parts = line.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
            
            facts.append(KeyFact(key: key, value: value))
        }
        
        return facts
    }
    
    private func parseDateEvents(from response: String) -> [DateEvent] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("|") }
        
        var events: [DateEvent] = []
        
        for line in lines {
            let parts = line.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            guard parts.count >= 3 else { continue }
            
            let date = parts[0]
            let event = parts[1]
            let year = Int(parts[2])
            
            events.append(DateEvent(
                event: event,
                date: date,
                year: year,
                precision: .approximate
            ))
        }
        
        return events
    }
    
    private func parseLocations(from response: String) -> [Location] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("|") }
        
        var locations: [Location] = []
        
        for line in lines {
            let parts = line.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            guard parts.count >= 2 else { continue }
            
            let name = parts[0]
            let typeString = parts[1].lowercased()
            let modernName = parts.count >= 3 ? parts[2] : nil
            
            let type: LocationType
            switch typeString {
            case "city": type = .city
            case "region": type = .region
            case "country": type = .country
            case "landmark": type = .landmark
            default: type = .historicalName
            }
            
            locations.append(Location(
                name: name,
                type: type,
                modernName: modernName
            ))
        }
        
        return locations
    }
}
