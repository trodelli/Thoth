//
//  DatePrecision.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum DatePrecision: String, Codable {
    case exact = "exact"
    case year = "year"
    case decade = "decade"
    case century = "century"
    case approximate = "approximate"
}
