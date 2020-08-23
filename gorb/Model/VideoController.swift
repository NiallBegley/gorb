//
//  VideoController.swift
//  gorb
//
//  Created by Niall on 9/11/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit
import CoreData
import CocoaLumberjack

protocol VideoControllerDelegate : class {
    func finishedRefresh(error: Error?)
    func updateThumbnails(indexPaths : [IndexPath])
}
class VideoController: NSObject {

    var persistentContainer: NSPersistentContainer?
    weak var delegate : VideoControllerDelegate?
    let serialQueue = DispatchQueue(label: "thumbnailqueue")
    let backgroundContext : NSManagedObjectContext?
    var task : URLSessionDataTask?
    var downloadThumbnailsWorkItem : DispatchWorkItem?
    
    init(container: NSPersistentContainer) {
        backgroundContext = container.newBackgroundContext()
        super.init()
        
        self.persistentContainer = container
        DDLogDebug("Initializing VideoController")
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextUpdated(_:)), name: .NSManagedObjectContextDidSave, object: backgroundContext)
    }
    
    deinit {
        DDLogDebug("Deinitializing VideoController")
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func backgroundContextUpdated(_ notification : NSNotification) {
        DDLogDebug("backgroundContextUpdated - merging changes")
        self.persistentContainer?.viewContext.mergeChanges(fromContextDidSave: notification as Notification)
    }
    
    func cancelRefresh() {
        DDLogDebug("cancelRefresh")
        if task?.state == URLSessionDataTask.State.running {
            DDLogDebug("Task is running - cancelling")
            task?.cancel()
        }
        
        downloadThumbnailsWorkItem?.cancel()
    }
    // MARK: - Deletion
    
    func deleteAll() -> Bool {
        DDLogDebug("deleteAll")
        guard let context = self.persistentContainer?.viewContext else {
            DDLogError("Failed to get persistent container context")
            return false
        }
        
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
    
    func getAllVideos() -> [Video] {
        
        DDLogDebug("Getting videos from core data")
        guard let context = Thread.isMainThread ? self.persistentContainer?.viewContext : self.backgroundContext else {
            DDLogError("Error getting context in getAllVideos")
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        fetchRequest.predicate = NSPredicate.init(format: "(url CONTAINS[cd] %@ OR url CONTAINS[cd] %@) AND id.length > 0", "youtube.com", "youtu.be")
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "created_at", ascending: true)]
        
        do {
            
            let videos = try context.fetch(fetchRequest)
            return videos as! [Video]
            
        } catch let error as NSError {
            DDLogError("Error fetching videos: " + error.localizedDescription)
        }
        return []
    }
    
    // MARK: - Network Refresh
    
    func refreshVideos() {
        cancelRefresh()
        
        DDLogDebug("refreshing videos from network")
        
        guard var urlcomp = URLComponents(string: "https://www.reddit.com/r/" + UserDefaults.standard.getSubreddit() + "/hot.json") else { return }
        urlcomp.queryItems = [
            URLQueryItem.init(name: "limit", value: "100")
        ]
        
        guard let url = urlcomp.url else {  return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        task = URLSession.shared.dataTask(with: request) { data, response, error in
            DDLogDebug("In data task")
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    DDLogError("Error in data task response \(String(describing: error))")
                    self.delegate?.finishedRefresh(error: error)
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                DDLogError("statusCode should be 2xx, but is \(response.statusCode)")
                DDLogError("response = \(response)")
                self.delegate?.finishedRefresh(error: nil)
                return
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
                
                //We're not going to use the return of parse() here because we want to filter out the same videos the ViewController does (ie non-youtube videos).  If we work off different sets of data the update calls for the thumbnail data have a chance of crashing
                _ = self.parse(try JSONSerialization.data(withJSONObject: entries, options: .init()), entity: [Video].self)
                let videos = self.getAllVideos()
                
                let videoIds : [NSManagedObjectID] = videos.map{(video) -> NSManagedObjectID in
                    return video.objectID
                }
                
                DDLogDebug("Finished parsing videos - calling finishedRefresh")
                self.delegate?.finishedRefresh(error: nil)
                
                DDLogDebug("Cancelling download thumbnails work item")
                self.downloadThumbnailsWorkItem?.cancel()

                self.downloadThumbnailsWorkItem = DispatchWorkItem(block: {
                    DDLogDebug("Download thumbnails work item began")
                    self.downloadThumbnails(videoIds)
                })

                DDLogDebug("Starting new download thumbnails work item")
                if self.downloadThumbnailsWorkItem != nil {
                    self.serialQueue.async(execute: self.downloadThumbnailsWorkItem!)
                }
                
            } catch let error {
                DDLogError("Error in data task try catch \(error)")
                self.delegate?.finishedRefresh(error: error)
            }
        }
        
        DDLogDebug("Starting data task to fetch videos over network")
        task?.resume()
    }
    
    func downloadThumbnails(_ videoIds : [NSManagedObjectID]) {
        DDLogDebug("downloadThumbnails")
        var i = 0
        guard let managedObjectContext = self.backgroundContext else {
            DDLogError("Error fetching context")
            return
        }
        var indexPaths : [IndexPath] = []
        
        for videoID in videoIds {
            
            do {
                //The docs for .object() say that it always returns an object, so we should be okay force casting this
                let video = managedObjectContext.object(with: videoID) as! Video
                
                //Try downloading the thumbnail from the reddit object, but if that doesn't exist, just grab it from Youtube
                if let url = URL.init(string: video.thumbnail) {
                    video.thumbnail_data = try NSData.init(contentsOf: url) as Data
                } else if let url = URL.init(string: "https://img.youtube.com/vi/\(video.id)/1.jpg") {
                    video.thumbnail_data = try NSData.init(contentsOf: url) as Data
                }
                
                //Add this video indexPath to our list to update 
                indexPaths.append(IndexPath(row: i, section: 0))
                
            } catch {
                //Just continue on to the next one
                DDLogError("Failed to download thumbnail for index \(i)")
            }
            
            i += 1
            if i % 5 == 0 {
                
                do {
                    DDLogDebug("Saving context after 5 thumbnails")
                    try managedObjectContext.save()
                    
                } catch let error {
                    DDLogError("Error trying to save context while downloading thumbnails: \(error)")
                }
                
                DDLogDebug("Updating thumbnails after 5 processed")
                self.delegate?.updateThumbnails(indexPaths: indexPaths)
                
                indexPaths.removeAll()
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch let error {
            DDLogError("Error trying to perform final save context while downloading thumbnails: \(error)")
        }
    }
    
    // MARK: - Parsing
    
    func parse<T: Decodable> (_ jsonData: Data, entity: T.Type) -> T? {
        DDLogDebug("Parsing json data")
        do {
            guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext else {
                fatalError("Failed to retrieve context")
            }
            
            // Parse JSON data
            guard let managedObjectContext = self.backgroundContext else {
                return nil
            }
            
            managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            
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
