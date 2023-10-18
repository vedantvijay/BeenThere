//
//  SettingsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/18/23.
//

import SwiftUI

struct SettingsView: View {    
    var body: some View {
        Form {
            Button("Delete All Data") {
                PersistenceController.shared.deleteCloudData { error in
                    if let error = error {
                        print("Error deleting cloud data: \(error.localizedDescription)")
                    } else {
                        print("Cloud data successfully deleted!")
                    }
                }          
            }
        }
    }
}

//#Preview {
//    SettingsView()
//}
