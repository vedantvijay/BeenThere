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
            SplashBackground()
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

struct SplashBackground: View {
    var body: some View {
        Image("splashMap")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
        Color(.background)
            .opacity(0.9
            )
            .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}

