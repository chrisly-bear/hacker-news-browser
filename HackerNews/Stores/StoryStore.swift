//
//  StoryStore.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 2/15/20.
//  Copyright © 2020 Kenichi Fujita. All rights reserved.
//

import Foundation

class StoryStore {
    
    let api = APIClient()
    
    var idsForTypes: [StoryQueryType:[Int]] = [:]
    
    func stories(for type: StoryQueryType,
                 offset: Int,
                 limit: Int,
                 completionHandler: @escaping ([Story]) -> Void ) {
        
        guard let idsForType = self.idsForTypes[type] else {
            api.ids(for: type) { (result) in
                if case .success(let ids) = result {
                    let idsForType = ids
                    self.idsForTypes[type] = idsForType
                    self.api.stories(for: Array(idsForType[offset..<(offset + limit)])) { (stories) in
                        completionHandler(stories)
                    }
                }
            }
            return
        }
        if idsForType.count > offset {
            self.api.stories(for: Array(idsForType[offset..<min((offset + limit), idsForType.count)])) { (stories) in
                completionHandler(stories)
            }
        } else {
            completionHandler([])
        }
        
    }
    
}
