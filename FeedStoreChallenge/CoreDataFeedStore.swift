//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import CoreData

final public class CoreDataFeedStore: FeedStore {

    private let viewContext: NSManagedObjectContext

    private struct CoreDataFeedImage {
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

    public init(storeURL: URL) {
        let bundle = Bundle(for: type(of: self))
        let modelURL = bundle.url(forResource: "FeedItemsModel", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!

        // Set custom path for SQLight database
        let description = NSPersistentStoreDescription(url: storeURL)
        let container = NSPersistentContainer(name: "FeedItemsModel", managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        self.viewContext = container.viewContext
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let coreDataFeed = feed.map(CoreDataFeedImage.init)

        let timestampManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Timestamp", into: self.viewContext)
        timestampManagedObject.setValue(timestamp, forKey: "date")

        for item in coreDataFeed {
            let feedItemManagedObject = NSEntityDescription.insertNewObject(forEntityName: "FeedItem", into: self.viewContext)
            feedItemManagedObject.setValue(item.id, forKey: "id")
            feedItemManagedObject.setValue(item.description, forKey: "feedDescription")
            feedItemManagedObject.setValue(item.location, forKey: "location")
            feedItemManagedObject.setValue(item.url, forKey: "url")
        }

        do {
            try self.viewContext.save()
            completion(.none)
        } catch {
            completion(error)
        }
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }

}


