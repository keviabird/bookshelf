//
//  Item.swift
//  Bookshelf
//
//  Created by Elena Gracheva on 26.10.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
