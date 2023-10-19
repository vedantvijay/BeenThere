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
    @AppStorage("chunksCount") var chunksCount: Int = 0
    
    
    var body: some View {
        ZStack {
            MapView(viewModel: mapViewModel)
                .ignoresSafeArea()
                .onAppear {
                    requestLocationAccess()
                    mapViewModel.updateChunksCount()
                }
            VStack {
                Spacer()
                // I want to display the total number of chunks/squares the user has been to
                Text("Chunks: \(chunksCount - 1)")
                    .bold()
                    .foregroundStyle(.black)
            }
        }
        
    }
    
    private func requestLocationAccess() {
        locationManager.requestAlwaysAuthorization()
    }
}


//#Preview {
//    ContentView()
//}
