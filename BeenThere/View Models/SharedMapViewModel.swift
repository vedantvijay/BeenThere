//
//  SharedMapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 11/1/23.
//

import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI

class SharedMapViewModel: TemplateMapViewModel {
        
    override func adjustMapViewToFitSquares() { }
    override func observeLocations() { }
    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }

    override func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
        mapView?.isOpaque = false
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.location.options.puckType = .puck2D(.makeDefault(showBearing: true))
        mapView?.ornaments.scaleBarView.isHidden = true
        self.annotationManager = mapView?.annotations.makePointAnnotationManager()
        mapView?.ornaments.logoView.alpha = 0.1
        mapView?.ornaments.attributionButton.alpha = 0.1
        addGridlinesToMap()
        centerMapOnLocation(location: locationManager.location ?? CLLocation(latitude: 50, longitude: 50))
    }

    func centerMapOnLocation(location: CLLocation) {
        guard let mapView = mapView else { return }
        let coordinate = location.coordinate
        let zoomLevel = 2
        let cameraOptions = CameraOptions(center: coordinate, zoom: Double(zoomLevel))
        mapView.mapboxMap.setCamera(to: cameraOptions)
    }
}

