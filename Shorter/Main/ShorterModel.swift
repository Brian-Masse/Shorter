//
//  ShorterModel.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation

struct ShorterModel {
    
    static var shared: ShorterModel = ShorterModel()
    
    static var ownerId: String { ShorterModel.realmManager.user?.id ?? "" }
    
    static var realmManager: RealmManager = RealmManager.shared
    
    var profile: ShorterProfile? = nil
}
