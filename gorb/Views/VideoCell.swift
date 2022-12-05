//
//  VideoCell.swift
//  gorb
//
//  Created by Niall Begley on 11/15/22.
//

import SwiftUI

struct VideoCell: View {
    @ObservedObject var video: Video

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: video.thumbnail)) { image in
                image.resizable()
            } placeholder: {
                Image("placeholder").resizable()
            }.frame(maxWidth: 66.0, maxHeight: 66.0)
            Text((video.title))
                .font(Font.system(size: 13.0))
                .truncationMode(.tail)

            Spacer()
            Button(action: { }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

struct VideoCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                VideoCell(video: Video.preview)
            }
        }
    }
}
