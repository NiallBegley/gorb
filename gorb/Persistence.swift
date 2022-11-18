//
//  Persistence.swift
//  gorb
//
//  Created by Niall Begley on 11/14/22.
//

import CoreData
import CocoaLumberjackSwift

struct VideosProvider {
    static let shared = VideosProvider()

    static var preview: VideosProvider = {
        let result = VideosProvider(inMemory: true)
        let viewContext = result.container.viewContext

        Video.makePreviews(count: 10)
        return result
    }()

    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "gorb")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDOSLogger.sharedInstance.logFormatter = CustomDDLogFormatter()
        DDLog.add(fileLogger)
    }

    func save() throws {
        let context = Thread.isMainThread ? container.viewContext : backgroundContext

        try context.save()
    }


    func deleteAll() -> Bool {
        DDLogDebug("deleteAll")
        let context = self.container.viewContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            DDLogError("Error deleting all Videos: " + error.localizedDescription)
            return false
        }

        return true
    }

    // MARK: - Fetching Existing

    func getAllVideos() async -> [Video] {

        DDLogDebug("Getting videos from core data")
        do {
            return try await backgroundContext.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
//                fetchRequest.predicate = NSPredicate.init(format: "(url CONTAINS[cd] %@ OR url CONTAINS[cd] %@) AND id.length > 0", "youtube.com", "youtu.be")
//                fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "created_at", ascending: true)]

                let videos = try backgroundContext.fetch(fetchRequest)
                return videos as! [Video]
            }
        } catch let error {
            print(error)
            return []
        }
    }

    func getVideo(withId id: NSManagedObjectID) async -> Video {
        let video = await backgroundContext.perform {
            let video = self.container.viewContext.object(with: id)
            return video
        }
        return video as! Video
    }

    enum VideoError: Error {
        case badRequest
        case parseError(error: Error)
        case batchInsertError
    }

    func refreshVideos() async throws {
//        cancelRefresh()

        DDLogDebug("refreshing videos from network")

        guard var urlcomp = URLComponents(string: "https://www.reddit.com/r/videos/hot.json") else { return }
        urlcomp.queryItems = [
            URLQueryItem.init(name: "limit", value: "100")
        ]

        guard let url = urlcomp.url else {  return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let session = URLSession.shared
        guard let (data, response) = try? await session.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VideoError.badRequest
        }

        do {
            guard let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject],
                let data = jsonData["data"],
                let children = data["children"] as? [[String:AnyObject]] else {
                    DDLogError("Error parsing through response json")
                    return
            }

            let entries = children.map {
                (entry) -> AnyObject? in
                return entry["data"]
            }

            let jsonobject = try JSONSerialization.data(withJSONObject: entries, options: .init())

            let jsonDecoder = JSONDecoder()
            let videoProps = try jsonDecoder.decode([VideoProperties].self, from: jsonobject)

            print("\(videoProps)")
            try await importVideos(videoProps)

//            //We're not going to use the return of parse() here because we want to filter out the same videos the ViewController does (ie non-youtube videos).  If we work off different sets of data the update calls for the thumbnail data have a chance of crashing
//            let videos = VideosProvider.shared.getAllVideos()
//
//            let videoIds : [NSManagedObjectID] = videos.map{(video) -> NSManagedObjectID in
//                return video.objectID
//            }
//
//            DDLogDebug("Finished parsing videos - calling finishedRefresh")
//            self.delegate?.finishedRefresh(error: nil)
//
//            DDLogDebug("Cancelling download thumbnails work item")
//            self.downloadThumbnailsWorkItem?.cancel()
//
//            self.downloadThumbnailsWorkItem = DispatchWorkItem(block: {
//                DDLogDebug("Download thumbnails work item began")
//                self.downloadThumbnails(videoIds)
//            })
//
//            DDLogDebug("Starting new download thumbnails work item")
//            if self.downloadThumbnailsWorkItem != nil {
//                self.serialQueue.async(execute: self.downloadThumbnailsWorkItem!)
//            }
        } catch let error {
            throw VideoError.parseError(error: error)
        }
    }

    private func importVideos(_ videoProperties: [VideoProperties]) async throws{
        guard !videoProperties.isEmpty else { return }
        var index = 0
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await context.perform {
//            let batchInsertRequest =  NSBatchInsertRequest(entity: Video.entity(), dictionaryHandler: { dictionary in
//                guard index < videoProperties.count else { return true }
//                dictionary.addEntries(from: videoProperties[index].dictionaryValue)
//                print("Getting \(index) dictionary for video: \(videoProperties[index])")
//                index += 1
//                return false
//            })

            let batchInsertRequest =  NSBatchInsertRequest(entity: Video.entity(), managedObjectHandler: { object in
                guard index < videoProperties.count else { return true }
                let video = object as! Video
                do {
                    try video.update(from: videoProperties[index])
                } catch(let error) {
                    
                }
                print("Getting \(index) dictionary for video: \(videoProperties[index])")
                index += 1
                return false
            })

            if let fetchResult = try? context.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }

            throw VideoError.batchInsertError
        }
    }

}
