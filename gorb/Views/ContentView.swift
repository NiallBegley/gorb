//
//  ContentView.swift
//  gorb
//
//  Created by Niall Begley on 11/14/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject var userSettings = UserSettings.shared
    @EnvironmentObject var videosViewModel : VideoViewModel
    private let player = YTWrapper()
    
    var body: some View {
        NavigationView {
            VStack{
                player
                List {
                    Section {
                        ForEach(videosViewModel.videos) { item in
                            VideoCell(video: item).onTapGesture {
                                player.playerView.load(withVideoId: item.id)
                            }
                        }
                    } header: {
                        HStack {
                            Text(userSettings.subreddit.name)
                            Spacer()
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onAppear(perform: {

                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, VideosProvider.preview.container.viewContext)
    }
}
