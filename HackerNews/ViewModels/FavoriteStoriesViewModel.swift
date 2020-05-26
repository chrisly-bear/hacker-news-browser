//
//  FavoriteStoriesViewModel.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 2/3/20.
//  Copyright © 2020 Kenichi Fujita. All rights reserved.
//

import UIKit

class FavoriteStoriesViewModel: StoriesViewModelType {
    var hasMore: Bool = false
    var canShowInstruction: Bool {
        return true
    }
    func loadNext() {
    }
    
    
    var stories: [Story] = [] {
        didSet {
            delegate?.storiesViewModelUpdated(self)
        }
    }
    
    weak var delegate: StoriesViewModelDelegate?
    let api: APIClient = APIClient()
    
    func load() {
        api.stories(for: FavoritesStore.shared.favorites) { (stories) in
            self.stories = stories
        }
    }
    
    init() {
        FavoritesStore.shared.observer = self
    }
}

extension FavoriteStoriesViewModel: FavoriteStoreObserver {
    
    func favoriteStoreUpdated(_ store: FavoritesStore) {
        load()
    }
    
}
