//
//  ContentView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import Mapbox
import CoreLocation

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    private let locationManager = CLLocationManager()
    
    
    var body: some View {
        MapView(viewModel: mapViewModel)
            .ignoresSafeArea()
            .onAppear {
                requestLocationAccess()
            }
    }
    
    private func requestLocationAccess() {
        locationManager.requestAlwaysAuthorization()
    }
}


//#Preview {
//    ContentView()
//}
