//
//  LocationType.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum LocationType: String, Codable {
    case city = "city"
    case region = "region"
    case country = "country"
    case landmark = "landmark"
    case historicalName = "historical_name"
}
