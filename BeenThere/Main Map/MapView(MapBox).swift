//
//  MapView(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import MapboxMaps

struct TestMapView: UIViewRepresentable {
    @StateObject var viewModel = TestMapViewModel()
    @Environment(\.colorScheme) var colorScheme

    func makeCoordinator() -> TestMapViewModel {
        return viewModel
    }
    
    func makeUIView(context: Context) -> MapView {
        // Make sure the viewModel creates and configures the map view
        viewModel.configureMapView(with: .zero, styleURI: StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")!)
        return viewModel.mapView!
    }

    
    func updateUIView(_ uiView: MapView, context: Context) {
        viewModel.checkAndAddSquaresIfNeeded()
        viewModel.adjustMapViewToFitSquares()
    }


}
