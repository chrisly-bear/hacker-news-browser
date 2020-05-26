//
//  APIClient.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 11/22/19.
//  Copyright © 2019 Kenichi Fujita. All rights reserved.
//

import Foundation

public struct Item: Decodable {
    
    public let id: Int?
    let deleted: Bool?
    public let by: String?
    public let date: Date
    let text: String?
    let dead: Bool?
    let parent: Int?
    let poll: Int?
    public let kids: [Int]?
    public let url: String?
    public let score: Int?
    public let title: String?
    let parts: [Int]?
    public let descendants: Int?
    
    private enum CodingKeys: String, CodingKey {
        case date = "time"
        case id
        case deleted
        case by
        case text
        case dead
        case parent
        case poll 
        case kids
        case url 
        case score
        case title
        case parts
        case descendants
    }
}

public struct Story {
    
    public let by: String
    public let descendants: Int
    public let id: Int
    public var commentIDs: [Int]? = nil
    public let score: Int
    public let date: Date
    public let title: String
    public let url: String?
    public let text: String?
    public var type: StoryType {
        if title.hasPrefix("Show HN:") {
            return .show
        } else if title.hasPrefix("Ask HN:") || url == nil {
            return .ask
        } else {
            return .normal
        }
    }
    public var info: String {
        ["\(score) points", by, date.postTimeAgo].compactMap { $0 }.joined(separator: " · ")
    }
    
    public init(_ item: Item) {
        self.by = item.by ?? ""
        self.descendants = item.descendants ?? 0
        self.id = item.id ?? 0
        self.commentIDs = item.kids ?? []
        self.score = item.score ?? 0
        self.date = item.date
        self.title = item.title ?? ""
        self.url = item.url
        self.text = item.text
    }
}

public enum StoryType: String {
    case ask
    case show
    case normal
}

public struct Comment {
    public let by: String?
    public let deleted: Bool
    public let id: Int
    public let commentIDs: [Int]?
    public var comments: [Comment] = []
    public let parent: Int
    public var text: String?
    public let date: Date
    public let tier: Int
    public var info: String {
        [by, date.postTimeAgo].compactMap { $0 }.joined(separator: " · ")
    }
}

extension Comment {
    
    public var flatten: [Comment] {
        var array: [Comment] = [self]
        for comment in comments {
            array.append(contentsOf: comment.flatten)
        }
        return array
    }
    
}


public enum StoryQueryType: String {
    case top
    case ask
    case show
    
}

public class APIClient {
    
    private let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
    private var hackerNewsSearchTask: URLSessionTask?
    
    public init() {}
    
    public func getItem(id: Int, completionHandler: @escaping (Result<Item, APIClientError>) -> Void) {
        guard let itemUrl = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") else {
            completionHandler(.failure(.invalidURL))
            return
        }
        session.dataTask(with: itemUrl) { data, response, error in
            guard let data = data else {
                completionHandler(.failure(.domainError))
                return
            }
            do {
                let item = try JSONDecoder.hackerNews.decode(Item.self, from: data)
                completionHandler(.success(item))
            }
            catch {
                completionHandler(.failure(.decodingError))
            }
        }.resume()
    }
    
    public func stories(for ids: [Int], completionHandler: @escaping ([Story]) -> Void) {
        var stories: [Int: Story] = [:]
        if ids.count == 0 {
            completionHandler([])
            return
        }
        for id in ids {
            self.getItem(id: id) { (result) in
                if case .success(let item) = result {
                    let story: Story = Story(item)
                    stories[id] = story
                    if stories.count == ids.count {
                        completionHandler(ids.compactMap { stories[$0] })
                    }
                }
            }
        }
    }
    
    public func ids(for type: StoryQueryType, completionHandler: @escaping (Result<[Int], APIClientError>) -> Void) {
        guard let url: URL = URL(string: "https://hacker-news.firebaseio.com/v0/\(type.rawValue)stories.json") else {
            completionHandler(.failure(.invalidURL))
            return
        }
        session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completionHandler(.failure(.domainError))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let json = json as? [Int] {
                    let ids = Array(json[0..<min(200, json.count)])
                    completionHandler(.success(ids))
                }
            }
            catch {
                completionHandler(.failure(.decodingError))
            }
            
        }.resume()
    }
    
}

private struct HNSStoryResponse: Decodable {
    let hits: [HNSStory]
}

private struct HNSStory: Decodable {
    public let date: Date
    public let title: String
    public let url: String?
    public let by: String
    public let score: Int
    public let descendants: Int
    public let id: String?
    public let text: String?
    
    private enum CodingKeys: String, CodingKey {
        case date = "createdAt"
        case title
        case url
        case by = "author"
        case score = "points"
        case descendants = "numComments"
        case id = "objectID"
        case text
    }
}

private struct HNSCommentResponse: Codable {
    let children: FailableCodableArray<HNSComment>
}

private struct HNSComment: Codable {
    public let id: Int
    public let date: Date
    public let by: String
    public var text: String?
    public var parent: Int?
    public var storyID: Int?
    public var comments: [HNSComment?]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case date = "createdAt"
        case by = "author"
        case text
        case parent = "parentID"
        case storyID
        case comments = "children"
    }
}

public enum APIClientError: Error {
    case invalidURL
    case domainError
    case decodingError
}

extension APIClient {

    public func searchStories(searchWord: String, completionHandler: @escaping (Result<[Story], APIClientError>) -> Void) {
        hackerNewsSearchTask?.cancel()
        guard searchWord != "" else {
            completionHandler(.success([]))
            return
        }
        guard let url: URL = URL(string: "http://hn.algolia.com/api/v1/search?query=\(searchWord)&tags=story") else {
            completionHandler(.failure(.invalidURL))
            return
        }
        self.hackerNewsSearchTask = session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completionHandler(.failure(.domainError))
                return
            }
            do {
                let hnsStoryResponse = try JSONDecoder.hackerNewsSearch.decode(HNSStoryResponse.self, from: data)
                let hnsStories = hnsStoryResponse.hits.compactMap { $0 }
                completionHandler(.success(hnsStories.compactMap { Story(hnsStory: $0) }))
            }
            catch {
                completionHandler(.failure(.decodingError))
            }
        }
        hackerNewsSearchTask?.resume()
    }
    
    public func comment(id: Int, completionHandler: @escaping (Result<[Comment], APIClientError>) -> Void) {
        guard let url = URL(string: "http://hn.algolia.com/api/v1/items/\(id)") else {
            completionHandler(.failure(.invalidURL))
            return
        }
        session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completionHandler(.failure(.domainError))
                return
            }
            do {
                let comments = try JSONDecoder.hackerNewsSearch.decode(HNSCommentResponse.self, from: data).children.elements
                completionHandler(.success(comments.map { Comment(hnsComment: $0) }))
            }
            catch {
                completionHandler(.failure(.decodingError))
            }
        }.resume()
    }
}

extension Story {
    fileprivate init(hnsStory: HNSStory) {
        self.by = hnsStory.by
        self.descendants = hnsStory.descendants
        self.id = Int(hnsStory.id ?? "0") ?? 0
        self.score = hnsStory.score
        self.date = hnsStory.date
        self.title = hnsStory.title
        self.url = hnsStory.url
        self.text = hnsStory.text
    }
}

extension Comment {
    fileprivate init(hnsComment: HNSComment, tier: Int = 0) {
        self.by = hnsComment.by
        self.deleted = false
        self.id = hnsComment.id
        self.commentIDs = []
        self.comments = hnsComment.comments.compactMap { $0 }.compactMap { Comment(hnsComment: $0, tier: tier + 1) }
        self.parent = hnsComment.parent ?? 0
        self.text = hnsComment.text
        self.date = hnsComment.date
        self.tier = tier
    }
}

extension JSONDecoder {
    static var hackerNews: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
    
    static var hackerNewsSearch: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
}

struct FailableCodableArray<Element: Codable>: Codable {
    var elements: [Element]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements = [Element]()
        if let count = container.count {
            elements.reserveCapacity(count)
        }
        while !container.isAtEnd {
            if let element = try container.decode(FailableDecodable<Element>.self).base {
                elements.append(element)
            }
        }
        self.elements = elements
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }
}

struct FailableDecodable<Base: Codable>: Codable {
    let base: Base?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.base = try? container.decode(Base.self)
    }
}
