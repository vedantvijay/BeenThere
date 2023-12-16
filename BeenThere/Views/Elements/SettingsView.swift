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
    @EnvironmentObject var viewModel: AccountViewModel
    @AppStorage("appState") var appState = "opening"

    @State private var showDeleteAccount = false
    @Binding var navigationPath: NavigationPath

    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    @State private var showFriendView = false
    
    var body: some View {
            VStack(alignment: .leading) {
                SettingsItemView(icon: Image("person"), text: "Edit Profile", destinationID: editProfileID, navigationPath: $navigationPath)
                Divider()
                SettingsItemView(icon: Image("people"), text: "Manage Friends", destinationID: manageFriendsID, navigationPath: $navigationPath)
                Divider()
//                SettingsItemView(icon: Image("share"), text: "Sharing", destinationID: sharingID, navigationPath: $navigationPath)
                SettingsItemView(icon: Image(systemName: "person.slash.fill"), text: "Delete Account", destinationID: deleteAccountID, navigationPath: $navigationPath)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(Color(uiColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)))
            )
        
    }
}

//#Preview {
//    SettingsView()
//}
