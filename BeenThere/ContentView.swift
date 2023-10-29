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
    
    @StateObject private var locationManagerDelegate = LocationManagerDelegate()

    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selection) {
            AccountView(viewModel: accountViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                }
                .tag(1)
            ZStack {
                MapView(viewModel: mapViewModel)
                    .ignoresSafeArea()
                    .onAppear {
                        mapViewModel.adjustMapViewToLocations()
                        let status = locationManagerDelegate.authorizationStatus
                        print("Authorization Status: \(status.rawValue)")
                        print("LOG: \(status)")
                    }
                    .onChange(of: $mapViewModel.locations.count) {
                        mapViewModel.adjustMapViewToLocations()
                    }
                if locationManagerDelegate.authorizationStatus != .authorizedAlways {
                    VStack {
                        Button("Update Location Settings") {
                            showSettingsAlert = true
                        }
                        .fontWeight(.black)
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .padding()
                        Spacer()
                    }
                }
            }
            .tabItem {
                Image(systemName: "map.fill")
            }
            .tag(2)

            LeaderboardView(viewModel: accountViewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
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
            accountViewModel.ensureUserHasUIDAttribute()
        }
        .confirmationDialog("Navigate", isPresented: $mapViewModel.showTappedLocation) {
            if let location = mapViewModel.tappedLocation {
                Link("Open in Google Maps", destination: googleMapsURL(for: location))
                Link("Open in Apple Maps", destination: appleMapsURL(for: location))
            }
        }
    }

    private func requestLocationAccess() {
        locationManagerDelegate.requestLocationAccess()
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

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager?.delegate = self
    }
    
    func requestLocationAccess() {
        locationManager?.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        locationManager?.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // Once 'When in Use' permission is granted, request 'Always' authorization
            self.locationManager?.requestAlwaysAuthorization()
        }
        self.authorizationStatus = status
    }
}
//
//
//#Preview {
//    ContentView()
//}
