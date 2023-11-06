//
//  BeenThereApp.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @AppStorage("isAuthenticated") var isAuthenticated = false
    
    var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                print("Logged in as: \(user.uid)")
                self.isSignedIn = true
                self.isAuthenticated = true
            } else {
                print("Not logged in.")
                self.isSignedIn = false
                self.isAuthenticated = false
            }
        }
    }
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

enum AppUIState {
    case opening
    case authenticated
    case notAuthenticated
    case createUser
}

@main
struct BeenThereApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var accountViewModel = SettingsViewModel()
    @AppStorage("appState") var appState = "notAuthenticated"
    @AppStorage("username") var username = ""
    
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case "authenticated":
                    ContentView()
                        .statusBarHidden()
                case "createUser":
                    CreateUsernameView()
                        .statusBarHidden()
                case "notAuthenticated":
                    LoginView()
                        .statusBarHidden()
                default:
                    LoginView()
                        .statusBarHidden()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    determineUIState()
                }
                if username == "" {
                    accountViewModel.signOut()
                }
                
            }
        }
        .environmentObject(accountViewModel)
        .environmentObject(authViewModel)
    }
    
    func determineUIState() {
        Auth.auth().addStateDidChangeListener() { auth, user in
            if authViewModel.isAuthenticated && authViewModel.isSignedIn && user != nil && auth.currentUser != nil {
                if username != "" {
                    appState = "authenticated"
                } else {
                    appState = "createUser"
                }
            } else {
                accountViewModel.signOut()
                appState = "notAuthenticated"
            }
        }
    }
}


