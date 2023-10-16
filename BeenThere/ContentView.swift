//
//  ContentView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import Mapbox
import CoreLocation
import FirebaseAuth

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    private let locationManager = CLLocationManager()

    
    var body: some View {
        ZStack {
            MapView(viewModel: mapViewModel)
                .ignoresSafeArea()
                .onAppear {
                    requestLocationAccess()
                }
            
            VStack {
                Spacer()
                HStack {
                    Button {
                        mapViewModel.toggleHeatmap()
                    } label: {
                        Image(systemName: mapViewModel.isHeatmapActive ? "eye" : "eye.slash")
                            .font(.largeTitle)
                            .bold()
                    }
                    .padding()
//                    Button {
////                        mapViewModel.toggleFlatStyle()
//                    } label: {
//                        Image(systemName: mapViewModel.isFlatStyle ? "square.fill" : "triangle.fill")
//                            .font(.largeTitle)
//                            .bold()
//                    }
                }
                
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
