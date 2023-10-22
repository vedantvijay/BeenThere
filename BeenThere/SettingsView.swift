//
//  SettingsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var accountViewModel = AccountViewModel.shared
    
    var body: some View {
        Form {
            Button("Sign Out") {
                accountViewModel.signOut()
            }
            NavigationLink("Delete Account") {
                ConfirmDeleteAccountView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
