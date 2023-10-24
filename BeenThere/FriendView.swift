//
//  FriendView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import SwiftUI

struct FriendView: View {
    @ObservedObject var viewModel = FriendMapViewModel.shared
    
    let friendUID: String
    
    var body: some View {
        VStack {
            FriendMapView()
        }
        .onAppear {
            viewModel.setUpFirestoreListener(friendUID: friendUID)
        }
    }
}

//#Preview {
//    FriendView()
//}
