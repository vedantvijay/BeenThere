//
//  CustomTabView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/1/23.
//

import SwiftUI

enum Tab {
    case settings, feed, map, leaderboards, profile
}

struct CustomTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: SettingsViewModel
//    @EnvironmentObject var friendMapViewModel: FriendMapViewModel
//    @EnvironmentObject var sharedMapViewModel: SharedMapViewModel
    @Binding var selection: Tab
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: {
                selection = .settings
            }) {
                Image(systemName: selection == .settings ? "gearshape.fill" : "gearshape")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding()
                    .foregroundColor(selection == .settings ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                    .offset(y: -10)

            }
            .frame(maxWidth: .infinity)
            
            
            
            
            Button(action: {
                selection = .feed
            }) {
                Image(systemName: selection == .settings ? "rectangle.3.group.bubble.left.fill" : "rectangle.3.group.bubble.left")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding()
                    .foregroundColor(selection == .feed ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                    .offset(y: -10)

            }
            .frame(maxWidth: .infinity)
            ZStack {
                Circle()
                    .frame(width: 66, height: 66)
                    .foregroundStyle(Material.bar)
                Button(action: {
                    selection = .map
                }) {
                    Image(systemName: selection == .map ? "safari.fill" : "safari")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(selection == .map ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                }
            }
            .offset(y: -30) // Adjust this to move up or down
            
            
            
            
            
            
            Button(action: {
                selection = .leaderboards
            }) {
                Image(systemName: selection == .leaderboards ? "chart.bar.fill" : "chart.bar")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding()
                    .foregroundColor(selection == .leaderboards ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                    .offset(y: -10)
            }
            .frame(maxWidth: .infinity)
            Button(action: {
                selection = .profile
            }) {
                ZStack {
                    Image(systemName: selection == .profile ? "person.fill" : "person")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(selection == .profile ? colorScheme == .light ? .black : .white : Color(uiColor: UIColor.lightGray))
                    
                    // Notification Indicator
                    if viewModel.receivedFriendRequests.count > 0 && selection != .profile {
//                        Circle()
                        Image(systemName: "bell.badge.circle.fill")
                            .foregroundColor(.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 15, y: -15)
                    }
                }
                .padding()
                .offset(y: -10)
            }
            .frame(maxWidth: .infinity)
        }
        
    }
}

#Preview {
    CustomTabView(selection: .constant(.map))
}
