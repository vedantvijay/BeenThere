//
//  CustomTabView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/1/23.
//

import SwiftUI

struct CustomTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                selection = 1
            }) {
                Image(systemName: selection == 1 ? "person.fill" : "person")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .padding()
                    .foregroundColor(selection == 1 ? colorScheme == .light ? .black : .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            
            ZStack {
                Circle()
                    .foregroundStyle(.ultraThinMaterial)
//                    .foregroundColor(colorScheme == .light ? .white : .black)
                    .frame(width: 67, height: 67)
//                    .shadow(radius: 3)
                
                Button(action: {
                    selection = 2
                }) {
                    Image(systemName: selection == 2 ? "safari.fill" : "safari")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(selection == 2 ? colorScheme == .light ? .black : .white : .secondary)
                }
            }
            .offset(y: -20) // Adjust this to move up or down
            
            Button(action: {
                selection = 3
            }) {
                Image(systemName: selection == 3 ? "chart.bar.fill" : "chart.bar")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .padding()
                    .foregroundColor(selection == 3 ? colorScheme == .light ? .black : .white : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    CustomTabView(selection: .constant(1))
}
