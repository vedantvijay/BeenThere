import SwiftUI

struct SlidyView: View {
    let lowHeight: CGFloat = 50
    let screenHeight: CGFloat
    let screenWidth: CGFloat
    
    @Binding var isInteractingWithSlidyView: Bool
    @State private var currentHeight: CGFloat
    @GestureState private var dragAmount = CGSize.zero
    @GestureState private var dragState = DragState.inactive
    @State private var dragStartY: CGFloat? = nil
    @State private var isGestureActive = false
    @State private var isSearchBarFocused: Bool = false

    private let swipeThresholdDistance: CGFloat = 1
    
    init(isInteractingWithSlidyView: Binding<Bool>, screenHeight: CGFloat, screenWidth: CGFloat) {
        self.screenHeight = screenHeight
        self.screenWidth = screenWidth
        _isInteractingWithSlidyView = isInteractingWithSlidyView
        _currentHeight = State(initialValue: lowHeight)
    }
    
    var body: some View {
            let mediumHeight = screenHeight * 0.4
            let tallHeight = screenHeight * 0.9

            ZStack(alignment: .top) {
                Rectangle()
                    .cornerRadius(15, corners: [.topLeft, .topRight])
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color(uiColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)))
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 40, height: 5)
                    .padding(6)
                    .foregroundStyle(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
                
                VStack {
                    FeedView()
                }
                .frame(width: screenWidth, height: currentHeight)
                .clipped()
                .offset(y: verticalOffset(for: currentHeight, mediumHeight: mediumHeight))
                .onChange(of: isSearchBarFocused) {
                    if isSearchBarFocused {
                        withAnimation {
                            currentHeight = tallHeight
                        }
                    }
                }
            }
            .frame(height: currentHeight)
            .gesture(
                DragGesture()
                    .updating($dragAmount) { drag, state, _ in
                        state = drag.translation
                    }
                    .onChanged { drag in
                        isInteractingWithSlidyView = true
                        let newHeight = max(lowHeight, currentHeight - drag.translation.height)
                        if newHeight != currentHeight {
                            currentHeight = newHeight
                        }
                    }
                    .onEnded { value in
                        handleGestureEnd(value, mediumHeight: mediumHeight, tallHeight: tallHeight)
                    }
            )
        
    }
    
    private func handleGestureEnd(_ value: DragGesture.Value, mediumHeight: CGFloat, tallHeight: CGFloat) {
           let verticalDistance = value.translation.height
           if abs(verticalDistance) > swipeThresholdDistance {
               let swipeUp = verticalDistance < 0
               withAnimation {
                   self.currentHeight = self.nextHeight(swipeUp: swipeUp, mediumHeight: mediumHeight, tallHeight: tallHeight)
               }
           } else {
               let closestHeight = self.closestHeight(to: currentHeight, mediumHeight: mediumHeight, tallHeight: tallHeight)
               withAnimation {
                   self.currentHeight = closestHeight
               }
           }
           isInteractingWithSlidyView = currentHeight == tallHeight
       }
    
    private func nextHeight(swipeUp: Bool, mediumHeight: CGFloat, tallHeight: CGFloat) -> CGFloat {
        _ = [lowHeight, mediumHeight, tallHeight]
        let closestHeight = self.closestHeight(to: currentHeight, mediumHeight: mediumHeight, tallHeight: tallHeight)
        
        if swipeUp {
            switch closestHeight {
            case lowHeight:
                return mediumHeight
            case mediumHeight:
                return tallHeight
            default:
                return tallHeight // Already at the tallest height
            }
        } else {
            switch closestHeight {
            case tallHeight:
                return mediumHeight
            case mediumHeight:
                return lowHeight
            default:
                return lowHeight // Already at the lowest height
            }
        }
    }
    
    
    private func closestHeight(to height: CGFloat, mediumHeight: CGFloat, tallHeight: CGFloat) -> CGFloat {
        let heights = [lowHeight, mediumHeight, tallHeight]
        return heights.min(by: { abs($0 - height) < abs($1 - height) }) ?? lowHeight
    }
    
    private func verticalOffset(for height: CGFloat, mediumHeight: CGFloat) -> CGFloat {
        if height <= lowHeight {
            return 100
        } else if height >= mediumHeight {
            return 0
        } else {
            let progress = (height - lowHeight) / (mediumHeight - lowHeight)
            return 100 - (progress * 100)
        }
    }
    
//    private func verticalOffset(for height: CGFloat, screenHeight: CGFloat) -> CGFloat {
//        return screenHeight - height
//    }

    
    private func handleDragGesture(_ gesture: DragGesture.Value, mediumHeight: CGFloat, tallHeight: CGFloat) {
        if isGestureActive {
            // Handle drag change
            let newHeight = max(lowHeight, currentHeight - gesture.translation.height)
            if newHeight != currentHeight {
                currentHeight = newHeight
            }
        } else {
            // Handle drag end
            let verticalDistance = gesture.translation.height
            if abs(verticalDistance) > swipeThresholdDistance {
                let swipeUp = verticalDistance < 0
                withAnimation {
                    self.currentHeight = self.nextHeight(swipeUp: swipeUp, mediumHeight: mediumHeight, tallHeight: tallHeight)
                }
            } else {
                let closestHeight = self.closestHeight(to: currentHeight, mediumHeight: mediumHeight, tallHeight: tallHeight)
                withAnimation {
                    self.currentHeight = closestHeight
                }
            }
            isInteractingWithSlidyView = currentHeight == tallHeight
        }
        isGestureActive.toggle()
    }



    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct NonScrollingScrollView<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    content
                }
                .frame(minHeight: geometry.size.height + 1) // Slightly larger than the screen
            }
        }
    }
}


struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct CustomScrollView<Content: View>: View {
    var content: Content
    let onDragGesture: (DragGesture.Value) -> Void

    init(@ViewBuilder content: () -> Content, onDragGesture: @escaping (DragGesture.Value) -> Void) {
        self.content = content()
        self.onDragGesture = onDragGesture
    }

    var body: some View {
        ScrollView {
            content
                .background(GeometryReader { geometryProxy in
                    Color.clear.preference(key: ViewOffsetKey.self, value: geometryProxy.frame(in: .named("scrollView")).origin.y)
                })
        }
        .coordinateSpace(name: "scrollView")
        .gesture(
            DragGesture()
                .onChanged(onDragGesture)
                .onEnded(onDragGesture)
        )
    }
}


struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}


//#Preview {
//    SlidyView(isInteractingWithSlidyView: .constant(true))
//}
