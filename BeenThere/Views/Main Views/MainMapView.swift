//
//  MapView(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import MapboxMaps

struct MainMapView: UIViewRepresentable {
//    @EnvironmentObject var accountViewModel: SettingsViewModel
    @EnvironmentObject var viewModel: MainMapViewModel
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> MapView {
        let styleURI = colorScheme == .dark ?
            StyleURI(rawValue: "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g") :
            StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")
        
        viewModel.configureMapView(with: .zero, styleURI: styleURI!)
        return viewModel.mapView!
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        // Update the map style URL only if it differs from the current style.
        let newStyleURI = colorScheme == .dark ?
            StyleURI(rawValue: "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g") :
            StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")
        
        if uiView.mapboxMap.style.uri != newStyleURI {
            uiView.mapboxMap.style.uri = newStyleURI
        }
        
        // Defer other updates until the style is loaded.
        uiView.mapboxMap.onNext(event: .styleLoaded) { _ in
            viewModel.addGridlinesToMap()
            viewModel.checkAndAddSquaresIfNeeded()
        }
    }
}
