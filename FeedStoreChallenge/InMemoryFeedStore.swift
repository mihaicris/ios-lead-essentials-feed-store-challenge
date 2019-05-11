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

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        self.memoryFeed = feed.map(InMemoryFeedImage.init)
        self.memoryTimestamp = timestamp
        completion(.none)
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        if let memoryFeed = self.memoryFeed, let timestamp = self.memoryTimestamp {
            let feed = memoryFeed.map { $0.local }
            completion(.found(feed: feed, timestamp: timestamp))
        } else {
            completion(.empty)
        }
    }

}
