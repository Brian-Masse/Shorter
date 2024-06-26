//
//  EmojiPicker.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIKit
import MCEmojiPicker
import UIUniversals

struct TestView2: View {
    var body: some View {
        
        VStack {
         
            Text("content")
            
            EmojiPicker()
            
//            Text("content")
        }
        .modifier( EmojiPresenter() )
    }
}

#Preview {
    TestView2()
}

//MARK: EmojiPickerViewModel
class EmojiPickerViewModel: ObservableObject {
    
    static let shared = EmojiPickerViewModel()

    @Published var showingEmojiTray: Bool = false
    @Published var selectedEmoji: String = "🫥"
    
    @Published var frequentlyUsedEmojis: EmojiCategory
    
    init() {
        self.frequentlyUsedEmojis = .init(
            type: .frequentlyUsed,
            categoryName: EmojiCategory.EmojiCateogryType.frequentlyUsed.title,
            emojis: UnicodeManager.shared.getFrequentlyUsedEmojis()
        )
    }
    
    @MainActor
    func selectEmoji(_ emoji: Emoji) {
        
        let unicode = emoji.keys.first!
        let charachter = Character(UnicodeScalar(unicode)!)
        
        withAnimation {
            self.selectedEmoji = String(charachter)
        }
        
        emoji.usage += 1
        emoji.lastUsage = .now
        
        self.frequentlyUsedEmojis.emojis = UnicodeManager.shared.getFrequentlyUsedEmojis()
    }
}

extension View {
    func emojiPresenter() -> some View {
        modifier(EmojiPresenter())
    }
}

//MARK: EmojiPresenter
struct EmojiPresenter: ViewModifier {
    
    private struct TrayLayout: Layout {
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            
            UIScreen.main.bounds.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            
            subviews.first!.place(at: .init(x: bounds.midX, y: bounds.maxY  ),
                                  anchor: .bottom,
                                  proposal: proposal)
        }
    }
    
    @ObservedObject private var viewModel = EmojiPickerViewModel.shared
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    if viewModel.showingEmojiTray {
                        ZStack {
                            TrayLayout {
                                EmojiPickerTray()
                            }
                        }
                        .onAppear { content.hideKeyboard() }
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation { viewModel.showingEmojiTray = false }}
                        .transition(
                            .scale(scale: 0.5, anchor: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                }
            }
    }
}

//MARK: EmojiPicker
struct EmojiPicker: View {
    
    @ObservedObject private var viewModel = EmojiPickerViewModel.shared
    
    var body: some View {
        VStack {
            UniversalButton {
                
                ZStack {
                    Text("IIIII")
                        .foregroundStyle(.clear)
                        .rectangularBackground(style: .transparent)
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
                        
                    Text( viewModel.selectedEmoji )
                        .font(.title)
                }
                
            } action: {
                viewModel.showingEmojiTray = true
            }
        }
    }
}

struct EmojiPickerTray: View {
    
    let unicodeManager = UnicodeManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel = EmojiPickerViewModel.shared
    
    @State private var currentCategory: EmojiCategory.EmojiCateogryType = .people
    
    @State private var scrollPosition: CGPoint = .zero
    
    let coordinateSpaceName = "scroll"
    
//    MARK: EmojiPicker ViewBuilders
    @ViewBuilder
    private func makeCategoryLabel(category: EmojiCategory, proxy: ScrollViewProxy) -> some View {
        UniversalButton(shouldAnimate: false) {
            HStack {
                Spacer()
                
                
                Image(systemName: category.type.icon)
                    .renderingMode(.template)
                    .font(.title3)
                    .if(currentCategory == category.type) { view in
                        view.foregroundStyle(Colors.getAccent(from: colorScheme))
                    }
                
                Spacer()
            }
        } action: {
            proxy.scrollTo( category.type.rawValue, anchor: .top )
            currentCategory = category.type
        }
    }
    
//    MARK: EmojiPickerBody
    var body: some View {
        GeometryReader { geo in
                            
            ScrollViewReader { proxy in
                VStack {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            ForEach(unicodeManager.defaultEmojis) { category in
                                
                                EmojiPickerCategoryView(category: category,
                                                        scrollPosition: $scrollPosition.y,
                                                        currentCategory: $currentCategory,
                                                        geo: geo)
                            }
                        }
                        
                        .background(GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self,
                                            value: geo.frame(in: .named(coordinateSpaceName)).origin)
                        })
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            self.scrollPosition = value
                        }
                    }
                    .coordinateSpace(name: coordinateSpaceName)
                    
                    Divider()
                    
                    HStack {
                        ForEach( unicodeManager.defaultEmojis ) { cateogry in
                            makeCategoryLabel(category: cateogry, proxy: proxy)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .clipShape(Rectangle())
        }
        .frame(height: 370)
        .rectangularBackground()
        .shadow(color: .black.opacity(0.15), radius: 20, y: 15)
        .padding(.vertical)
    }
}

//MARK: EmojiPickerCategoryView
private struct EmojiPickerCategoryView: View {
    
    let unicodeManager = UnicodeManager.shared
    
    let category: EmojiCategory
    
    @ObservedObject private var viewModel = EmojiPickerViewModel.shared
    
    @Binding var scrollPosition: CGFloat
    @Binding var currentCategory: EmojiCategory.EmojiCateogryType
    
    let geo: GeometryProxy
    
    @State private var lockPos: CGFloat = .zero
    @State private var lockTitle: Bool = false
    
    private let coloumnCount: Double = 8
    private let coloumnSpacing: Double = 5
    
    private func emojiWidth(in geo: GeometryProxy) -> CGFloat {
        (geo.size.width - ( coloumnSpacing * coloumnCount - 1 )) / ( coloumnCount )
    }
    
    private func checkLockTitle(in geo: GeometryProxy) {
        let pos = geo.frame(in: .named("scroll")).minY
        
        if pos < 1 && !self.lockTitle {
            self.lockTitle = true
            self.currentCategory = category.type
        }
        if pos > 1 && self.lockTitle { self.lockTitle = false }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                Text( "\(category.name)" )
                    .font(.headline)
                    .textCase(.uppercase)
                    .opacity(0.7)
                
                Spacer()
                
                UniversalButton {
                    Image(systemName: "xmark")
                        .padding([.leading, .bottom])
                        .padding([.top, .trailing], 7)
                        .zIndex(2)
                } action: {
                    viewModel.showingEmojiTray = false
                }
            }
            .id(category.type.rawValue)
            .background()
            .zIndex(1)
            .offset(y: lockTitle ? -scrollPosition - lockPos : 0)
            
            LazyVGrid(columns: [.init(.adaptive(minimum: emojiWidth(in: geo), maximum: emojiWidth(in: geo)),
                                      spacing: coloumnSpacing,
                                      alignment: .center)],
                      alignment: .center,
                      spacing: coloumnSpacing) {
                
                let emojis = category.emojis
                
                ForEach(emojis) { emoji in
                    let unicode = emoji.keys.first!
                    let charachter = Character(UnicodeScalar(unicode)!)
                    
                    UniversalButton {
                        Text( String(charachter) )
                            .font(.largeTitle)
                    } action: {
                        viewModel.selectEmoji( emoji )
                        viewModel.showingEmojiTray = false
                    }
                }
            }
                          .padding(.bottom)
        }
        .overlay { GeometryReader { localGeo in
          Rectangle()
                .foregroundStyle(.clear)
                .onChange(of: scrollPosition) { oldValue, newValue in
                    checkLockTitle(in: localGeo)
                }
                .onAppear { self.lockPos = localGeo.frame(in: .named("scroll")).minY }
            
        }}
    }
}

//MARK: PreferenceKey
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}
