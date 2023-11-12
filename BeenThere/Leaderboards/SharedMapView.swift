//
//  SharedMapView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/31/23.
//

import SwiftUI
import MapboxMaps

struct SharedMapView: UIViewRepresentable {
    @EnvironmentObject var viewModel: SharedMapViewModel
    @Environment(\.colorScheme) var colorScheme

    func makeCoordinator() -> SharedMapViewModel {
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

//
//#Preview {
//    SharedMapView()
//}
