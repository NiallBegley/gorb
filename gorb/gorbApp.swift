//
//  gorbApp.swift
//  gorb
//
//  Created by Niall Begley on 11/14/22.
//

import SwiftUI
import CocoaLumberjackSwift

@main
struct gorbApp: App {
    let persistenceController = VideosProvider.shared
    @State var videosViewModel = VideoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(videosViewModel)
        }
    }
}
