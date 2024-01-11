//
//  LeaderboardView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/28/23.
//

import Kingfisher
import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @EnvironmentObject var friendMapViewModel: FriendMapViewModel
    @EnvironmentObject var sharedMapViewModel: SharedMapViewModel
    @State private var leaderboardScope = "friends"
    let scopeOptions = ["friends", "global"]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Scope", selection: $leaderboardScope) {
                    ForEach(scopeOptions, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onDisappear {
                    viewModel.updateProfileImages()
                }
                .onAppear {
                    if viewModel.users.count == 0 {
                        viewModel.setUpFirestoreListener()
                    }
                }
                Spacer()
                ScrollViewReader { proxy in
                    List {
                        if leaderboardScope == "friends" {
                            if !viewModel.sortedFriendsByLocationCount().isEmpty {
                                ForEach(viewModel.sortedFriendsByLocationCount().indices, id: \.self) { index in
                                    let friend = viewModel.sortedFriendsByLocationCount()[index]
                                    NavigationLink(destination: FriendView(username: friend["username"] as? String ?? "", firstName: friend["firstName"] as? String ?? "", friend: friend)) {
                                        HStack {
                                            Text("\(index + 1).")
                                                .bold()
                                                .padding(.trailing, 3)
                                                .font(.title2)
                                            if let friendUID = friend["uid"] as? String {
                                                if let imageUrl = viewModel.profileImageUrls[friendUID] {
                                                    KFImage(imageUrl)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .clipShape(Circle())
                                                        .frame(width: 50, height: 50)
                                                        .padding(.trailing, 10)
                                                } else {
                                                    Image(systemName: "person.crop.circle")
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                        .foregroundStyle(.secondary)
                                                        .padding(.trailing, 5)
                                                }
                                            }
                                            if let friendUsername = friend["username"] as? String {
                                                if let friendFirstName = friend["firstName"] as? String, let friendLastName = friend["lastName"] as? String {
                                                    if friendFirstName != "" {
                                                        Text("\(friendFirstName) \(friendLastName)")
                                                            .fontWeight(friendUsername == viewModel.username ? .bold : .regular)
                                                            .padding(.trailing, 4)
                                                            .font(.title2)
                                                    }
                                                    
                                                } else {
                                                    Text("@\(friendUsername)")
                                                        .italic()
                                                        .foregroundStyle(.secondary)
                                                }
                                                
                                            }
                                            
                                            Spacer()
                                            
                                            if let locations = friend["locations"] as? [[String: Any]] {
                                                Text("\(locations.count)")
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        .font(.title3)
                                    }
                                }
                            } else {
                                Text("You have no friends added yet.")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        else if leaderboardScope == "global" {
//                            Section {
//                                NavigationLink("Shared Map") {
//                                    SharedView(viewModel: sharedMapViewModel, accountViewModel: viewModel)
//                                }
//                            }
                            
                            ForEach(viewModel.sortedUsersByLocationCount().indices, id: \.self) { index in
                                let person = viewModel.sortedUsersByLocationCount()[index]
                                if let personUsername = person["username"] as? String,
    //                               let personUID = person["uid"] as? String,
                                   let personLocations = person["locations"] as? [[String: Any]] {
                                    HStack {
                                        // Display the rank
                                        Text("\(index + 1).")
                                            .bold()
                                            .padding(.trailing, 5) // Add some padding to separate the rank from the name
                                        
                                        
                                        
                                        if let friendUID = person["uid"] as? String {
                                            if let imageUrl = viewModel.profileImageUrls[friendUID] {
                                                KFImage(imageUrl)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                                    .padding(.trailing, 10)
                                            } else {
                                                Image(systemName: "person.crop.circle")
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundStyle(.secondary)
                                                    .padding(.trailing, 5)

                                            }
                                            
                                            if let friendUsername = person["username"] as? String {
                                                if let personFirstName = person["firstName"] as? String {
                                                    if personFirstName != "" {
                                                        Text(personFirstName)
                                                            .fontWeight(friendUID == viewModel.uid ? .bold : .regular)
                                                            .padding(.trailing, 4)
                                                    } else {
                                                        Text("@\(friendUsername)")
                                                            .italic()
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                        Spacer()
                                        Text("\(personLocations.count)")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .font(.title3)
                                }
                            }
                            .onAppear {
                                // Scroll to the user's position
                                if let userIndex = viewModel.sortedUsersByLocationCount().firstIndex(where: { $0["username"] as? String == viewModel.username }) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            proxy.scrollTo(userIndex, anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(friendMapViewModel)
        .environmentObject(sharedMapViewModel)
        .environmentObject(viewModel)
    }
}


//#Preview {
//    LeaderboardView()
//}
