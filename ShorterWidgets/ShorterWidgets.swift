//
//  ShorterWidgets.swift
//  ShorterWidgets
//
//  Created by Brian Masse on 6/21/24.
//

import WidgetKit
import SwiftUI

let suiteName = "group.com.shorter.BrianMasse"

//MARK: Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀", imageData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        
        let entry = SimpleEntry(date: Date(), emoji: "😀", imageData: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            
            var imageData: Data? = nil
            
            if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
                
                if let data = defaults.data(forKey: WidgetKeys.imageWidgetImageDataKey) {
                    
                    imageData = data
                }
                
            }
            
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "value", imageData: imageData)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

//MARK: TimeLine Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let imageData: Data?
}

//MARK: WidgetView
struct ShorterWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            if let imageData = entry.imageData {
                if let uiImage = PhotoManager.decodeUIImage(from: imageData) {
                    
                    let image = Image(uiImage: uiImage.resized(toWidth: 800, isOpaque: true)!)
                    
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                }
            }
            
            VStack {
                Text("Time:")
                Text(entry.date, style: .time)
                
                Text("Emoji:")
                Text(entry.emoji)
            }
        }
    }
}

struct SelectFriendProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, emoji: "placeholder", imageData: nil)
    }
    
    func snapshot(for configuration: SelectFriendIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: .now, emoji: "snapshot", imageData: nil)
    }
    
    func timeline(for configuration: SelectFriendIntent, in context: Context) async -> Timeline<SimpleEntry> {
        
        let friend = configuration.friend
        print( friend.imageData )
        
        let simpleEntry = SimpleEntry(date: .now, emoji: configuration.friend.firstName, imageData: friend.imageData)
        
        let timeline = Timeline(entries: [simpleEntry], policy: .never)
        return timeline
        
    }
    
    
}

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

//#Preview(as: .systemSmall) {
//    ShorterWidgets()
//} timeline: {
//    SimpleEntry(date: .now, emoji: "😀", imageData: nil)
//    SimpleEntry(date: .now, emoji: "🤩", imageData: nil)
//}
