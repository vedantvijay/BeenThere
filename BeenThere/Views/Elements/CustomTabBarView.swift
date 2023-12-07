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
                            .offset(y: -5)
                        Text("Search")
                            .font(.caption)
                    }
                }
                .foregroundColor(selection == .settings ? .white : Color(uiColor: UIColor(red: 0.68, green: 0.68, blue: 0.68, alpha: 1)))
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
                                .foregroundColor(selection == .map ? .white : Color(uiColor: UIColor.lightGray))
                        }
                    }
                    Text("Explore")
                        .padding(.top, 3)
                        .font(.caption)
                }
                .foregroundColor(selection == .map ? .white : Color(uiColor: UIColor(red: 0.68, green: 0.68, blue: 0.68, alpha: 1)))
                Button(action: {
                    selection = .leaderboards
                }) {
                    VStack {
                        Image("leaderboard")
                            .resizable()
                            .frame(width: 22, height: 25)
                            .offset(y: -5)
                        Text("Leaderboard")
                            .font(.caption)
                    }
                }
                .foregroundColor(selection == .leaderboards ? .white : Color(uiColor: UIColor(red: 0.68, green: 0.68, blue: 0.68, alpha: 1)))
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom)

        }
        .offset(y: -3)
        .ignoresSafeArea()
        .frame(height: 65)
    }
}

struct CurvedTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let curveDepth: CGFloat = 30
        let curveWidth: CGFloat = rect.width * 0.25

        let controlPointX = (rect.width - curveWidth) / 2
        let curveControlPointY: CGFloat = -curveDepth

        path.move(to: CGPoint(x: 0, y: 0))

        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.addLine(to: CGPoint(x: rect.width/3.25, y: 0))

        path.addCurve(
            to: CGPoint(x: rect.width / 2, y: curveControlPointY),
            control1: CGPoint(x: controlPointX, y: 0),
            control2: CGPoint(x: rect.width / 2 - curveWidth / 4, y: curveControlPointY)
        )
        
        path.addCurve(
            to: CGPoint(x: rect.width - rect.width/3.25, y: 0),
            control1: CGPoint(x: rect.width / 2 + curveWidth / 4, y: curveControlPointY),
            control2: CGPoint(x: rect.width - controlPointX, y: 0)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        path.addLine(to: CGPoint(x: 0, y: rect.height))

        return path
    }
}





#Preview {
    CustomTabBarView(selection: .constant(.map))
}


