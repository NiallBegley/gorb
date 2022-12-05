//
//  Video.swift
//  gorb
//
//  Created by Niall Begley on 11/14/22.
//
import UIKit
import CoreData
import CocoaLumberjack

struct VideoProperties: Decodable {

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case thumbnail
        case num_comments
        case ups
        case permalink
        case id
    }

    var url : String
    var title : String
    var num_comments : Int
    var ups : Int
    var permalink : String
    var thumbnail : String
    var id: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        self.title = try container.decode(String.self, forKey: .title)

        self.ups = try container.decode(Int.self, forKey: .ups)
        self.num_comments = try container.decode(Int.self, forKey: .ups)
        self.permalink = try container.decode(String.self, forKey: .permalink)
        self.thumbnail = try container.decode(String.self, forKey: .thumbnail)
        self.id = try container.decode(String.self, forKey: .id)
    }

    var dictionaryValue: [String: Any] {
        [
            "url": url,
            "title": title,
            "num_comments": num_comments,
            "ups": ups,
            "permalink": permalink,
            "thumbnail": thumbnail,
            "id": id,
        ]
    }
}

class Video: NSManagedObject, Identifiable {


    @NSManaged var url : String
    @NSManaged var title : String
    @NSManaged var id : String
    @NSManaged var video_id: String
    @NSManaged var args : String
    @NSManaged var num_comments : Int
    @NSManaged var ups : Int
    @NSManaged var permalink : String
    @NSManaged var thumbnail_data : Data
    @NSManaged var thumbnail : String
    @NSManaged var created_at : Date


    func update(from videoProperties: VideoProperties) throws {
        let dictionary = videoProperties.dictionaryValue
        guard let newUrl = dictionary["url"] as? String,
              let newTitle = dictionary["title"] as? String,
              let newThumbnail = dictionary["thumbnail"] as? String,
              let newComments = dictionary["num_comments"] as? Int,
              let newUps = dictionary["ups"] as? Int,
              let newPermalink = dictionary["permalink"] as? String,
              let newId = dictionary["id"] as? String
        else {
            fatalError()
        }

        self.url = newUrl
        self.title = convertSpecialCharacters(string: newTitle)
        self.num_comments = newComments
        self.ups = newUps
        self.permalink = newPermalink
        self.thumbnail = newThumbnail
        self.video_id = extractYoutubeID(from: url)
        self.created_at = Date()
        self.id = newId

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

extension Video {

    static let preview: Video = {
        let video = Video.makePreviews(count: 1)
        return video[0]
    }()

    static func makePreviews(count: Int) -> [Video] {
        var videos = [Video]()
        let viewContext = VideosProvider.preview.container.viewContext
        for _ in 0..<count {
            let video = Video(context: viewContext)

            video.url = "https://youtu.be/C6nAxiym9oc"
            video.title = "Here's a youtuber callin…before the FTX collapse"
            video.num_comments = 50
            video.ups = 15618
            video.permalink = "/r/videos/comments/yvci0h/heres_a_youtuber_calling_out_sam_bankmanfried_on/"
            video.thumbnail = "https://b.thumbs.redditmedia.com/eJecGMIF494Ggl42RyDroKD5p-x6pVFQiWwO4GcwUzk.jpg"
            videos.append(video)
        }
        return videos
    }
}
