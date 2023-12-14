//
//  SlidyView.swift
//  BeenThere
//
//  Created by Jared Jones on 12/13/23.
//

import SwiftUI

struct SlidyView: View {
    let lowHeight: CGFloat = 50
    let mediumHeight: CGFloat = 200
    let tallHeight: CGFloat = 750

    @Binding var isInteractingWithSlidyView: Bool
    @State private var currentHeight: CGFloat
    @GestureState private var dragAmount = CGSize.zero
    @GestureState private var dragState = DragState.inactive


    init(isInteractingWithSlidyView: Binding<Bool>) {
            _isInteractingWithSlidyView = isInteractingWithSlidyView
            _currentHeight = State(initialValue: lowHeight)
        }


    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .cornerRadius(15, corners: [.topLeft, .topRight])
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(uiColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)))
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 40, height: 5)
                .padding(6)
                .foregroundStyle(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
            ScrollView {
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search", text: .constant(""))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "mic.fill")
                    }
                    .padding()
                    .background(.gray)
                    .cornerRadius(5)
                    Text("Basically make this look like the apple maps bottom sheet thing")
                        .foregroundStyle(.secondary)
                        .fontWeight(.black)
                }
                .padding()
                .offset(y: verticalOffset(for: currentHeight))
            }
            .padding(.top, 45)
        }
        .frame(height: currentHeight)
        .gesture(
            DragGesture()
                .updating($dragAmount) { drag, state, _ in
                    state = drag.translation
                }
                .onChanged { _ in
                    isInteractingWithSlidyView = true
                    let newHeight = max(lowHeight, currentHeight - dragAmount.height)
                    currentHeight = newHeight
                }
                .onEnded { _ in
                    isInteractingWithSlidyView = currentHeight == tallHeight
                    let closestHeight = self.closestHeight(to: currentHeight)
                    withAnimation {
                        self.currentHeight = closestHeight
                    }
                }
        )
    }

    private func closestHeight(to height: CGFloat) -> CGFloat {
        let heights = [lowHeight, mediumHeight, tallHeight]
        return heights.min(by: { abs($0 - height) < abs($1 - height) }) ?? lowHeight
    }

    private func verticalOffset(for height: CGFloat) -> CGFloat {
        if height <= lowHeight {
            return 100
        } else if height >= mediumHeight {
            return 0
        } else {
            let progress = (height - lowHeight) / (mediumHeight - lowHeight)
            return 100 - (progress * 100)
        }
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

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}



#Preview {
    SlidyView(isInteractingWithSlidyView: .constant(true))
}
