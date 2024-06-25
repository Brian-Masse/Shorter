//
//  ShorterModel.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import UIUniversals
import SwiftUI

struct ShorterModel {
    
    static var shared: ShorterModel = ShorterModel()
    
    static var ownerId: String { ShorterModel.realmManager.user?.id ?? "" }
    
    static var realmManager: RealmManager = RealmManager.shared
    
    var profile: ShorterProfile? = nil
    
//    MARK: Style
    static let defautColorPallett : [Color] = [
        Color(hex: "#875F8A"),
        Color(hex: "#49404A"),
        Color(hex: "#51574D"),
        Color(hex: "#2E3529"),
        Color(hex: "#977999"),
        Color(hex: "#7A5C7D"),
    ]
}
