import SwiftUI

struct CustomTabBarView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AccountViewModel
    @EnvironmentObject var mainMapViewModel: MainMapViewModel
    @EnvironmentObject var friendMapViewModel: FriendMapViewModel
    @EnvironmentObject var sharedMapViewModel: SharedMapViewModel
    @Binding var selection: Tab
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CurvedTabShape()
                .fill(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
                .frame(height: 90)
            HStack(alignment: .bottom) {
                Button(action: {
                    selection = .settings
                }) {
                    VStack {
                        Image("search")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(selection == .settings ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                            .offset(y: -5)
                        Text("Search")
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: UIColor.lightGray))
                    }
                   

                }
                .frame(maxWidth: .infinity)
                VStack {
                    ZStack {
                        Circle()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(Color(uiColor: UIColor(red: 0.29, green: 0.47, blue: 0.94, alpha: 1)))
                        Button(action: {
                            if selection == .map {
                                mainMapViewModel.adjustMapViewToFitSquares()
                            }
                            selection = .map
                        }) {
                            Image("explore")
                                .resizable()
                                .frame(width: 25, height: 32)
                                .foregroundColor(selection == .map ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                        }
                    }
                    Text("Explore")
                        .padding(.top, 3)
                        .font(.caption)
                        .foregroundStyle(selection == .map ? .white : Color(uiColor: UIColor.lightGray))
                }
                Button(action: {
                    selection = .leaderboards
                }) {
                    VStack {
                        Image("leaderboard")
                            .resizable()
                            .frame(width: 22, height: 25)
                            .foregroundColor(selection == .leaderboards ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                            .offset(y: -5)
                        Text("Leaderboard")
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: UIColor.lightGray))
                    }
                    
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom)

        }
        .ignoresSafeArea()
        .frame(height: 45)
    }
}

struct CurvedTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let curveDepth: CGFloat = 30 // The vertical offset for the curve control point
        let curveWidth: CGFloat = rect.width * 0.25 // The horizontal extent of the curve from the center

        // Calculate the horizontal positions for the control points
        let controlPointX = (rect.width - curveWidth) / 2
        let curveControlPointY: CGFloat = -curveDepth // The y-value for the curve's control points

        // Start at the bottom left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Line up to the top left corner
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.addLine(to: CGPoint(x: rect.width/3.25, y: 0))

        // Curve from the left to the top center of the hump
        path.addCurve(
            to: CGPoint(x: rect.width / 2, y: curveControlPointY), // End point at the top center of the curve
            control1: CGPoint(x: controlPointX, y: 0), // Control point 1 at the start of the curve
            control2: CGPoint(x: rect.width / 2 - curveWidth / 4, y: curveControlPointY) // Control point 2 towards the middle from the left
        )
        
        // Curve from the top center of the hump to the right
        path.addCurve(
            to: CGPoint(x: rect.width - rect.width/3.25, y: 0), // End point at the top right corner
            control1: CGPoint(x: rect.width / 2 + curveWidth / 4, y: curveControlPointY), // Control point 3 towards the middle from the right
            control2: CGPoint(x: rect.width - controlPointX, y: 0) // Control point 4 at the end of the curve
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // Line down to the bottom right corner
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        // Close the path
        path.addLine(to: CGPoint(x: 0, y: rect.height))

        return path
    }
}





#Preview {
    CustomTabBarView(selection: .constant(.map))
}
