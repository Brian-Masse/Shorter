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
          postedDate: Date,
          showSignInScreen: Bool = false) {
        self.date = date
        self.title = title
        self.fullName = fullName
        self.emoji = emoji
        self.postedDate = postedDate
        self.imageData = imageData
        self.showSignInScreen = showSignInScreen
    }
    
    let date: Date

    let title: String
    let fullName: String
    let emoji: String
    let imageData: Data?
    let postedDate: Date
    let showSignInScreen: Bool
}

//MARK: WidgetView
struct ShorterWidgetsEntryView : View {
    var entry: FriendWidgetEntry
    
    @ViewBuilder
    private func makeRegularContent() -> some View {
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
    
    var body: some View {
        if entry.showSignInScreen {
            VStack {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                
                Text( "Sign In to See your Friends' posts" )
            }
            .font(.title)
            .bold()
            
        } else {
            makeRegularContent()
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
    
    private func makeSignInEntry() -> FriendWidgetEntry {
        .init(title: "", fullName: "", emoji: "", postedDate: .now, showSignInScreen: true)
    }
    
    private func compressImageData(_ data: Data) -> Data {
        return PhotoManager.encodeImage(PhotoManager.decodeUIImage(from: data), compressionQuality: 1, in: 300)
    }
    
    @MainActor
    private func makePostEntry(from id: String, name: String) async -> FriendWidgetEntry? {
        if let post = await WidgetRealmManger().retrieveImageData(from: id) {
            
            return FriendWidgetEntry(date: .now + ( 60 * 60 ),
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
    
//    MARK: Report Memory
    func report_memory() -> UInt64 {
        var info = mach_task_basic_info()
        let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
    
    @MainActor
    func timeline(for configuration: SelectFriendIntent, in context: Context) async -> Timeline<FriendWidgetEntry> {
        
        let friend = configuration.friend
        
//        if friend.id == "sign in" {
//            let entry = makeSignInEntry()
//            return Timeline(entries: [entry], policy: .never)
//        }
        
        let name = "\(friend.firstName) \(friend.lastName)"
        
        let entry = await makePostEntry(from: friend.id, name: name)
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
                      postedDate: .now,
                      showSignInScreen: true)
}
