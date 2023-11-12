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
//        viewModel.addGridlinesToMap()
//        viewModel.checkAndAddSquaresIfNeeded()
    }
}

//struct FriendMapView: UIViewRepresentable {
//    @EnvironmentObject var viewModel: FriendMapViewModel
//    func makeCoordinator() -> FriendMapViewModel {
//        return viewModel
//    }
//
//    func makeUIView(context: Context) -> MGLMapView {
//        viewModel.mapView.delegate = viewModel
//        viewModel.mapView.showsUserLocation = true
//        viewModel.mapView.attributionButtonPosition = .topRight
//        viewModel.mapView.logoViewPosition = .topLeft
//        viewModel.adjustMapViewToLocations()
//        viewModel.mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)
//        
//        // Disable autoresizing mask translation
//        viewModel.mapView.logoView.translatesAutoresizingMaskIntoConstraints = false
//        viewModel.mapView.attributionButton.translatesAutoresizingMaskIntoConstraints = false
//
//        // Set constraints for the logoView to ignore safe areas
//        NSLayoutConstraint.activate([
//            viewModel.mapView.logoView.topAnchor.constraint(equalTo: viewModel.mapView.topAnchor, constant: 20), // 8 points from the top
//            viewModel.mapView.logoView.leftAnchor.constraint(equalTo: viewModel.mapView.leftAnchor, constant: 20) // 8 points from the left
//        ])
//
//        // Set constraints for the attributionButton to ignore safe areas
//        NSLayoutConstraint.activate([
//            viewModel.mapView.attributionButton.topAnchor.constraint(equalTo: viewModel.mapView.topAnchor, constant: 20), // 8 points from the top
//            viewModel.mapView.attributionButton.rightAnchor.constraint(equalTo: viewModel.mapView.rightAnchor, constant: -20) // 8 points from the right
//        ])
//        
//        return viewModel.mapView
//    }
//
//    
//    func updateUIView(_ uiView: MGLMapView, context: Context) {
//        // Code to update the UIView, if necessary.
//        if let annotations = uiView.annotations {
//            uiView.removeAnnotations(annotations)
//        }
//        
//        // If there's a tappedAnnotation in the ViewModel, add it to the map
//        if let annotation = viewModel.tappedAnnotation {
//            uiView.addAnnotation(annotation)
//        }
//    }
//}
