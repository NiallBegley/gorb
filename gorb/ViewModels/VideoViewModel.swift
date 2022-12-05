//
//  VideoViewModel.swift
//  gorb
//
//  Created by Niall Begley on 11/16/22.
//

import Foundation
import CocoaLumberjackSwift

class VideoViewModel: ObservableObject {
    @Published private(set) var videos: [Video] = []

    func refreshVideos() {
        videos.removeAll()
        
        Task {
            VideosProvider.shared.deleteAll()
            do {
                try await VideosProvider.shared.refreshVideos()
            } catch(let error) {
                print("\(error)")
            }

            let vids = await VideosProvider.shared.getAllVideos()
            DDLogInfo("Found \(vids.count) videos in core data")
            DispatchQueue.main.async {
                self.videos.append(contentsOf: vids)
            }
        }
    }

    init() {
        refreshVideos()
    }
}
