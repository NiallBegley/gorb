//
//  Video.swift
//  VideoForReddit
//
//  Created by Niall on 9/9/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit
import CoreData

class Video: NSManagedObject,Codable {

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case thumbnail
        case num_comments
        case ups
        case permalink
    }
    
    @NSManaged var url : String
    @NSManaged var title : String
    @NSManaged var id : String
    @NSManaged var args : String
    @NSManaged var num_comments : Int
    @NSManaged var ups : Int
    @NSManaged var permalink : String
    @NSManaged var thumbnail_data : Data
    @NSManaged var thumbnail : String
    @NSManaged var created_at : Date
    
    required convenience init(from decoder: Decoder) throws {
        
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Video", in: managedObjectContext) else {
                fatalError("Failed to decode Video")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(String.self, forKey: .url)
        self.title = try container.decode(String.self, forKey: .title)
        self.title = convertSpecialCharacters(string: self.title)
        
        
        self.ups = try container.decode(Int.self, forKey: .ups)
        self.num_comments = try container.decode(Int.self, forKey: .ups)
        self.id = extractYoutubeID(from: url)
        self.permalink = try container.decode(String.self, forKey: .permalink)
        self.thumbnail = try container.decode(String.self, forKey: .thumbnail)
        self.created_at = Date()
        
    }
    
    func convertSpecialCharacters(string: String) -> String {
            var newString = string
            let char_dictionary = [
                "&amp;" : "&",
                "&lt;" : "<",
                "&gt;" : ">",
                "&quot;" : "\"",
                "&apos;" : "'"
            ];
            for (escaped_char, unescaped_char) in char_dictionary {
                newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.literal, range: nil)
            }
            return newString
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
       
    }
    
    func extractYoutubeID(from url: String) -> String
    {
        if let _ = url.range(of: "youtube.com", options: .caseInsensitive) {
            //Try and extract an ID out of a url of format https://youtube.com/watch?v=XXXXXX
            if let components  = URLComponents(string: url),
                let queryItems = components.queryItems,
                let id = queryItems.first(where: {$0.name == "v"})?.value {
                
                //let otherArgs = queryItems.removeAll(keepingCapacity: <#T##Bool#>)
                
                return id
            }
        }
        else if let _ = url.range(of: "youtu.be", options: .caseInsensitive) {
            let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"

            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: url.count)
            
            guard let result = regex?.firstMatch(in: url, range: range) else {
                return ""
            }
            
            return (url as NSString).substring(with: result.range)
        }
        //The URL isn't a youtube URL, so the id field is useless
        return ""
    }
}
