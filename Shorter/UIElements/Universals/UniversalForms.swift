//
//  UniversalForms.swift
//  Shorter
//
//  Created by Brian Masse on 6/25/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: StyledTextField
struct StyledTextField: View {
    
    let title: String
    let prompt: String
    let binding: Binding<String>
    let multiLine: Bool
    let privateField: Bool
    let clearable: Bool
    
    init( title: String, prompt: String = "", binding: Binding<String>, multiLine: Bool = false, privateField: Bool = false, clearable: Bool = false ) {
        self.title = title
        self.privateField = privateField
        self.binding = binding
        self.prompt = prompt
        self.multiLine = multiLine
        self.clearable = clearable
    }
    
    @ViewBuilder
    private func makeTextField() -> some View {
        if privateField {
            SecureField(prompt, text: binding)
        } else {
            if multiLine {
                TextField(prompt, text: binding, axis: .vertical)
            } else {
                TextField(prompt, text: binding)
            }
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState var focused: Bool
    @State var showingClearButton: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            if !title.isEmpty {
                Text( title )
                    .font(.title3)
                    .bold()
                    .padding(.trailing)
            }
            
            makeTextField()
                .focused($focused)
                .lineLimit(1...)
                .frame(maxWidth: .infinity)
                .padding( .trailing, 5 )
                .tint(Colors.getAccent(from: colorScheme) )
                .rectangularBackground(style: .transparent)
                .cardWithDepth()
            
                .onChange(of: self.focused) { value, _ in
                    withAnimation { self.showingClearButton = value }
                }
            
            if showingClearButton && clearable && !binding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Text( "clear" )
                            .font(.caption)
                        Image(systemName: "xmark")
                        Spacer()
                        
                    }
                    .rectangularBackground(style: .secondary)
                    .onTapGesture {
                        withAnimation { binding.wrappedValue = "" }
                    }
                }.transition(.opacity)
            }
        }
    }
}

//MARK: Styled Photo Picker
struct StyledPhotoPicker: View {
    
    @ObservedObject var photoManager = PhotoManager.shared
    
    let description: String
    let maxPhotoWidth: CGFloat
    let shouldCrop: Bool
    
    init(_ image: Binding<UIImage?>, description: String, maxPhotoWidth: CGFloat = 120, shouldCrop: Bool = true) {
        self._croppedImage = image
        self.description = description
        self.maxPhotoWidth = maxPhotoWidth
        self.shouldCrop = shouldCrop
    }
    
    @State private var showPhotoPicker: Bool = false
    @State private var showCropView: Bool = false
    
    @Binding var croppedImage: UIImage?
    
    @ViewBuilder
    private func makePhotoPicker<C: View>(@ViewBuilder contentBuilder: () -> C) -> some View {
        Menu {
            ContextMenuButton("from camera", icon: "camera.metering.multispot") {
                photoManager.sourceType = .camera
                self.showPhotoPicker = true
            }
            ContextMenuButton("from photo library", icon: "photo.on.rectangle") {
                photoManager.sourceType = .photoLibrary
                self.showPhotoPicker = true
            }
            
        } label: { contentBuilder()
        }.buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func makeFullImageUploader() -> some View {
        UniversalButton {
            HStack {
                Spacer()
                
                VStack {
                    Text( "Upload Image" )
                    ResizableIcon("cable.connector", size: Constants.UISubHeaderTextSize)
                }
                Spacer()
            }.rectangularBackground(style: .transparent)
            
        } action: { showPhotoPicker = true }
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 7) {
            
            HStack {
                Text("Choose a Profile Picture")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                if let _ = croppedImage {
                    makePhotoPicker {
                        IconButton("photo.on.rectangle.angled") { }
                    }
                    
                    if shouldCrop {
                        IconButton("crop.rotate") {
                            showCropView = true
                        }
                    }
                }
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.callout)
                    .padding(.bottom)
            }
            
            if let image = croppedImage {
                HStack {
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(Constants.UIDefaultCornerRadius)
                        .frame(maxWidth: maxPhotoWidth)
                        .clipShape(Circle())
                        .padding(.top)
                    Spacer()
                }
                
                
            } else {
                makePhotoPicker { makeFullImageUploader() }
            }
        }
        
        .sheet(isPresented: $showPhotoPicker) {
            ImagePickerView(sourceType: photoManager.sourceType) { uiImage in
                photoManager.storedImage = uiImage
                
                if shouldCrop { showCropView = true }
                else { self.croppedImage = uiImage }
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCropView) {
            let image = Image(uiImage: photoManager.storedImage!)
            CropView(image: image) { image in
                self.croppedImage = image
            }
        }
    }
}

//MARK: CropView
@MainActor
fileprivate struct CropView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let image: Image
    
    let onCrop: ( UIImage ) -> Void
    
    init( image: Image, onCrop: @escaping ( UIImage ) -> Void = { _ in } ) {
        self.image = image
        self.onCrop = onCrop
    }
    
//    MARK: CropView Vars
    @State private var moving: Bool = false
    @State private var offset: CGSize = .zero
    @State private var priorOffset: CGSize = .zero
    
    @State private var scale: CGFloat = 1
    @State private var priorScale: CGFloat = 0
    
    @State private var showingGrid: Bool = true
    
    private func saveImage(geo: GeometryProxy) {
        let renderer = ImageRenderer(content: makeImage(showGrid: false, geo: geo) )
        renderer.proposedSize = ProposedViewSize(CGSize( width: geo.size.width * 4, height: geo.size.width * 4 ))
        
        let image = renderer.uiImage!
        
        self.onCrop( image )
        
        dismiss()
    }
    
    //    MARK: CropView Gestures
    private func moveGesture(geo: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                self.moving = true
                self.offset = CGSize(width: value.translation.width + self.priorOffset.width,
                                     height: value.translation.height + self.priorOffset.height)
            }
            .onEnded { value in self.moving = false }
    }
    
    private var resizeGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                self.scale = max(1, value + priorScale)
                self.moving = true
            }
            .onEnded { value in
                self.priorScale = self.scale - 1
                self.moving = false
            }
    }
    
//    Geo represents the size of the croppedSpace
//    imageRect represents the size of the image
    private func constrainOffset(geo: GeometryProxy, imageRect: CGSize) -> CGSize {
        let baseHorizontalOverflow = (imageRect.width * scale - geo.size.width) / 2
        let baseVerticalOverflow = (imageRect.height * scale - geo.size.width) / 2
        
        let xMin =  min( offset.width, baseHorizontalOverflow)
        let x =     max( xMin, -baseHorizontalOverflow )

        let yMin =  min( offset.height, baseVerticalOverflow )
        let y =     max( yMin, -baseVerticalOverflow )
        
        return CGSize( width: x, height: y )
        
    }
    
//    MARK: CropView Headers
    @ViewBuilder
    private func makeHeader(geo: GeometryProxy) -> some View {
        HStack {
            IconButton("xmark") { dismiss() }
            
            Spacer()
            
            Text( "Crop" )
                .font(.title2)
                .bold()
            
            Spacer()
            
            IconButton("checkmark") { saveImage(geo: geo) }
        }
    }
    
    @ViewBuilder
    private func makeGrid(geo: GeometryProxy) -> some View {
        let cellCount = 5
        let space = geo.size.width / CGFloat(cellCount)
        
        ZStack(alignment: .topLeading) {
            ForEach(1...cellCount, id: \.self) { i in
                Divider(vertical: true, strokeWidth: 1)
                    .offset(x: CGFloat(i) * space)
            }
            ForEach(1...cellCount, id: \.self) { i in
                Divider(strokeWidth: 1)
                    .offset(y: CGFloat(i) * space)
            }
        }
    }
    
    @ViewBuilder
    private func makeImage(showGrid: Bool, geo: GeometryProxy) -> some View {
        ZStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay { GeometryReader { imageGeo in
                    Color.clear
                        .onChange(of: moving) { oldValue, newValue in
                            if !newValue { withAnimation {
                                self.offset = constrainOffset(geo: geo, imageRect: imageGeo.size )
                                self.priorOffset = self.offset
                            }}
                        }
                }}
                .scaleEffect(self.scale)
                .offset(self.offset)
                .frame(width: geo.size.width, height: geo.size.width)
            
            makeGrid(geo: geo)
                .opacity(showGrid ? 0.3 : 0)
                .frame(width: geo.size.width, height: geo.size.width)
        }
        .background(.black.opacity(0.2))
        .gesture(moveGesture(geo: geo))
        .gesture(resizeGesture)
        .clipShape(Circle())
        .contentShape(Circle())
    }
    
    @ViewBuilder
    private func makeControlButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        
        UniversalButton {
            VStack {
                Image(systemName: icon)
                    .padding(.bottom, 7)
                Text( title )
            }
            .frame(width: 120)
            .rectangularBackground(style: .primary)
        } action: { action() }

    }
    
    @ViewBuilder
    private func makeControlButtons() -> some View {
        HStack {
            Spacer()
            
            makeControlButton(title: "Reset Edits", icon: "circle.dotted") {
                self.scale = 1
                self.offset = .zero
            }
        
            makeControlButton(title: "Show Grid", icon: showingGrid ? "square.3.layers.3d.down.left" : "square.3.layers.3d.down.left.slash") {
                self.showingGrid.toggle()
            }
            
            Spacer()
        }
    }
    
//    MARK: CropView Body
    var body: some View {
        GeometryReader { geo in
            VStack {
                makeHeader(geo: geo)
                    .zIndex(100)

                Spacer()
                
                makeImage(showGrid: showingGrid, geo: geo)
                    .shadow(radius: 30)
                    .zIndex(1)
                
                Spacer()
                
                makeControlButtons()
                
                Spacer()
            }
        }
        .padding()
        .background(.black.opacity(0.3))
        .universalImageBackground(image)
    }
}
