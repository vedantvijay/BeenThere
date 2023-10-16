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
    @ObservedObject var viewModel: MapViewModel

    func makeCoordinator() -> MapViewModel {
        return viewModel
    }

    func makeUIView(context: Context) -> MGLMapView {
        viewModel.mapView.delegate = viewModel
        viewModel.mapView.showsUserLocation = true
        viewModel.mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        return viewModel.mapView
    }

    func updateUIView(_ uiView: MGLMapView, context: Context) {
        // Code to update the UIView, if necessary.
    }
}
