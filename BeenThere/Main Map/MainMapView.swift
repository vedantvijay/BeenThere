//
//  MapView(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import MapboxMaps

struct MainMapView: UIViewRepresentable {
    @StateObject var viewModel = MainMapViewModel()
    @Environment(\.colorScheme) var colorScheme

    func makeCoordinator() -> MainMapViewModel {
        return viewModel
    }
    
    func makeUIView(context: Context) -> MapView {
        viewModel.configureMapView(with: .zero, styleURI: StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")!)
        return viewModel.mapView!
    }

    
    func updateUIView(_ uiView: MapView, context: Context) {
        viewModel.updateMapStyleURL()
        viewModel.addGridlinesToMap()
        viewModel.checkAndAddSquaresIfNeeded()
    }
}


struct CameraState {
    var latitude: Double
    var longitude: Double
    var zoom: Double
}
