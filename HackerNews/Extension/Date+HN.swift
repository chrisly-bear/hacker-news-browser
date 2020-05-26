//
//  Date+HN.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 5/8/20.
//  Copyright © 2020 Kenichi Fujita. All rights reserved.
//

import Foundation

extension Date {
    var postTimeAgo: String {
        get {
            let calendar = Calendar.current
            let agoSinceToday = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date())
            if agoSinceToday.year ?? 0 >= 1 {
                return "\(agoSinceToday.year ?? 0)y"
            }
            else if agoSinceToday.month ?? 0 >= 1 {
                return "\(agoSinceToday.month ?? 0)m"
            }
            else if agoSinceToday.day ?? 0 >= 1 {
                return "\(agoSinceToday.day ?? 0)d"
            }
            else if agoSinceToday.hour ?? 0 >= 1 {
                return "\(agoSinceToday.hour ?? 0)h"
            }
            else if agoSinceToday.minute ?? 0 >= 1 {
                return "\(agoSinceToday.minute ?? 0)m"
            }
            else {
                return "now"
            }
        }
    }
}
