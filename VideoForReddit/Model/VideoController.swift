//
//  VideoController.swift
//  VideoForReddit
//
//  Created by Niall on 9/11/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit
import CoreData

protocol VideoControllerDelegate : class {
    func finishedRefresh(error: Error?)
    func updateThumbnails(indexPaths : [IndexPath])
}
class VideoController: NSObject {

    var persistentContainer: NSPersistentContainer?
    weak var delegate : VideoControllerDelegate?
    let serialQueue = DispatchQueue(label: "thumbnailqueue")
    let backgroundContext : NSManagedObjectContext?
    
    init(container: NSPersistentContainer) {
        backgroundContext = container.newBackgroundContext()
        super.init()
        
        self.persistentContainer = container
        
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextUpdated(_:)), name: .NSManagedObjectContextDidSave, object: backgroundContext)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func backgroundContextUpdated(_ notification : NSNotification) {
        self.persistentContainer?.viewContext.mergeChanges(fromContextDidSave: notification as Notification)
    }
    
    // MARK: - Deletion
    
    func deleteAll() -> Bool {
        guard let context = self.persistentContainer?.viewContext else {
            return false
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("Error deleting all Videos: " + error.localizedDescription)
            return false
        }
        
        return true
    }
    
    // MARK: - Fetching Existing
    
    func getAllVideos() -> [Video] {
        
        
        guard let context = Thread.isMainThread ? self.persistentContainer?.viewContext : self.backgroundContext else {
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        fetchRequest.predicate = NSPredicate.init(format: "(url CONTAINS[cd] %@ OR url CONTAINS[cd] %@) AND id.length > 0", "youtube.com", "youtu.be")
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "created_at", ascending: true)]
        
        do {
            
            let videos = try context.fetch(fetchRequest)
            return videos as! [Video]
            
        } catch let error as NSError {
            print("Error fetching videos: " + error.localizedDescription)
        }
        return []
    }
    
    // MARK: - Network Refresh
    
    func refreshVideos() {
        guard var urlcomp = URLComponents(string: "https://www.reddit.com/r/" + UserDefaults.standard.getSubreddit() + "/hot.json") else { return }
        urlcomp.queryItems = [
            URLQueryItem.init(name: "limit", value: "100")
        ]
        
        guard let url = urlcomp.url else {  return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    self.delegate?.finishedRefresh(error: error)
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                self.delegate?.finishedRefresh(error: nil)
                return
            }
            
            do {
                guard let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject],
                    let data = jsonData["data"],
                    let children = data["children"] as? [[String:AnyObject]] else { return }
                
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
                
                self.delegate?.finishedRefresh(error: nil)
                
                self.serialQueue.async {
                    self.downloadThumbnails(videoIds)
                }
            
                
            } catch let error {
                print(error)
                self.delegate?.finishedRefresh(error: error)
            }
        }
        
        task.resume()
    }
    
    func downloadThumbnails(_ videoIds : [NSManagedObjectID]) {
        var i = 0
        guard let managedObjectContext = self.backgroundContext else {
            return
        }
        var indexPaths : [IndexPath] = []
        
        for videoID in videoIds {
            
            do {
                //The docs for .object() say that it always returns an object, so we should be okay force casting this
                let video = managedObjectContext.object(with: videoID) as! Video
                
                if let url = URL.init(string: video.thumbnail) {
                    video.thumbnail_data = try NSData.init(contentsOf: url) as Data
                    //                                print("downloaded thumbnail for " + video.title)
                }
                
                indexPaths.append(IndexPath(row: i, section: 0))
                
                i += 1
                if i % 5 == 0 {
                    
                    do {
                        try managedObjectContext.save()
                        
                    } catch let error {
                        print(error)
                    }
                    
                    self.delegate?.updateThumbnails(indexPaths: indexPaths)
                    
                    indexPaths.removeAll()
                }
            } catch {
                //Just continue on to the next one
                print("Failed to download thumbnail")
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch let error {
            print(error)
        }
    }
    
    func parse<T: Decodable> (_ jsonData: Data, entity: T.Type) -> T? {
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
            let entities = try decoder.decode(entity, from: jsonData)
            
            try managedObjectContext.save()
            
            return entities
        } catch let error {
            print(error)
            return nil
        }
    }
}
