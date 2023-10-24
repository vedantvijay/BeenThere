//
//  FriendMapView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import SwiftUI
import CoreLocation
import Mapbox

struct FriendMapView: UIViewRepresentable {
    @ObservedObject var viewModel = FriendMapViewModel.shared

    func makeCoordinator() -> FriendMapViewModel {
        return viewModel
    }

    func makeUIView(context: Context) -> MGLMapView {
        viewModel.mapView.delegate = viewModel
        viewModel.mapView.showsUserLocation = true
        viewModel.mapView.attributionButtonPosition = .topRight
        viewModel.mapView.logoViewPosition = .topLeft
        viewModel.mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        
        // Disable autoresizing mask translation
        viewModel.mapView.logoView.translatesAutoresizingMaskIntoConstraints = false
        viewModel.mapView.attributionButton.translatesAutoresizingMaskIntoConstraints = false

        // Set constraints for the logoView to ignore safe areas
        NSLayoutConstraint.activate([
            viewModel.mapView.logoView.topAnchor.constraint(equalTo: viewModel.mapView.topAnchor, constant: 20), // 8 points from the top
            viewModel.mapView.logoView.leftAnchor.constraint(equalTo: viewModel.mapView.leftAnchor, constant: 20) // 8 points from the left
        ])

        // Set constraints for the attributionButton to ignore safe areas
        NSLayoutConstraint.activate([
            viewModel.mapView.attributionButton.topAnchor.constraint(equalTo: viewModel.mapView.topAnchor, constant: 20), // 8 points from the top
            viewModel.mapView.attributionButton.rightAnchor.constraint(equalTo: viewModel.mapView.rightAnchor, constant: -20) // 8 points from the right
        ])
        
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
