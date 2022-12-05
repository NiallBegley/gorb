//
//  SubredditPicker.swift
//  gorb
//
//  Created by Niall Begley on 12/4/22.
//

import SwiftUI

struct SubredditPicker: View {
    @ObservedObject var userSettings = UserSettings.shared
    @State var selection: Subreddit?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var videoViewModel: VideoViewModel
    var body: some View {
        List($userSettings.subreddits, id: \.id, selection: $selection) { subreddit in
            HStack {
                Text(subreddit.name.wrappedValue)
                Spacer()
                if let selection,
                    selection.id == subreddit.id {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                userSettings.subreddit = subreddit.wrappedValue
                videoViewModel.refreshVideos()

                self.presentationMode.wrappedValue.dismiss()
            }
        }.onAppear {
            self.selection = userSettings.subreddit
        }.textSelection(.enabled)
    }
}
