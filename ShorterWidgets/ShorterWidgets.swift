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
                Text( entry.postedDate.formatted(date: .abbreviated, time: .omitted) )
                Text( entry.fullName )
                    .textCase(.uppercase)
                    .font(.caption2)
                    .opacity(0.8)
            }
            .padding([.trailing, .bottom], 5)
        }
        .background {
            if let imageData = entry.imageData {
                let uiImage = PhotoManager.decodeUIImage(from: imageData) ?? UIImage(named: "BigSur")
                    
                let image = Image(uiImage: uiImage!.resized(toWidth: 800, isOpaque: true)!)
                
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .padding(-15)
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
        let uiImage = UIImage(named: "BigSur")
        let imageData = PhotoManager.encodeImage(uiImage)
        
        return FriendWidgetEntry(date: .now,
                          title: "Place Holder",
                          fullName: "Brian Masse",
                          emoji: "🫥",
                          imageData: imageData,
                          postedDate: .now)
    }
    
    private func makeEmptyWidgetEntry(name: String) -> FriendWidgetEntry {
        .init(date: .now,
              title: "Waiting on Post",
              fullName: name,
              emoji: "🙂‍↔️",
              imageData: nil,
              postedDate: .now)
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
        
        var entry: FriendWidgetEntry? = nil
        
        if let post = await WidgetRealmManger.shared.retrieveImageData(from: friend.id) {
            
            entry = FriendWidgetEntry(date: .now,
                                          title: post.title,
                                          fullName: name,
                                          emoji: post.emoji,
                                          imageData: post.imageData,
                                          postedDate: post.postedDate)
        }
    
        let finalEntry: FriendWidgetEntry = entry ?? makeEmptyWidgetEntry(name: name)
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
