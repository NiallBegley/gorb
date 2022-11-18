//
//  ContentView.swift
//  gorb
//
//  Created by Niall Begley on 11/14/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var videosViewModel : VideoViewModel
    private let player = YTWrapper()
    var body: some View {
        VStack{
            player
            NavigationView {
                List {
                    ForEach(videosViewModel.videos) { item in
                        VideoCell(video: item).onTapGesture {
                            player.playerView.load(withVideoId: item.id)
                        }
                    }
                }
                .listStyle(.plain)
                Text("Select an item")
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
