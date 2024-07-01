//
//  PlanterScene.swift
//  Planter
//
//  Created by Brian Masse on 11/29/23.
//

import Foundation
import SwiftUI
import UIUniversals

protocol ShorterSceneEnum: CaseIterable, RawRepresentable, Hashable, Identifiable where Self.AllCases: RandomAccessCollection, Self.RawValue == Int {
    func getTitle() -> String
}

struct ShorterScene<Content: View, Scene: ShorterSceneEnum>: View {
    
//    MARK: Vars
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var sceneState: Scene
    @Binding var sceneComplete: Bool
    
    @State private var slideDirection: Edge = .trailing
    
    @ViewBuilder var contentBuilder: ( Scene, Edge ) -> Content
    let submit: () -> Void
    
    let allowsSceneRegression: Bool
    let showControlsOnStart: Bool
    let hasStartScene: Bool
    let hideControls: Bool
    
    init( _ scene: Binding<Scene>,
          sceneComplete: Binding<Bool>,
          canRegressScene: Bool,
          showControlsOnStart: Bool = false,
          hasStartScene: Bool = false,
          hideControls: Bool = false,
          submit: @escaping() -> Void,
          contentBuilder: @escaping ( Scene, Edge ) -> Content ) {
        
        
        self.contentBuilder = contentBuilder
        self._sceneState = scene
        self._sceneComplete = sceneComplete
        self.submit = submit
        self.showControlsOnStart = showControlsOnStart
        self.hasStartScene = hasStartScene
        self.hideControls = hideControls
        
        self.allowsSceneRegression = canRegressScene
    }
    
//    MARK: StructMethods
    private var onLastPage: Bool {
        sceneState.rawValue == Scene.allCases.count - 1
    }
    
    private func progressScene() {
        slideDirection = .trailing
        
        withAnimation {
            if onLastPage {
                submit()
            } else if sceneComplete {
                sceneState = Scene(rawValue: sceneState.rawValue + 1) ?? sceneState
            }
            sceneComplete  = false
        }
    }
    
    private func regressScene() {
        slideDirection = .leading
            
        if sceneState.rawValue == 0 { dismiss() }
        if allowsSceneRegression { withAnimation {
            sceneState = Scene( rawValue: sceneState.rawValue - 1 ) ?? sceneState
        } }
        sceneComplete = true
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeSceneCompletionIndicator(sceneId: Int) -> some View {
        ZStack {
            Circle().stroke(lineWidth: 2)
            Circle()
                .fill()
                .opacity(sceneId <= sceneState.rawValue ? 1 : 0)
        }
        .frame(width: 8, height: 8)
    }
    
    @ViewBuilder
    private func makeSceneCompletionIndicators() -> some View {
        HStack {
            let start = hasStartScene ? 1 : 0
            
            ForEach( start..<Scene.allCases.count, id: \.self ) { i in
                makeSceneCompletionIndicator(sceneId: i)
            }
        }
    }
    
    @ViewBuilder
    private func makeHeader() -> some View {
        
        HStack(alignment: .center) {
            IconButton("arrow.backward") { regressScene() }
                .opacity( sceneState.rawValue == 0 ? 0.3 : 1 )
            
            Spacer()
            
            VStack {
                makeSceneCompletionIndicators()
            }
            
            Spacer()
            
            IconButton("arrow.forward") { progressScene() }
                .opacity( sceneComplete ? 1 : 0.3 )
        }
    }
    
    @ViewBuilder
    private func makeNextButton() -> some View {
        
        UniversalButton {
            HStack {
                Spacer()
                
                Text( "Continue" )
                    .font(.title2)
                
                Image(systemName: "arrow.forward")
                
                Spacer()
            }
            .if(sceneComplete) { view in view.foregroundStyle(.background) }
            .rectangularBackground( style: sceneComplete ? .accent : .primary)
            .shadow(color: Colors.getAccent(from: colorScheme).opacity(sceneComplete ? 0.3 : 0),
                    radius: 25)
            .opacity(sceneComplete ? 1 : 0.45)
            .bold()
            
        } action: {
            if !sceneComplete { return }
            progressScene()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            if sceneState.rawValue > 0 || showControlsOnStart {
                if !hideControls {
                    makeHeader()
                        .padding(.bottom)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 0) {
                
                contentBuilder( sceneState, slideDirection)
                
                Spacer()
                
                makeNextButton()
            }
            .padding(.horizontal, 7)
            .padding(.horizontal)
        }
//        .scrollDismissesKeyboard(.immediately)
        .ignoresSafeArea()
        .padding(.vertical)
        .background {
            BlurredBackground(colors: ShorterModel.defautColorPallett)
                .ignoresSafeArea()
        }
        
//        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ProfileCreationView()
}
