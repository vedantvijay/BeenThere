//
//  MapView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import Mapbox
import CoreLocation

struct MapView: UIViewRepresentable {
    @ObservedObject var viewModel = MapViewModel.shared

    func makeCoordinator() -> MapViewModel {
        return viewModel
    }

    func makeUIView(context: Context) -> MGLMapView {
        viewModel.mapView.delegate = viewModel
        viewModel.mapView.showsUserLocation = true
        viewModel.mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 1.0 // default is 0.5 but you can increase it if needed
        viewModel.mapView.addGestureRecognizer(longPress)
        
        return viewModel.mapView
    }
    
    func updateUIView(_ uiView: MGLMapView, context: Context) {
        // Code to update the UIView, if necessary.
        if let annotations = uiView.annotations {
            uiView.removeAnnotations(annotations)
        }
        
        // If there's a tappedAnnotation in the ViewModel, add it to the map
        if let annotation = viewModel.tappedAnnotation {
            uiView.addAnnotation(annotation)
        }
    }
}
