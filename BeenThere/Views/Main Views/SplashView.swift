//
//  SplashView.swift
//  BeenThere
//
//  Created by Jared Jones on 1/13/24.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("splashMap")
                .resizable()
                .scaledToFill()
//                .opacity(0.5)
                .ignoresSafeArea()
            Color(.background)
                .opacity(0.9
                )
                .ignoresSafeArea()
            VStack {
                Image("icon")
                    .resizable()
                    .frame(width: 125, height: 125)
                    .padding()
                Text("Been There")
                    .font(.largeTitle)
                    .fontWeight(.black)
//                    .foregroundStyle(.mutedPrimary)
                    .shadow(radius: 5)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SplashView()
}

