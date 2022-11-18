//
//  YTWrapper.swift
//  gorb
//
//  Created by Niall Begley on 11/15/22.
//

import YouTubeiOSPlayerHelper
import SwiftUI

struct YTWrapper: UIViewRepresentable {

    let playerView = YTPlayerView()
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        
    }

    func makeUIView(context: Context) -> YTPlayerView {
//        playerView.load(withVideoId: videoID)
        return playerView
    }

}

struct YoutubeView: View {
    var body: some View {
        YTWrapper()
    }
}
