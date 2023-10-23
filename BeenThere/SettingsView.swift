//
//  SettingsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var accountViewModel = AccountViewModel.shared
    
    var body: some View {
        Form {
            Button("Sign Out") {
                accountViewModel.signOut()
                dismiss()
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
