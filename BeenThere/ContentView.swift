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
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject private var mapViewModel = MapViewModel()
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("chunksCount") var chunksCount: Int = 0
    @State private var showTestDialog = false
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()
    @StateObject private var locationManagerDelegate = LocationManagerDelegate(locationManager: CLLocationManager())

    @State private var showSettingsAlert: Bool = false
    @State private var selection = 2
    
    var usesMetric: Bool {
        let locale = Locale.current
        switch locale.measurementSystem {
        case .metric:
            return true
        case .us, .uk:
            return false
        default:
            return true
        }
    }
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selection) {
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                }
                .tag(1)
            ZStack {
                if locationManagerDelegate.authorizationStatus != .authorizedAlways {
                    if locationManagerDelegate.authorizationStatus == .denied {
                        Button("Update Location Settings") {
                            showSettingsAlert = true
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                MapView(viewModel: mapViewModel)
                    .ignoresSafeArea()
            }
                .tabItem {
                    Image(systemName: "map.fill")
                }
                .tag(2)
            AccountView(viewModel: accountViewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                }
                .tag(3)
        }
        .alert(isPresented: $showSettingsAlert) {
            Alert(
                title: Text("Location Access Denied"),
                message: Text("To enable location access, please go to Settings and allow always location access for this app."),
                primaryButton: .default(Text("Go to Settings"), action: {
                    openAppSettings()
                }),
                secondaryButton: .cancel()
            )
        }
        .onChange(of: colorScheme) {
            mapViewModel.updateMapStyleURL()
        }
        .onAppear {
            mapViewModel.updateMapStyleURL()
        }
        .confirmationDialog("Navigate", isPresented: $mapViewModel.showTappedLocation) {
            if let location = mapViewModel.tappedLocation {
                Link("Open in Google Maps", destination: googleMapsURL(for: location))
                Link("Open in Apple Maps", destination: appleMapsURL(for: location))
            }
        }
    }

    private func requestLocationAccess() {
        locationManager.delegate = locationManagerDelegate
        locationManager.requestWhenInUseAuthorization() // Start with 'When in Use' authorization
    }

    private func googleMapsURL(for location: CLLocationCoordinate2D) -> URL {
        URL(string: "comgooglemaps://?q=\(location.latitude),\(location.longitude)&center=\(location.latitude),\(location.longitude)&zoom=14")!
    }
    private func appleMapsURL(for location: CLLocationCoordinate2D) -> URL {
        URL(string: "http://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&z=14")!
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var locationManager: CLLocationManager?

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // Once 'When in Use' permission is granted, request 'Always' authorization
            self.locationManager?.requestAlwaysAuthorization()
        }
        self.authorizationStatus = status
    }
}


#Preview {
    ContentView()
}
