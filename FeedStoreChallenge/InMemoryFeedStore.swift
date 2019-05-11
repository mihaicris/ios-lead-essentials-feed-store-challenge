//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import Foundation

public class InMemoryFeedStore: FeedStore {

    private struct InMemoryFeedImage {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL

        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    public init() {}

    private var memoryFeed: [InMemoryFeedImage]?
    private var memoryTimestamp: Date?

    private let queue = DispatchQueue(label: "\(InMemoryFeedStore.self)-Queue", qos: .userInitiated, attributes: .concurrent)

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        queue.async(flags: .barrier) {
            self.memoryFeed = nil
            self.memoryTimestamp = nil
            completion(.none)
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        queue.async(flags: .barrier) {
            self.memoryFeed = feed.map(InMemoryFeedImage.init)
            self.memoryTimestamp = timestamp
            completion(.none)
        }
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        queue.async {
            if let memoryFeed = self.memoryFeed, let timestamp = self.memoryTimestamp {
                let feed = memoryFeed.map { $0.local }
                completion(.found(feed: feed, timestamp: timestamp))
            } else {
                completion(.empty)
            }
        }
    }

}
