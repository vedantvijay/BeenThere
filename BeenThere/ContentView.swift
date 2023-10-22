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

    @AppStorage("chunksCount") var chunksCount: Int = 0
    @State private var showTestDialog = false
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()
    @StateObject private var locationManagerDelegate = LocationManagerDelegate(locationManager: CLLocationManager())

    @State private var showSettingsAlert: Bool = false
    
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
        ZStack {
            MapView(viewModel: mapViewModel)
                .ignoresSafeArea()
                .onAppear {
                    requestLocationAccess()
                }
            
            VStack {
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
//                HStack {
//                    NavigationLink {
//                        AccountView(viewModel: accountViewModel)
//                    } label: {
//                        Image(systemName: "person.circle.fill")
//                            .fontWeight(.black)
//                            .font(.largeTitle)
//                    }
//                    .padding()
//                    .padding()
//                    Spacer()
//                }
//                .ignoresSafeArea()
//                .foregroundStyle(.white)
                Spacer()
                NavigationLink("My Profile") {
                    AccountView(viewModel: accountViewModel)
                }
                .buttonStyle(.borderedProminent)
            }
            .confirmationDialog("Navigate", isPresented: $mapViewModel.showTappedLocation) {
                if let location = mapViewModel.tappedLocation {
                    Link("Open in Google Maps", destination: googleMapsURL(for: location))
                    Link("Open in Apple Maps", destination: appleMapsURL(for: location))
                }
            }
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
