//
//  ExtractionEngine.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

class ExtractionEngine {
    private let wikipediaService: WikipediaService
    private let wikipediaParser: WikipediaParser
    private let aiEnhancementService: AIEnhancementService
    private let logger = Logger.shared
    
    // NEW: Progress callback
    var onProgressUpdate: ((ExtractionStep) -> Void)?
    
    init(
        wikipediaService: WikipediaService,
        wikipediaParser: WikipediaParser,
        aiEnhancementService: AIEnhancementService = AIEnhancementService()
    ) {
        self.wikipediaService = wikipediaService
        self.wikipediaParser = wikipediaParser
        self.aiEnhancementService = aiEnhancementService
    }
    
    func extract(url: URL, aiEnabled: Bool, summaryRatio: Double) async throws -> ThothExtraction {
        // Step 1: Fetch from Wikipedia
        onProgressUpdate?(.fetchingWikipedia)
        logger.info("Fetching: \(url.lastPathComponent)")
        let article = try await wikipediaService.fetchArticle(url: url)
        onProgressUpdate?(.parsingHTML)
        
        // Step 2: Parse HTML
        logger.info("Parsing HTML")
        let parsed = try wikipediaParser.parse(article)
        
        // Step 3: AI Enhancement (if enabled)
        var summary = parsed.firstParagraph
        var articleType: ArticleType = .other
        var keyFacts: [KeyFact] = []
        var dates: [DateEvent] = []
        var locations: [Location] = []
        var relatedTopics: [String] = []
        var totalInputTokens = 0
        var totalOutputTokens = 0
        
        if aiEnabled {
            logger.info("Applying AI enhancements")
            
            do {
                // Generate summary
                onProgressUpdate?(.generatingSummary)
                let (aiSummary, summaryTokens) = try await aiEnhancementService.enhanceWithTokens(
                    parsed: parsed,
                    targetRatio: summaryRatio,
                    onProgressUpdate: onProgressUpdate
                )
                
                summary = aiSummary.summary
                articleType = aiSummary.articleType
                keyFacts = aiSummary.keyFacts
                dates = aiSummary.dates
                locations = aiSummary.locations
                relatedTopics = aiSummary.relatedTopics
                totalInputTokens = summaryTokens.inputTokens
                totalOutputTokens = summaryTokens.outputTokens
                
                logger.success("AI enhancement complete")
                logger.info("💰 Cost: \(CostCalculator.shared.calculateCost(inputTokens: totalInputTokens, outputTokens: totalOutputTokens).formattedCost)")
                
            } catch {
                logger.warning("AI enhancement failed, using basic extraction", details: error.localizedDescription)
                logger.info("Basic extraction will be available without AI enhancements")
            }
        }
        
        onProgressUpdate?(.complete)
        
        // Step 4: Build ThothExtraction
        let extraction = ThothExtraction(
            metadata: Metadata(
                sourceURL: url,
                wikipediaPageID: parsed.pageID,
                aiEnhanced: aiEnabled,
                summaryRatio: summaryRatio,
                tokensUsed: aiEnabled ? TokenUsage(
                    inputTokens: totalInputTokens,
                    outputTokens: totalOutputTokens
                ) : nil
            ),
            article: Article(
                title: parsed.title,
                alternateNames: parsed.alternateNames,
                summary: summary,
                type: articleType,
                wordCount: summary.split(separator: " ").count,
                originalWordCount: parsed.wordCount
            ),
            temporalContext: TemporalContext(
                dates: dates
            ),
            geographicContext: GeographicContext(
                locations: locations
            ),
            structuredContent: StructuredContent(
                infobox: parsed.infobox,
                tables: parsed.tables,
                sections: parsed.sections
            ),
            classification: Classification(
                categories: parsed.categories,
                keyFacts: keyFacts,
                relatedTopics: relatedTopics
            ),
            references: References(
                seeAlso: parsed.seeAlso
            )
        )
        
        logger.success("Extraction complete: \(parsed.title)")
        return extraction
    }
}
