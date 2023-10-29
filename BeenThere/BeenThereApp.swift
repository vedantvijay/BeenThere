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

@main
struct BeenThereApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authViewModel = AuthViewModel()
    @AppStorage("isAuthenticated") var isAuthenticated = false
    @AppStorage("username") var username = ""
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                if username != "" {
                    ContentView()
                        .statusBarHidden()
                } else {
                    CreateUsernameView()
                        .statusBarHidden()
                }
            } else {
                LoginView()
                    .statusBarHidden()
            }
        }
        .environmentObject(authViewModel)
    }
}

