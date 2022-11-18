//
//  VideoController.swift
//  gorb
//
//  Created by Niall on 9/11/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit
import CoreData
import CocoaLumberjackSwift

protocol VideoControllerDelegate : class {
    func finishedRefresh(error: Error?)
    func updateThumbnails(indexPaths : [IndexPath])
}
class VideoController: NSObject {

    weak var delegate : VideoControllerDelegate?
    let serialQueue = DispatchQueue(label: "thumbnailqueue")
    var task : URLSessionDataTask?
    var downloadThumbnailsWorkItem : DispatchWorkItem?

    override init() {
        super.init()

        DDLogDebug("Initializing VideoController")
//        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextUpdated(_:)), name: .NSManagedObjectContextDidSave, object: backgroundContext)
    }

    deinit {
        DDLogDebug("Deinitializing VideoController")
        NotificationCenter.default.removeObserver(self)
    }
//
//    @objc func backgroundContextUpdated(_ notification : NSNotification) {
//        DDLogDebug("backgroundContextUpdated - merging changes")
//        DispatchQueue.main.async {
//            self.persistentContainer?.viewContext.mergeChanges(fromContextDidSave: notification as Notification)
//        }
//    }

    func cancelRefresh() {
        DDLogDebug("cancelRefresh")
        if task?.state == URLSessionDataTask.State.running {
            DDLogDebug("Task is running - cancelling")
            task?.cancel()
        }

        downloadThumbnailsWorkItem?.cancel()
    }
    // MARK: - Deletion

    // MARK: - Network Refresh


//    func downloadThumbnails(_ videoIds : [NSManagedObjectID]) {
//        DDLogDebug("downloadThumbnails")
//        var i = 0
//        var indexPaths : [IndexPath] = []
//
//        for videoID in videoIds {
//
//            do {
//                let video = VideosProvider.shared.getVideo(withId: videoID)
//                if video.isFault {
//                    print("Test")
//                    continue
//                }
//                
//                //Try downloading the thumbnail from the reddit object, but if that doesn't exist, just grab it from Youtube
//                if let url = URL.init(string: video.thumbnail) {
//                    video.thumbnail_data = try NSData.init(contentsOf: url) as Data
//                } else if let url = URL.init(string: "https://img.youtube.com/vi/\(video.id)/1.jpg") {
//                    video.thumbnail_data = try NSData.init(contentsOf: url) as Data
//                }
//
//                //Add this video indexPath to our list to update
//                indexPaths.append(IndexPath(row: i, section: 0))
//
//            } catch {
//                //Just continue on to the next one
//                DDLogError("Failed to download thumbnail for index \(i)")
//            }
//
//            i += 1
//            if i % 5 == 0 {
//
//                do {
//                    DDLogDebug("Saving context after 5 thumbnails")
//                    try VideosProvider.shared.save()
//                } catch let error {
//                    DDLogError("Error trying to save context while downloading thumbnails: \(error)")
//                }
//
//                DDLogDebug("Updating thumbnails after 5 processed")
//                self.delegate?.updateThumbnails(indexPaths: indexPaths)
//
//                indexPaths.removeAll()
//            }
//        }
//
//        do {
//            try VideosProvider.shared.save()
//        } catch let error {
//            DDLogError("Error trying to perform final save context while downloading thumbnails: \(error)")
//        }
//    }

    // MARK: - Parsing

    func parse<T: Decodable> (_ jsonData: Data, entity: T.Type) -> T? {
        DDLogDebug("Parsing json data")
        do {
            guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext else {
                fatalError("Failed to retrieve context")
            }

            // Parse JSON data
            let managedObjectContext = VideosProvider.shared.container.newBackgroundContext()

            let decoder = JSONDecoder()
            decoder.userInfo[codingUserInfoKeyManagedObjectContext] = managedObjectContext

            DDLogDebug("Going to decode from jsonData")
            let entities = try decoder.decode(entity, from: jsonData)

            DDLogDebug("Saving context after decoding")
            try managedObjectContext.save()

            return entities
        } catch let error {
            print(error)
            return nil
        }
    }
}

