//
//  ArticleType.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum ArticleType: String, Codable, CaseIterable, Identifiable {
    case person = "Person"
    case place = "Place"
    case event = "Event"
    case concept = "Concept"
    case theory = "Theory"
    case organization = "Organization"
    case object = "Object"
    case work = "Work"
    case period = "Period"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .person: return "person.fill"
        case .place: return "mappin.circle.fill"
        case .event: return "calendar"
        case .concept: return "lightbulb.fill"
        case .theory: return "atom"
        case .organization: return "building.2.fill"
        case .object: return "cube.fill"
        case .work: return "book.fill"
        case .period: return "clock.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}
