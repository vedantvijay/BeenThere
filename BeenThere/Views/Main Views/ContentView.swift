import SwiftUI
import CoreLocation
import FirebaseAuth
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

struct ContentView: View {
    @AppStorage("username") var username = ""
    @AppStorage("appState") var appState = "opening"
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var friendMapViewModel = FriendMapViewModel(accountViewModel: AccountViewModel.sharedFriend)
    @StateObject var sharedMapViewModel = SharedMapViewModel(accountViewModel: AccountViewModel.sharedShared)
    @StateObject var mainMapViewModel = MainMapViewModel(accountViewModel: AccountViewModel.sharedMain)
    @StateObject private var locationManagerDelegate = LocationManagerDelegate()
    @StateObject var navigationManager = NavigationManager()
    @State private var isNavigationActive = false
    @State private var activeRoute: Route?
    @State private var isKeyboardVisible = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showTestDialog = false
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @State private var showSettingsAlert: Bool = false
    @State private var selection = Tab.map
    @State private var focusedField: Any?
    @State private var showNavigation = false
    
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
                    .ignoresSafeArea()

            case .feed:
                FeedView()
                    .ignoresSafeArea()
            case .map:
                ZStack(alignment: .top) {
                    MainMapView()
                        .ignoresSafeArea()
                        .environmentObject(mainMapViewModel)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
//                        .onAppear {
//                            mainMapViewModel.onNavigationStart = { route in
//                                print("Navigation start triggered")
//                                if let routeResponse = mainMapViewModel.routeResponse, let routeIndex = routeResponse.routes?.firstIndex(of: route) {
//                                    self.activeRoute = route
//                                    self.isNavigationActive = true
//                                    print("isNavigationActive set to true")
//                                }
//                            }
//                        }
//                        .onAppear {
//                            let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Example coordinates
//                            let destination = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
//                            mainMapViewModel.requestDirections(from: origin, to: destination)
//                        }

//                        .sheet(isPresented: $isNavigationActive) {
//                            Text("Navigation View Controller should be here")
//                        }



                    HStack {
                        if !(authorizationStatus == .authorizedAlways || authorizationStatus == .notDetermined) {
                            Spacer()
                            Button {
                                showSettingsAlert = true
                            } label: {
                                Image(systemName: "location.slash.circle.fill")
                            }
                            .padding([.top, .trailing])
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .ignoresSafeArea()
                }
                .onChange(of: locationManagerDelegate.authorizationStatus) {
                    self.authorizationStatus = locationManagerDelegate.authorizationStatus
                }
                
            case .leaderboards:
                LeaderboardView()
                    .ignoresSafeArea()
                    .environmentObject(friendMapViewModel)
                    .environmentObject(sharedMapViewModel)
            case .profile:
                ProfileView()
                    .ignoresSafeArea()
                    .environmentObject(accountViewModel)
            }
            if !isKeyboardVisible {
                CustomTabBarView(selection: $selection)
                    .environmentObject(mainMapViewModel)
                    .environmentObject(friendMapViewModel)
                    .environmentObject(sharedMapViewModel)
                    .environmentObject(accountViewModel)
                    .ignoresSafeArea()
            }
        }
        .background(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
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
        .onChange(of: accountViewModel.locations.count) {
            mainMapViewModel.locations = accountViewModel.locations
            mainMapViewModel.addSquaresToMap(locations: accountViewModel.locations)
        }
        .onChange(of: colorScheme) {
            if colorScheme == .light {
                print("LOG: light mode")
                mainMapViewModel.isDarkModeEnabled = false
                friendMapViewModel.isDarkModeEnabled = false
                sharedMapViewModel.isDarkModeEnabled = false
            } else {
                print("LOG: dark mode")
                mainMapViewModel.isDarkModeEnabled = true
                friendMapViewModel.isDarkModeEnabled = true
                sharedMapViewModel.isDarkModeEnabled = true
            }
            mainMapViewModel.updateMapStyleURL()
        }
       
        .onAppear {
            if colorScheme == .light {
                print("LOG: light mode")
                mainMapViewModel.isDarkModeEnabled = false
                friendMapViewModel.isDarkModeEnabled = false
                sharedMapViewModel.isDarkModeEnabled = false
            } else {
                print("LOG: dark mode")
                mainMapViewModel.isDarkModeEnabled = true
                friendMapViewModel.isDarkModeEnabled = true
                sharedMapViewModel.isDarkModeEnabled = true
            }
            mainMapViewModel.updateMapStyleURL()
            accountViewModel.ensureUserHasUIDAttribute()
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = true
            }
            notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
            }
        }
        .confirmationDialog("Navigate", isPresented: $mainMapViewModel.showTappedLocation) {
            if let location = mainMapViewModel.tappedLocation {
//                Button("Start Navigation") {
//                    if let destination = mainMapViewModel.tappedLocation, let currentLocation = mainMapViewModel.locationManager.location?.coordinate {
//                        mainMapViewModel.requestDirections(from: currentLocation, to: destination)
//
//                    }
//                }
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
            self.locationManager?.requestAlwaysAuthorization()
        }
        self.authorizationStatus = status
    }
}

//#Preview {
//    ContentView()
//}

