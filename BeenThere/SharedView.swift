//
//  SharedView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/1/23.
//

import SwiftUI

struct SharedView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: SharedMapViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    var userLocations: [Location] {
        let tempLocations = accountViewModel.users.flatMap { user -> [Location] in
            guard let locationDictionaries = user["locations"] as? [[String: Double]] else {
                return []
            }
            return locationDictionaries.compactMap {
                guard let lowLatitude = $0["lowLatitude"],
                      let highLatitude = $0["highLatitude"],
                      let lowLongitude = $0["lowLongitude"],
                      let highLongitude = $0["highLongitude"] else {
                    return nil
                }
                return Location(lowLatitude: lowLatitude,
                                highLatitude: highLatitude,
                                lowLongitude: lowLongitude,
                                highLongitude: highLongitude)
            }
        }
        let finalLocations = Array(Set(tempLocations))
        return finalLocations
    }
    
    var body: some View {
        ZStack(alignment: .top) {
                SharedMapView()
                    .ignoresSafeArea()
                    .onAppear {
                        viewModel.updateMapStyleURL()
                        viewModel.locations = userLocations
                    }
                    .onChange(of: colorScheme) {
                        viewModel.updateMapStyleURL()
                    }
                Text("Shared Map")
                .font(.largeTitle)
                .fontWeight(.black)
//                .shadow(color: colorScheme == .light ? .secondary : .white, radius: 1)
            }
            
            
        
        .onDisappear {
            dismiss()
        }
    }
}

//#Preview {
//    SharedView()
//}
