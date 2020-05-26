//
//  StoryImageCache.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 3/18/20.
//  Copyright © 2020 Kenichi Fujita. All rights reserved.
//

import Foundation
import UIKit

class StoryImageCache {
    var storyImageInfos: [String: StoryImageInfo] = [:]
    let key = "touchIcon"
    let userDefaults: UserDefaults
    static let shared = StoryImageCache()
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        if let cached = userDefaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode([String: StoryImageInfo].self, from: cached) {
                self.storyImageInfos = decoded
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addTouchIcon(storyHost: String, storyImageInfo: StoryImageInfo) {
        storyImageInfos[storyHost] = storyImageInfo
    }
    
    @objc func didEnterBackground() {
        save()
    }
    
    private func save() {
        let converted = try? JSONEncoder().encode(storyImageInfos)
        userDefaults.set(converted, forKey: key)
    }
    
}
