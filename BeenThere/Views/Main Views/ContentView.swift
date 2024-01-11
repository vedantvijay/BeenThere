import SwiftUI
import CoreLocation
import FirebaseAuth
import Kingfisher
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

struct ContentView: View {
    @Environment(\.dismiss) var dismiss
    
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
    @State private var isInteractingWithSlidyView = false
    @State private var showSpeedAlert = false
    
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
        GeometryReader { geometry in
            VStack {
                switch selection {
                case .feed:
                    FeedView()
                        .ignoresSafeArea()
                case .map:
                    
                    ZStack(alignment: .top) {
                        
                        ZStack(alignment: .bottom) {
                            MainMapView()
                                .disabled(isInteractingWithSlidyView)
                                .ignoresSafeArea()
                                .environmentObject(mainMapViewModel)
                                .onTapGesture {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    mainMapViewModel.showTappedLocation = false
                                }
//                            SlidyView(isInteractingWithSlidyView: $isInteractingWithSlidyView, screenHeight: geometry.size.height, screenWidth: geometry.size.width)
                        }
                        VStack {
                            // The map picker should go right here
                            Picker("Map Selection", selection: $mainMapViewModel.mapSelection) {
                                Text("Personal").tag(MapSelection.personal)
                                Text("Global").tag(MapSelection.global)
                                ForEach(accountViewModel.friendList) { friend in
                                        Text(friend.firstName + " " + friend.lastName)
//                                        .onTapGesture {
//                                            mainMapViewModel.friendLocations = friend.locations
//                                        }
                                        .tag(MapSelection.friend(friend.id))
                                }
                            }
                            HStack {
                                if !(authorizationStatus == .authorizedAlways || authorizationStatus == .notDetermined) {
                                    Button {
                                        showSettingsAlert = true
                                    } label: {
                                        Image(systemName: "location.slash.circle.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                                if let lastLocation = mainMapViewModel.locationManager.location {
                                    if lastLocation.speed.magnitude > 100 * 0.447 && lastLocation.speed.magnitude != -1 && lastLocation.speedAccuracy.magnitude < 10 * 0.44704 && lastLocation.speedAccuracy.magnitude != -1 {
                                        Button {
                                            showSpeedAlert = true
                                        } label: {
                                            Image(systemName: "gauge.open.with.lines.needle.84percent.exclamation")
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.orange)
                                    }
                                }
                            }
                        }
                        
                    }
                    .onChange(of: locationManagerDelegate.authorizationStatus) {
                        self.authorizationStatus = locationManagerDelegate.authorizationStatus
                    }
                    
                    
                    
                case .leaderboards:
                    LeaderboardView()
                        .ignoresSafeArea()
                        .environmentObject(friendMapViewModel)
                        .environmentObject(sharedMapViewModel)
                        .background(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
                    
                case .profile:
                    ProfileView()
                        .ignoresSafeArea()
                        .environmentObject(accountViewModel)
                        .background(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
                    
                }
                if !isKeyboardVisible {
                    CustomTabBarView(selection: $selection)
                        .environmentObject(mainMapViewModel)
                        .environmentObject(friendMapViewModel)
                        .environmentObject(sharedMapViewModel)
                        .environmentObject(accountViewModel)
                        .ignoresSafeArea()
                        .background(Color(uiColor: UIColor(red: 0.23, green: 0.27, blue: 0.36, alpha: 1)))
                }
            }
        }
        
        .alert("Location Access Denied", isPresented: $showSettingsAlert) {
            Button("Dismiss") {
                dismiss()
            }
            Button("Go To Settings") {
                openAppSettings()
            }
        } message: {
            Text("In order for this app to work as inteneded, please set your \"Location\" setting to \"Always\"")
        }
        .alert(isPresented: $showSpeedAlert) {
            Alert(
                title: Text("Too Fast"),
                message: Text("Location tracking will be disabled until you are travelling less than 100 mph.")
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
//        .sheet(isPresented: $mainMapViewModel.showTappedLocation) {
//            if mainMapViewModel.tappedLocation != nil {
//                DirectionsSheetView(location: mainMapViewModel.tappedLocation!)
//                        .presentationDetents([.height(200)])
//                        .presentationDragIndicator(.visible)
//                        .presentationBackground(.thinMaterial)
//                        .presentationBackgroundInteraction(.enabled)
//            }
//            
//        }
    }
    
    private func requestLocationAccess() {
        locationManagerDelegate.requestLocationAccess()
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

