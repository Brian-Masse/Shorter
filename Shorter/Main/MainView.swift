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

struct MainView: View {
    
    @State private var showingCreatePostView: Bool = false
    
    @ObservedResults( ShorterPost.self ) var posts
    
    
    
    var body: some View {
        
        VStack {
            HStack {
                
                Image(systemName: "pencil")
                
                Spacer()
                
                Text( "Shorter" )
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Image(systemName: "plus")
                    .onTapGesture { showingCreatePostView = true }
            }
            
            Spacer()
            
            ForEach( posts ) { post in
                
                HStack {
                    Text(post.title)
                    
                    Spacer()
                    
                    if let image = PhotoManager.decodeImage(from: post.imageData) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                    }
                }
                .onTapGesture {
                    if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
                        
                        if let uiImage = PhotoManager.decodeUIImage(from: post.imageData) {
                            let imageData = PhotoManager.encodeImage(uiImage, compressionQuality: 0.5)
                            
                            defaults.setValue( post.title, forKey: WidgetKeys.imageWidgetDataKey )
                            
                            defaults.setValue( imageData, forKey: WidgetKeys.imageWidgetImageDataKey)
                            
                            WidgetCenter.shared.reloadTimelines(ofKind: "ShorterWidgets")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreatePostView) {
            CreatePostView()
        }
    }
}

struct CreatePostView: View {
    
    @State private var showingImagePicker: Bool = false
    
    @State private var title: String = ""
    
    private func submit() {
        if title.isEmpty { return }
        
        let imageData = PhotoManager.encodeImage(self.image)
        
        let post = ShorterPost(ownerId: ShorterModel.ownerId, title: title, data: imageData)
        
        RealmManager.addObject( post )
    }
    
    @State var image: UIImage? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text("Create Post")
                .font(.title2)
                .bold()
            
            TextField("title", text: $title, prompt: Text( "title" ))
            
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
