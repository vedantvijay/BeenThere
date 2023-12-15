//
//  FriendMapView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import SwiftUI
import MapboxMaps

struct FriendMapView: UIViewRepresentable {
    @EnvironmentObject var viewModel: FriendMapViewModel

    func makeCoordinator() -> FriendMapViewModel {
        return viewModel
    }
    
    func makeUIView(context: Context) -> MapView {
        viewModel.configureMapView(with: .zero, styleURI: StyleURI(rawValue: "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g")!)
        return viewModel.mapView!
    }

    func updateUIView(_ uiView: MapView, context: Context) {
//        viewModel.updateMapStyleURL()
        viewModel.addGridlinesToMap()
        viewModel.checkAndAddSquaresIfNeeded()
    }
}
