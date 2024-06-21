//
//  MessagingManager.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import SwiftUI
import UIKit
import Messages
import MessageUI

protocol MessagessViewDelegate {
    func messageCompletion (result: MessageComposeResult)
}

class Coordinator: NSObject, UINavigationControllerDelegate, MessagessViewDelegate {
    var parent: MessageUIView
    
    init(_ controller: MessageUIView) {
        self.parent = controller
    }
        
    func messageCompletion (result: MessageComposeResult) {
        self.parent.presentationMode.wrappedValue.dismiss ()
        self.parent.completion(result)
    }
}

class MessagesViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    var delegate: MessagessViewDelegate?
    var recipients: [String]?
    var body: String?
    
    override func viewDidLoad() {
        super.viewDidLoad ( )
    }
    
    
    func displayMessageInterface() {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.recipients = self.recipients ?? []
        composeVC.body = body ?? ""
        
        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
        } else {
            self.delegate?.messageCompletion (result: MessageComposeResult.failed)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        self.delegate?.messageCompletion(result: result)
    }
}
            
            
            
struct MessageUIView: UIViewControllerRepresentable {
    
    // To be able to dismiss itself after successfully finishing with the MessagesUI
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var recipients: [String]
    @Binding var body: String
    
    var completion: ((_ result: MessageComposeResult) -> Void)
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> MessagesViewController {
        let controller = MessagesViewController()
        controller.delegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }
    func updateUIViewController(_ uiViewController: MessagesViewController, context: Context) {
        uiViewController.recipients = recipients
        uiViewController.displayMessageInterface()
    }
}
