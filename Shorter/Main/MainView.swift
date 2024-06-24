//
//  MainView.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import SwiftUI
import RealmSwift
import WidgetKit
import UIUniversals

//MARK: MainView
struct MainView: View {
    
    @State private var showingCreatePostView: Bool = false
    
    @ObservedResults( ShorterPost.self ) var posts
    
//    MARK: Body
    var body: some View {
        ZStack(alignment: .top) {
            Text( "Shorter" )
                .font(.title2)
                .bold()
                .padding(.top, 7)
            
            ShorterPostsView(posts: Array( posts ))
            
        }
        .task {
            await NotificationManager.shared.loadStatus()
        }
    }
}

struct CreatePostView: View {
    
    @State private var showingImagePicker: Bool = false
    
    @State private var title: String = ""
    @State private var fullTitle: String = ""
    @State private var notes: String = ""
    
    @MainActor
    private func submit() {
        if title.isEmpty { return }
        
        let imageData = PhotoManager.encodeImage(self.image)
        
        let post = ShorterPost(ownerId: ShorterModel.ownerId,
                               authorName: ShorterModel.shared.profile!.fullName,
                               fullTitle: fullTitle,
                               title: title,
                               emoji: "🙂‍↔️",
                               notes: notes,
                               data: imageData)
        
        RealmManager.addObject( post )
    }
    
    @State var image: UIImage? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text("Create Post")
                .font(.title2)
                .bold()
            
            TextField("title", text: $title, prompt: Text( "title" ))
            TextField("fullTitle", text: $fullTitle, prompt: Text( "full title" ))
            TextField("notes", text: $notes, prompt: Text( "notes" ))
            
            Button(action: { showingImagePicker = true }) {
                Text( "image picker" )
            }
            
            Button(action: submit) {
                Text("submit")
            }
            
            Spacer()
            
            if let image = self.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
            }
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                self.image = image
            }
        }
    }
    
}

#Preview {
    MainView()
        .padding()
}
