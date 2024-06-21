//
//  PermissionManager.swift
//  Planter
//
//  Created by Brian Masse on 12/8/23.
//

import Foundation
import RealmSwift
import SwiftUI
import PhotosUI
import UIKit

//MARK: PhotoManager
//this class loads photos using the PhotosPicker SwiftUI component
//it can only load / process one image at a time. Once a UI has received the photo it is requesting (retrievedImage != nil)
//it should capture that, so this class can arbitrate that var for the next photo
class PhotoManager: ObservableObject {

    static func decodeImage(from data: Data) -> Image? {
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    static func encodeImage( _ image: UIImage? ) -> Data {
        if let image { return image.jpegData(compressionQuality: 0.9) ?? Data() }
        return Data()
    }
}

enum ImageError: Error {
    case transferError( String )
}

//MARK: Planter Images
struct PlanterImage: Transferable {
    
    let image: UIImage
    
    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw ImageError.transferError("Data Import Failed")
            }
            return PlanterImage(image: uiImage)
        }
    }
    
}


struct ImagePickerView: UIViewControllerRepresentable {
    private var sourceType: UIImagePickerController.SourceType
    private let onImagePicked: (UIImage) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    
    public init(sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping (UIImage) -> Void) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = self.sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: { self.presentationMode.wrappedValue.dismiss() },
            onImagePicked: self.onImagePicked
        )
    }
    
    final public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        private let onDismiss: () -> Void
        private let onImagePicked: (UIImage) -> Void
        
        init(onDismiss: @escaping () -> Void, onImagePicked: @escaping (UIImage) -> Void) {
            self.onDismiss = onDismiss
            self.onImagePicked = onImagePicked
        }
        
        public func imagePickerController(_ picker: UIImagePickerController,
                                          didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                self.onImagePicked(image)
            }
            self.onDismiss()
        }
        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            self.onDismiss()
        }
    }
}
