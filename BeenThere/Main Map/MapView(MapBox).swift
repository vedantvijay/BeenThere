//
//  MapView(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import MapboxMaps

struct TestMapView: UIViewRepresentable {
    @ObservedObject var viewModel = MapViewModel()
    @Environment(\.colorScheme) var colorScheme

    func makeCoordinator() -> MapViewModel {
        return viewModel
    }
    
    func makeUIView(context: Context) -> MapView {
        // Initialize the Mapbox map view
        let options = MapInitOptions(styleURI: StyleURI(rawValue: "mapbox://styles/jaredjones/clon7r77w009b01qjcmyqctc3"))
        let mapView = MapView(frame: .zero, mapInitOptions: options)
      
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Set the initial coordinates to an example location
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        // Update the view in response to SwiftUI state changes
        // Code to update the UIView, if necessary.
//        if let annotations = uiView.annotations {
//            uiView.removeAnnotations(annotations)
//        }
//        
//         If there's a tappedAnnotation in the ViewModel, add it to the map
//        if let annotation = viewModel.tappedAnnotation {
//            uiView.addAnnotation(annotation)
//        }
        
        viewModel.updateSquareColors(for: colorScheme) // Call ViewModel function to update colors based on color scheme
    }
}
