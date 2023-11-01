//
//  FriendView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import SwiftUI

struct FriendView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: FriendMapViewModel

    @State private var username = ""
    
    let friend: [String: Any]
    
    var body: some View {
        VStack {
            FriendMapView()
                .ignoresSafeArea()
                .onAppear {
                    if let friendUsername = friend["username"] {
                        username = friendUsername as! String
                    }
                    viewModel.updateMapStyleURL()
                    if let locationDictionaries = friend["locations"] as? [[String: Any]] {
                        let locations: [Location] = locationDictionaries.compactMap { locationDict in
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: locationDict, options: [])
                                let location = try JSONDecoder().decode(Location.self, from: jsonData)
                                return location
                            } catch {
                                print("Error decoding location: \(error)")
                                return nil
                            }
                        }

                        // Now, `locations` is an array of `Location` instances
                        viewModel.locations = locations
                        viewModel.adjustMapViewToLocations()
                        print("LOG: \(locations)")
                        print("LOG: \(viewModel.locations)")
                    }

                }
                .onChange(of: colorScheme) {
                    viewModel.updateMapStyleURL()
                }
                .navigationTitle(username)
        }
        .onDisappear {
            dismiss()
        }
    }
}

//#Preview {
//    FriendView()
//}
