//
//  SearchBar.swift
//  BeenThere
//
//  Created by Jared Jones on 12/6/23.
//

import SwiftUI
import Kingfisher
import MapboxGeocoder
import CoreLocation

struct SearchBarView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @State private var searchText = ""
    @State private var suggestions: [GeocodedPlacemark] = []
    @State private var userLocation: CLLocationCoordinate2D?
    @FocusState private var isSearchFocused: Bool
    @Binding var isFocused: Bool

    var geocoder = Geocoder.shared
    let locationManager = CLLocationManager()
    @State var showProfile = false
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.rowBackground)
                    .frame(maxHeight: 65)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(uiColor: UIColor(red: 0.48, green: 0.49, blue: 0.55, alpha: 1)), lineWidth: 2)
                    )
                HStack {
                    TextField("Not Interactive Yet", text: $searchText)
                        .disabled(true)
                        .focused($isSearchFocused)
                        .padding(.leading, 40)
                        .font(.title2)
                        .overlay(
                            HStack {
                                Image("magnifyingGlass")
                                    .foregroundColor(Color.mutedPrimary)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                        )
                        .onChange(of: isSearchFocused) {
                            isFocused = isSearchFocused
                        }
                    Button {
                        showProfile = true
                    } label: {
                        if let imageUrl = viewModel.profileImageUrl {
                            KFImage(imageUrl)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(5)
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(5)
                                .foregroundStyle(Color.mutedPrimary)
                        }
                    }
                    
                    
                }
                .padding()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .padding(.horizontal)
    }
}

//#Preview {
//    SearchBar()
//}
