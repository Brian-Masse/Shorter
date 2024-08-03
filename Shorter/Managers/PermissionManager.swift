//
//  PermissionManager.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift

//these are the names used for each of the different queries throuhgout the app
//they are used when adding / removing queries
enum QuerySubKey: String, CaseIterable {
    case shorterPostQuery
    case shorterProfileQuery
    case timingManager
    case blockedUsersQuery
}

//MARK: QueryPermission
class QueryPermission<T: Object> {
    
    let name: String
    let query: ((Query<T>) -> Query<Bool>)
    
    var addedSubscription: Bool = false
    
    private var additionalQueries: [ QueryPermission<T> ] = []
    
    init( named name: String, query: @escaping (Query<T>) -> Query<Bool> ) {
        self.name = name
        self.query = query
    }
    
    func getSubscription() -> QuerySubscription<T> {
        self.addedSubscription = true
        return QuerySubscription(name: name, query: query)
    }
    
    func addQuery(_ name: String, _ query: @escaping ((Query<T>) -> Query<Bool>) ) async {
        let additionalQuery = QueryPermission(named: name, query: query)
        
        let _ = await RealmManager.shared.addGenericSubcriptions(name: name, query: query)
        additionalQueries.append(additionalQuery)
    }
    
    func removeQuery(_ name: String) async {
        await RealmManager.shared.removeSubscription(name: name)
        if let index = additionalQueries.firstIndex(where: { wrappedQuery in
            wrappedQuery.name == name
        }) {
            additionalQueries.remove(at: index)
        }
    }
    
    func removeAllNonBaseQueries() async {
        for query in additionalQueries {
            await removeQuery( query.name )
        }
    }
}
