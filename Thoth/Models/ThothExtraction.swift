//
//  ThothExtraction.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

struct ThothExtraction: Codable, Identifiable, Hashable {
    let id: UUID
    let metadata: Metadata
    let article: Article
    let temporalContext: TemporalContext
    let geographicContext: GeographicContext
    let structuredContent: StructuredContent
    let classification: Classification
    let references: References
    
    init(
        id: UUID = UUID(),
        metadata: Metadata,
        article: Article,
        temporalContext: TemporalContext = TemporalContext(),
        geographicContext: GeographicContext = GeographicContext(),
        structuredContent: StructuredContent = StructuredContent(),
        classification: Classification = Classification(),
        references: References = References()
    ) {
        self.id = id
        self.metadata = metadata
        self.article = article
        self.temporalContext = temporalContext
        self.geographicContext = geographicContext
        self.structuredContent = structuredContent
        self.classification = classification
        self.references = references
    }
}

// MARK: - Metadata

struct Metadata: Codable, Hashable {
    let extractedAt: Date
    let sourceURL: URL
    let wikipediaPageID: Int?
    let thothVersion: String
    let aiEnhanced: Bool
    let summaryRatio: Double
    let tokensUsed: TokenUsage?
    
    init(
        extractedAt: Date = Date(),
        sourceURL: URL,
        wikipediaPageID: Int? = nil,
        thothVersion: String = AppConstants.appVersion,
        aiEnhanced: Bool = false,
        summaryRatio: Double = AppConstants.Defaults.summaryRatio,
        tokensUsed: TokenUsage? = nil
    ) {
        self.extractedAt = extractedAt
        self.sourceURL = sourceURL
        self.wikipediaPageID = wikipediaPageID
        self.thothVersion = thothVersion
        self.aiEnhanced = aiEnhanced
        self.summaryRatio = summaryRatio
        self.tokensUsed = tokensUsed
    }
}

// Token usage tracking
struct TokenUsage: Codable, Hashable {
    let inputTokens: Int
    let outputTokens: Int
}

// MARK: - Article

struct Article: Codable, Hashable {
    let title: String
    let alternateNames: [String]
    let summary: String
    let type: ArticleType
    let wordCount: Int
    let originalWordCount: Int
    
    init(
        title: String,
        alternateNames: [String] = [],
        summary: String = "",
        type: ArticleType = .other,
        wordCount: Int = 0,
        originalWordCount: Int = 0
    ) {
        self.title = title
        self.alternateNames = alternateNames
        self.summary = summary
        self.type = type
        self.wordCount = wordCount
        self.originalWordCount = originalWordCount
    }
}

// MARK: - Temporal Context

struct TemporalContext: Codable, Hashable {
    let dates: [DateEvent]
    let timePeriod: TimePeriod?
    
    init(dates: [DateEvent] = [], timePeriod: TimePeriod? = nil) {
        self.dates = dates
        self.timePeriod = timePeriod
    }
}

struct DateEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let event: String
    let date: String
    let year: Int?
    let precision: DatePrecision
    
    init(
        id: UUID = UUID(),
        event: String,
        date: String,
        year: Int? = nil,
        precision: DatePrecision = .approximate
    ) {
        self.id = id
        self.event = event
        self.date = date
        self.year = year
        self.precision = precision
    }
}

struct TimePeriod: Codable, Hashable {
    let name: String
    let startYear: Int?
    let endYear: Int?
    let description: String?
    
    init(
        name: String,
        startYear: Int? = nil,
        endYear: Int? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.startYear = startYear
        self.endYear = endYear
        self.description = description
    }
}

// MARK: - Geographic Context

struct GeographicContext: Codable, Hashable {
    let locations: [Location]
    
    init(locations: [Location] = []) {
        self.locations = locations
    }
}

struct Location: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: LocationType
    let modernName: String?
    let coordinates: Coordinates?
    
    init(
        id: UUID = UUID(),
        name: String,
        type: LocationType,
        modernName: String? = nil,
        coordinates: Coordinates? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.modernName = modernName
        self.coordinates = coordinates
    }
}

struct Coordinates: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Structured Content

struct StructuredContent: Codable, Hashable {
    let infobox: Infobox?
    let tables: [Table]
    let sections: [Section]
    let lists: [ListContent]
    
    init(
        infobox: Infobox? = nil,
        tables: [Table] = [],
        sections: [Section] = [],
        lists: [ListContent] = []
    ) {
        self.infobox = infobox
        self.tables = tables
        self.sections = sections
        self.lists = lists
    }
}

struct Infobox: Codable, Hashable {
    let type: String?
    let fields: [InfoboxField]
    
    init(type: String? = nil, fields: [InfoboxField] = []) {
        self.type = type
        self.fields = fields
    }
}

struct InfoboxField: Codable, Identifiable, Hashable {
    let id: UUID
    let key: String
    let value: String
    
    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct Table: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let headers: [String]
    let rows: [[String]]
    let rowCount: Int
    let truncated: Bool
    let sourceSection: String?
    
    init(
        id: String,
        title: String,
        description: String? = nil,
        headers: [String] = [],
        rows: [[String]] = [],
        rowCount: Int = 0,
        truncated: Bool = false,
        sourceSection: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.headers = headers
        self.rows = rows
        self.rowCount = rowCount
        self.truncated = truncated
        self.sourceSection = sourceSection
    }
}

struct Section: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let level: Int
    let content: String
    let wordCount: Int
    let subsections: [Section]?
    
    init(
        id: String,
        title: String,
        level: Int,
        content: String = "",
        wordCount: Int = 0,
        subsections: [Section]? = nil
    ) {
        self.id = id
        self.title = title
        self.level = level
        self.content = content
        self.wordCount = wordCount
        self.subsections = subsections
    }
}

struct ListContent: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String?
    let items: [String]
    let ordered: Bool
    
    init(
        id: UUID = UUID(),
        title: String? = nil,
        items: [String] = [],
        ordered: Bool = false
    ) {
        self.id = id
        self.title = title
        self.items = items
        self.ordered = ordered
    }
}

// MARK: - Classification

struct Classification: Codable, Hashable {
    let categories: [String]
    let keyFacts: [KeyFact]
    let relatedTopics: [String]
    
    init(
        categories: [String] = [],
        keyFacts: [KeyFact] = [],
        relatedTopics: [String] = []
    ) {
        self.categories = categories
        self.keyFacts = keyFacts
        self.relatedTopics = relatedTopics
    }
}

struct KeyFact: Codable, Identifiable, Hashable {
    let id: UUID
    let key: String
    let value: String
    
    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

// MARK: - References

struct References: Codable, Hashable {
    let seeAlso: [SeeAlsoLink]
    
    init(seeAlso: [SeeAlsoLink] = []) {
        self.seeAlso = seeAlso
    }
}

struct SeeAlsoLink: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let url: URL?
    
    init(id: UUID = UUID(), title: String, url: URL? = nil) {
        self.id = id
        self.title = title
        self.url = url
    }
}
