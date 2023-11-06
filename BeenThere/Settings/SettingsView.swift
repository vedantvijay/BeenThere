//
//  AccountView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import AlertToast

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @AppStorage("appState") var appState = "opening"

    @State private var showDeleteAccount = false

    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    
//    let darkModeColors = [Color.black, Color.gray, Color.purple, Color.blue]
//        let lightModeColors = [Color.white, Color.yellow, Color.green, Color.pink]
//    
//    @State private var tempDarkColor: Color
//    @State private var tempLightColor: Color
//    @AppStorage("darkColor") var darkColorString = ""
//    @AppStorage("lightColor") var lightColorString = ""
//
//    init() {
//          let darkColorString = AppStorage(wrappedValue: "20,20,20", "darkColor")
//          let lightColorString = AppStorage(wrappedValue: "100,100,100", "lightColor")
//
//          let initialDarkColor = Color(rgbaString: darkColorString.wrappedValue)
//          let initialLightColor = Color(rgbaString: lightColorString.wrappedValue)
//          
//          _tempDarkColor = State(initialValue: initialDarkColor)
//          _tempLightColor = State(initialValue: initialLightColor)
//      }
    
    @State private var showFriendView = false
    
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
//                    ColorPicker("Dark Mode Color", selection: $tempDarkColor)
//                        .onChange(of: tempDarkColor) {
//                            darkColorString = tempDarkColor.rgbaString
//                        }
//                        
//                    ColorPicker("Light Mode Color", selection: $tempLightColor)
//                        .onChange(of: tempLightColor) {
//                            lightColorString = tempLightColor.rgbaString
//                        }
                }
                Section {
                    NavigationLink("Manage Friends") {
                        ManageFriendsView()
                    }
                }
                Section {
                    NavigationLink("Change Username") {
                        ChangeUsernameView()
                    }
                }
                Section {
                    Button("Sign Out") {
                        viewModel.signOut()
                        dismiss()
                        appState = "notAuthenticated"
                    }
                    NavigationLink("Delete Account") {
                        ConfirmDeleteAccountView()
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toast(isPresenting: $viewModel.usernameChanged) {
                AlertToast(displayMode: .alert, type: .complete(.green), title: "Username changed")
            }
        }
    }
}

//extension Color {
//    init(rgbaString: String) {
//        let components = rgbaString.split(separator: ",").compactMap { Double($0) }
//        self.init(
//            .sRGB,
//            red: components.indices.contains(0) ? components[0] / 255.0 : 1.0,
//            green: components.indices.contains(1) ? components[1] / 255.0 : 1.0,
//            blue: components.indices.contains(2) ? components[2] / 255.0 : 1.0,
//            opacity: 1.0 // Always full opacity
//        )
//    }
//    
//    var rgbaString: String {
//        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
//            return "0,0,0,1" // Return full opacity if color components are not available
//        }
//        let red = Int(components[0] * 255)
//        let green = Int(components[1] * 255)
//        let blue = Int(components[2] * 255)
//        return "\(red),\(green),\(blue),255" // Always return 255 for alpha component
//    }
//}
//
//extension UIColor {
//    convenience init(rgbaString: String) {
//        let components = rgbaString.split(separator: ",").compactMap { CGFloat(Double($0) ?? 0) / 255.0 }
//        self.init(
//            red: components.indices.contains(0) ? components[0] : 1.0,
//            green: components.indices.contains(1) ? components[1] : 1.0,
//            blue: components.indices.contains(2) ? components[2] : 1.0,
//            alpha: 1.0 // Always full opacity
//        )
//    }
//    
//    var rgbaString: String {
//        var red: CGFloat = 0
//        var green: CGFloat = 0
//        var blue: CGFloat = 0
//        getRed(&red, green: &green, blue: &blue, alpha: nil)
//        
//        let redInt = Int(red * 255)
//        let greenInt = Int(green * 255)
//        let blueInt = Int(blue * 255)
//        return "\(redInt),\(greenInt),\(blueInt),255" // Always return 255 for alpha component
//    }
//}


//
//#Preview {
//    AccountView(viewModel: AccountViewModel)
//}
