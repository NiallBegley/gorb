//
//  SettingsView.swift
//  gorb
//
//  Created by Niall Begley on 11/27/22.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @ObservedObject var userSettings = UserSettings.shared

    var body: some View {
        VStack{

//            NavigationView {
                List {
                    Toggle(isOn: $userSettings.autoplay) {
                        Text("Autoplay:")
                    }
                    NavigationLink(destination: SubredditPicker()) {
                        HStack {
                            Text("Subreddit:")
                            Spacer()
                            Text(userSettings.subreddit.name)
                        }
                    }
                }
                .listStyle(.plain)
                Text("Select an item")
            }
//        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//
//    }
//}
