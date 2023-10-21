//
//  ContentView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import Mapbox
import CoreLocation

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    private let locationManager = CLLocationManager()
    @AppStorage("chunksCount") var chunksCount: Int = 0
    @State private var showTestDialog = false
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @StateObject private var locationManagerDelegate = LocationManagerDelegate()
    
    var usesMetric: Bool {
        let locale = Locale.current
        switch locale.measurementSystem {
        case .metric:
            return true
        case .us, .uk:
            return false
        default:
            return true // Default to metric for unknown measurement systems
        }
    }

    
    var body: some View {
        ZStack {
            MapView(viewModel: mapViewModel)
                .ignoresSafeArea()
                .onAppear {
                    requestLocationAccess()
                    mapViewModel.updateChunksCount()
                }
            VStack {
                if locationManagerDelegate.authorizationStatus != .authorizedAlways {
                    Button("Enable Always Location Access") {
                        requestLocationAccess()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Spacer()
                Text("Chunks: \(chunksCount - 1)")
                    .fontWeight(.black)
                    .foregroundStyle(.black)
                Text("Area: \(String(format: "%.0f", mapViewModel.totalAreaInChunks())) \(usesMetric ? "sq. km" : "sq. miles")")
                    .fontWeight(.black)
                    .foregroundStyle(.black)
            }
            .confirmationDialog("Navigate", isPresented: $mapViewModel.showTappedLocation) {
                if let location = mapViewModel.tappedLocation {
                    Link("Open in Google Maps", destination: googleMapsURL(for: location))
                    Link("Open in Apple Maps", destination: appleMapsURL(for: location))
                }
            }
        }
    }
    private func requestLocationAccess() {
        locationManager.delegate = locationManagerDelegate
        locationManager.requestAlwaysAuthorization()
    }

//    
//    private func requestLocationAccess() {
//        locationManager.requestAlwaysAuthorization()
//    }
    private func googleMapsURL(for location: CLLocationCoordinate2D) -> URL {
        URL(string: "comgooglemaps://?q=\(location.latitude),\(location.longitude)&center=\(location.latitude),\(location.longitude)&zoom=14")!
    }
    private func appleMapsURL(for location: CLLocationCoordinate2D) -> URL {
        URL(string: "http://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&z=14")!
    }
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }
}





#Preview {
    ContentView()
}
