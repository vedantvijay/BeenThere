//
//  FriendView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import SwiftUI
import Kingfisher

struct FriendView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: FriendMapViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel

    let username: String
    let firstName: String
    let friend: [String: Any]
    
    var body: some View {
        VStack {
                HStack(alignment: .center) {
                    Spacer()
                    if let imageUrl = accountViewModel.profileImageUrls[(friend["uid"] as? String)!] {
                        KFImage(imageUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 125, height: 125)
                            .clipShape(Circle())

                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 125, height: 125)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 10) {
                        if firstName != "" {
                            Text(firstName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Text("@\(username)")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(viewModel.locations.count == 1 ? "\(viewModel.locations.count) chunk" : "\(viewModel.locations.count) chunks")
                            .foregroundStyle(.tertiary)
                            .font(.title3)
                    }
                    Spacer()
                }
                .padding()
//                .background {
//                    RoundedRectangle(cornerRadius: 25)
//                        .frame(maxHeight: 150)
//                        .padding()
//                        .padding()
//                }
            Divider()
                .padding(.horizontal)
            ZStack(alignment: .top) {
                FriendMapView()
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding()
                    .padding()
//                    .shadow(color: colorScheme == .light ? .secondary : .secondary, radius: 3)
                    .onAppear {
                        
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
                            viewModel.locations = locations
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.locations = locations
                            }
                        }
                    }
                    .onDisappear {
                        dismiss()
                    }
//                HStack {
//                    Picker("Map Type", selection: $viewModel.mapType) {
//                        ForEach(MapType.allCases) { type in
//                            Label(String(type.rawValue).capitalized, systemImage: type == .visited ? "figure.hiking" : "camera.fill")
//                                .tag(type)
//                        }
//                    }
//                    .padding(.top)
//                    .padding(.top)
//
//                    .onChange(of: viewModel.mapType) {
//                        viewModel.mapType = viewModel.mapType
//                        viewModel.checkAndAddSquaresIfNeeded()
//                        viewModel.adjustMapViewToFitSquares()
//                    }
//                }
            }
            
        }
    }
}

//#Preview {
//    FriendView(username: Person.preview.username, firstName: Person.preview.firstName, friend: [:])
//}
