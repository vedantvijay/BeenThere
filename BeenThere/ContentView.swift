//
//  ContentView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import Mapbox
import CoreLocation
import FirebaseAuth

struct ContentView: View {
    @AppStorage("username") var username = ""
    @AppStorage("appState") var appState = "opening"
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var accountViewModel = SettingsViewModel()
    @StateObject var friendMapViewModel = FriendMapViewModel()
    @StateObject var sharedMapViewModel = SharedMapViewModel()
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var testMapViewModel = TestMapViewModel()
//    @Environment(\.colorScheme) var colorScheme
    @StateObject private var locationManagerDelegate = LocationManagerDelegate()
    @State private var isKeyboardVisible = false
    @Environment(\.colorScheme) var colorScheme

    @State private var showTestDialog = false
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @State private var showSettingsAlert: Bool = false
    @State private var selection = Tab.map
    
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

    var body: some View {
        VStack {
            switch selection {
            case .settings:
                SettingsView()
            case .feed:
               
                FeedView()
            case .map:
                TestMapView(viewModel: testMapViewModel)
                    .onChange(of: testMapViewModel.locations) {
                        testMapViewModel.adjustMapViewToFitSquares()
                    }
//                ZStack {
//                    if colorScheme == .light {
//                        Color.white
//                            .ignoresSafeArea()
//                    } else {
//                        Color.white.opacity(0.1)
//                            .ignoresSafeArea()
//                    }
//                    OldMapView(viewModel: mapViewModel)
//                        .ignoresSafeArea()
//                        .onAppear {
//                            mapViewModel.adjustMapViewToLocations()
//                            let status = locationManagerDelegate.authorizationStatus
//                            print("Authorization Status: \(status.rawValue)")
//                            print("LOG: \(status)")
//                        }
//                        .onChange(of: $mapViewModel.locations.count) {
//                            mapViewModel.adjustMapViewToLocations()
//                        }
//                    if locationManagerDelegate.authorizationStatus != .authorizedAlways {
//                        VStack {
//                            Button("Update Location Settings") {
//                                showSettingsAlert = true
//                            }
//                            .fontWeight(.black)
//                            .buttonStyle(.bordered)
//                            .tint(.orange)
//                            .padding()
//                            .padding(.top, 50)
//                            Spacer()
//                        }
//                    }
//                }
            case .leaderboards:
                LeaderboardView()
                    .environmentObject(friendMapViewModel)
                    .environmentObject(sharedMapViewModel)
            case .profile:
                ProfileView()
            }
            if !isKeyboardVisible {
                CustomTabView(selection: $selection)
                    .padding(.bottom, 10)
            }

        }
        .ignoresSafeArea()
        .background(Material.bar)
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
            if colorScheme == .light {
                print("LOG: light mode")
                mapViewModel.isDarkModeEnabled = false
                friendMapViewModel.isDarkModeEnabled = false
                sharedMapViewModel.isDarkModeEnabled = false
            } else {
                print("LOG: dark mode")
                mapViewModel.isDarkModeEnabled = true
                friendMapViewModel.isDarkModeEnabled = true
                sharedMapViewModel.isDarkModeEnabled = true
            }
            mapViewModel.updateMapStyleURL()
            testMapViewModel.updateMapStyleURL()
        }
        .onAppear {
            if colorScheme == .light {
                print("LOG: light mode")
                mapViewModel.isDarkModeEnabled = false
                friendMapViewModel.isDarkModeEnabled = false
                sharedMapViewModel.isDarkModeEnabled = false
            } else {
                print("LOG: dark mode")
                mapViewModel.isDarkModeEnabled = true
                friendMapViewModel.isDarkModeEnabled = true
                sharedMapViewModel.isDarkModeEnabled = true
            }
            testMapViewModel.updateMapStyleURL()
            mapViewModel.updateMapStyleURL()
            accountViewModel.ensureUserHasUIDAttribute()
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = true
            }
            notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
            }
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
        URL(string: "http://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&q=\(location.latitude),\(location.longitude)")!
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error: \(error)")
            }
            // Enable or disable features based on the authorization.
        }
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
