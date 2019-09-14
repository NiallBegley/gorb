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
    func updateProgress(percentage : Float)

}
class VideoController: NSObject {

    var persistentContainer: NSPersistentContainer?
    weak var delegate : VideoControllerDelegate?
    
    init(container: NSPersistentContainer) {
        self.persistentContainer = container
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
        
        guard let context = self.persistentContainer?.viewContext else {
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        fetchRequest.predicate = NSPredicate.init(format: "url CONTAINS[cd] %@ OR url CONTAINS[cd] %@", "youtube.com", "youtu.be")
        
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
        guard var urlcomp = URLComponents(string: "https://www.reddit.com/r/videos/hot.json") else { return }
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
                
                var count = 0
                
                for entry in children {
                    if let videoData = entry["data"] {
                        _ = self.parse(try JSONSerialization.data(withJSONObject: videoData, options: .init()), entity: Video.self)
                        count += 1
                        self.delegate?.updateProgress(percentage: Float(count) / Float(children.count))
                    }
                }
                
                self.delegate?.finishedRefresh(error: nil)
                
            } catch let error {
                print(error)
                self.delegate?.finishedRefresh(error: error)
            }
        }
        
        task.resume()
    }
    
    func parse<T: Decodable> (_ jsonData: Data, entity: T.Type) -> T? {
        do {
            guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext else {
                fatalError("Failed to retrieve context")
            }
            
            // Parse JSON data
            guard let managedObjectContext = persistentContainer?.newBackgroundContext() else {
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
