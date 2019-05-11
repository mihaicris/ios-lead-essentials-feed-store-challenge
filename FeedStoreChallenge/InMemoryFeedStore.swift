//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import Foundation

public class InMemoryFeedStore: FeedStore {
    public init() {}

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }

    
}
