//
//  DirectionsOverviewView.swift
//  BeenThere
//
//  Created by Jared Jones on 12/11/23.
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct DirectionsSheetView: View {
    @EnvironmentObject var viewModel: MainMapViewModel
    let collapsedHeight: CGFloat = 45
    let expandedHeight: CGFloat = 400
    @State private var sheetHeight: CGFloat = 45
    @State private var isDragging: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .cornerRadius(15, corners: [.topLeft, .topRight])
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(uiColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)))
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 40, height: 4)
                .padding(4)
                .padding(.bottom, 10)
                .foregroundStyle(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: .constant(""))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "mic.fill")
                }
                .padding(10)
                .background(.gray)
                .cornerRadius(5)
                .padding()
                .opacity(viewModel.showTappedLocation ? 1 : 0)
                Button("Navigate in App") { }
                    .opacity(viewModel.showTappedLocation ? 1 : 0)
                HStack {
                    Link("Open in Google Maps", destination: googleMapsURL(for: viewModel.tappedLocation ?? CLLocationCoordinate2D(latitude: 50, longitude: 50)))
                    Link("Open in Apple Maps", destination: appleMapsURL(for: viewModel.tappedLocation ?? CLLocationCoordinate2D(latitude: 50, longitude: 50)))
                }
                    .opacity(viewModel.showTappedLocation ? 1 : 0)
                Text("Basically make this look like the apple maps bottom sheet thing?")
                    .opacity(viewModel.showTappedLocation ? 1 : 0)
                    .padding()
                    .foregroundStyle(.secondary)
                    .fontWeight(.black)
            }
            .padding(.top, 20)
            .frame(height: viewModel.showTappedLocation ? .infinity : .zero)
        }
        
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newHeight = sheetHeight + value.translation.height
                    sheetHeight = min(max(collapsedHeight, newHeight), expandedHeight)
                }
                .onEnded { value in
                    isDragging = false
                    let middleHeight = (collapsedHeight + expandedHeight) / 2
                    sheetHeight = sheetHeight < middleHeight ? collapsedHeight : expandedHeight
                }
        )
//        .onChange(of: viewModel.tappedLocation) {
//            if viewModel.tappedLocation == nil {
//                viewModel.centerAfterSheetDissapears(at: viewModel.lastCameraCenter ?? CLLocationCoordinate2D(latitude: 50, longitude: 50))
//            }
//        }
//        .animation(.easeInOut, value: sheetHeight)
//        .animation(.easeInOut, value: isDragging)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showTappedLocation)
        .buttonStyle(.bordered)
        .frame(height: viewModel.showTappedLocation ? expandedHeight : collapsedHeight)
//        .frame(height: sheetHeight)
    }
    
    private func googleMapsURL(for location: CLLocationCoordinate2D) -> URL {
        URL(string: "comgooglemaps://?q=\(location.latitude),\(location.longitude)&center=\(location.latitude),\(location.longitude)&zoom=14")!
    }
    private func appleMapsURL(for location: CLLocationCoordinate2D) -> URL {
        URL(string: "http://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&q=\(location.latitude),\(location.longitude)")!
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

// Shape for rounding specific corners
struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//#Preview {
//    DirectionsSheetView()
//}
