//
//  ShorterWidgets.swift
//  ShorterWidgets
//
//  Created by Brian Masse on 6/21/24.
//

import WidgetKit
import SwiftUI

//MARK: TimeLine Entry
struct FriendWidgetEntry: TimelineEntry {
    init( date: Date = .now,
          title: String,
          fullName: String,
          emoji: String,
          imageData: Data? = nil,
          postedDate: Date) {
        self.date = date
        self.title = title
        self.fullName = fullName
        self.emoji = emoji
        self.postedDate = postedDate
        self.imageData = imageData
    }
    
    let date: Date

    let title: String
    let fullName: String
    let emoji: String
    let imageData: Data?
    let postedDate: Date
}

//MARK: WidgetView
struct ShorterWidgetsEntryView : View {
    var entry: FriendWidgetEntry
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            LinearGradient(colors: [.black, .clear],
                           startPoint: .bottom,
                           endPoint: .top)
            .opacity(0.7)
            .padding(-15)
            .padding(.top, 70)
            
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Text(entry.title)
                        .bold()
                        .font(.title2)
                        .lineLimit(1)
                    Text(entry.emoji)
                    
                    Spacer()
                }
                Text( entry.date.formatted(date: .omitted, time: .complete) )
                Text( entry.fullName )
                    .textCase(.uppercase)
                    .font(.caption2)
                    .opacity(0.8)
            }
            .padding([.trailing, .bottom], 5)
        }
        .background {
            if entry.imageData == nil { Image( "BigSur" ) }
            else {
                let image = Image(uiImage: PhotoManager.decodeUIImage(from: entry.imageData!)! )
                
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .clipped()
//                    .padding(-15)
            }
        }
        .foregroundStyle(.white)
        .padding(-5)
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

//MARK: Timeline Provider
struct SelectFriendProvider: AppIntentTimelineProvider {

    private func makePlaceHolderWidgetEntry() -> FriendWidgetEntry {
        return FriendWidgetEntry(date: .now,
                          title: "Place Holder",
                          fullName: "Brian Masse",
                          emoji: "🫥",
                          imageData: nil,
                          postedDate: .now)
    }
    
    private func makeEmptyWidgetEntry(name: String) -> FriendWidgetEntry {

        .init(date: .now + ( 60 * 6 ) ,
              title: "Waiting on Post",
              fullName: name,
              emoji: "🙂‍↔️",
              imageData: nil,
              postedDate: .now)
    }
    
    private func compressImageData(_ data: Data) -> Data {
        if data.count < 600000 {
            return data
        }

        let uiImage = PhotoManager.decodeUIImage(from: data)
        return PhotoManager.encodeImage(uiImage, compressionQuality: 0, in: 100)
    }
    
    @MainActor
    private func makePostEntry(from id: String, name: String) async -> FriendWidgetEntry? {
        if let post = await WidgetRealmManger().retrieveImageData(from: id) {
            
            return FriendWidgetEntry(date: .now,
                                    title: post.title,
                                    fullName: name,
                                    emoji: post.emoji,
                                    imageData: compressImageData(post.imageData),
                                    postedDate: post.postedDate)
        }
        
        return nil
    }
    
    func placeholder(in context: Context) -> FriendWidgetEntry {
        makePlaceHolderWidgetEntry()
    }
    
    func snapshot(for configuration: SelectFriendIntent, in context: Context) async -> FriendWidgetEntry {
        makePlaceHolderWidgetEntry()
    }
    
    @MainActor
    func timeline(for configuration: SelectFriendIntent, in context: Context) async -> Timeline<FriendWidgetEntry> {
        
        let friend = configuration.friend
        let name = "\(friend.firstName) \(friend.lastName)"
        
        let entry = await makePostEntry(from: friend.id, name: name)
        let finalEntry: FriendWidgetEntry = entry ?? makeEmptyWidgetEntry(name: name)

        print( "MAKING TIMELINE" )
        
        let timeline = Timeline(entries: [finalEntry], policy: .atEnd)
        return timeline
        
    }
}

//MARK: ShorterWidgets
struct ShorterWidgets: Widget {
    let kind: String = "ShorterWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: SelectFriendIntent.self,
                               provider: SelectFriendProvider()) { entry in
            ShorterWidgetsEntryView(entry: entry)
            
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall, .systemLarge, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ShorterWidgets()
    
} timeline: {
    let image = UIImage(named: "Goats")
    let data = PhotoManager.encodeImage(image,
                                        compressionQuality: 0.5)
    
    FriendWidgetEntry(date: .now,
                      title: "Post Title",
                      fullName: "Brian Masse",
                      emoji: "🫥",
                      imageData: data,
                      postedDate: .now)
}
