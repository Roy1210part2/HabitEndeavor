//
//  Item.swift
//  HabitEndevor
//
//  Created by 류성균 on 5/6/26.
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
