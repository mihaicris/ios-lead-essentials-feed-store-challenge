//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import CoreData

final public class CoreDataFeedStore: FeedStore {

    private let viewContext: NSManagedObjectContext
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator

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

        init(id: UUID,
             description: String?,
             location: String?,
             url: URL) {
            self.id = id
            self.description = description
            self.location = location
            self.url = url
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
        self.persistentStoreCoordinator = container.persistentStoreCoordinator
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let feedFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedItem")
        let timestampFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Timestamp")

        let deleteFeed = NSBatchDeleteRequest(fetchRequest: feedFetchRequest)
        let deleteTimestamp = NSBatchDeleteRequest(fetchRequest: timestampFetchRequest)

        do {
            try self.persistentStoreCoordinator.execute(deleteFeed, with: self.viewContext)
            try self.persistentStoreCoordinator.execute(deleteTimestamp, with: self.viewContext)
            completion(.none)
        } catch let error as NSError {
            completion(error)
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let coreDataFeed = feed.map(CoreDataFeedImage.init)

        let timestampManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Timestamp", into: self.viewContext)
        timestampManagedObject.setValue(timestamp, forKey: "date")

        for item in coreDataFeed {
            let feedItemManagedObject = NSEntityDescription.insertNewObject(forEntityName: "FeedItem", into: self.viewContext)
            feedItemManagedObject.setValue(item.id, forKey: "id")
            feedItemManagedObject.setValue(item.description, forKey: "itemDescription")
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
        let feedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedItem")
        let timestampRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Timestamp")
        feedRequest.returnsObjectsAsFaults = false
        timestampRequest.returnsObjectsAsFaults = false
        var feed: [CoreDataFeedImage] = []
        do {
            let feedResults = try self.viewContext.fetch(feedRequest)
            let timestampResults = try self.viewContext.fetch(timestampRequest)

            switch (feedResults.isEmpty, timestampResults.isEmpty) {
            case (true, true):
                completion(.empty)
            case (false, false):
                for item in feedResults as! [NSManagedObject] {
                    guard let id = item.value(forKey: "id") as? UUID else { continue }
                    guard let description = item.value(forKey: "itemDescription") as? String else { continue }
                    guard let location = item.value(forKey: "location") as? String else { continue }
                    guard let url = item.value(forKey: "url") as? URL else { continue }
                    let feedImage = CoreDataFeedImage(id: id, description: description, location: location, url: url)
                    feed.append(feedImage)
                }
                guard let timestamp = (timestampResults.first as? NSManagedObject)?.value(forKey: "date") as? Date else {
                    completion(.failure(NSError(domain: "Core Data", code: 0, userInfo: [:])))
                    return
                }
                completion(.found(feed: feed.map { $0.local }, timestamp: timestamp))
            default:
                completion(.failure(NSError(domain: "Core Data", code: 0, userInfo: [:])))
            }
        } catch {
            completion(.failure(error))
        }

    }

}


