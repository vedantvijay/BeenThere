//
//  FeedView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI

struct FeedView: View {
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Feed (coming soon)")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Label("Create Post", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
}

#Preview {
    FeedView()
}
