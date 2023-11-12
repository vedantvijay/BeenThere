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
    @Environment(\.colorScheme) var colorScheme

    func makeCoordinator() -> FriendMapViewModel {
        return viewModel
    }
    
    func makeUIView(context: Context) -> MapView {
        viewModel.configureMapView(with: .zero, styleURI: StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")!)
        return viewModel.mapView!
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        viewModel.updateMapStyleURL()
    }
}
