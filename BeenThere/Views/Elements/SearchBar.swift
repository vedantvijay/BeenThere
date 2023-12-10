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

struct SearchBar: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @State private var searchText = ""
    @State private var suggestions: [GeocodedPlacemark] = []
    @State private var userLocation: CLLocationCoordinate2D?
    @FocusState private var isSearchFocused: Bool
    @Binding var showNavigation: Bool

    var geocoder = Geocoder.shared
    let locationManager = CLLocationManager()
    @State var showProfile = false
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)))
                    .frame(maxHeight: 65)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(uiColor: UIColor(red: 0.48, green: 0.49, blue: 0.55, alpha: 1)), lineWidth: 2)
                    )
                HStack {
                    TextField("Search here", text: $searchText)
                        .focused($isSearchFocused)
                        .padding(.horizontal, 50)
                        .font(.title2)
                        .overlay(
                            HStack {
                                Image("magnifyingGlass")
                                    .foregroundColor(.white)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                        )
                    Button {
                        showProfile = true
                    } label: {
                        if let imageUrl = viewModel.profileImageUrl {
                            KFImage(imageUrl)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .padding(5)
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .padding(5)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    
                }
                .padding()
            }
            if isSearchFocused && !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(suggestions, id: \.name) { place in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(place.name)
                                        .bold()
                                    Text(place.qualifiedName ?? "")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                        .lineLimit(1)
                                    
                                }
                                Spacer()
                                Button {
                                    selectPlace(place)
                                } label: {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                        .font(.largeTitle)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
        }
        .onChange(of: searchText) {
            fetchSuggestions(for: searchText)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .padding(.horizontal)
        .onAppear {
            requestLocation()
        }
    }
    
    func selectPlace(_ place: GeocodedPlacemark) {
        self.searchText = place.qualifiedName ?? ""
        self.showNavigation = true
        // Add additional actions here, like closing the search, navigating, etc.
        // Example: self.isSearchFocused = false
    }
    
    func fetchSuggestions(for query: String) {
        let options = ForwardGeocodeOptions(query: query)
        if let location = userLocation {
            // options.allowedISOCountryCodes = ["US"]
            options.focalLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        }
        
        _ = geocoder.geocode(options) { (placemarks, attribution, error) in
            DispatchQueue.main.async {
                var uniquePlacemarks = [GeocodedPlacemark]()
                var seen: Set<String> = []

                for placemark in placemarks ?? [] {
                    // Safely unwrap formattedName or use a fallback value (e.g., an empty string)
                    let address = placemark.qualifiedName ?? ""

                    // Skip if the formattedName is empty (or your defined fallback)
                    guard !address.isEmpty else { continue }

                    if !seen.contains(address) {
                        seen.insert(address)
                        uniquePlacemarks.append(placemark)
                    }
                }

                self.suggestions = uniquePlacemarks
            }
        }
    }


    private func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        userLocation = locationManager.location?.coordinate
    }
}

//#Preview {
//    SearchBar()
//}
