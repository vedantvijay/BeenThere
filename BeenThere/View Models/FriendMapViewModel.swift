//
//  FriendMapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI

class FriendMapViewModel: TemplateMapViewModel {
    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
    override func observeLocations() { }
    
    override func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView?.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let cameraState = self?.mapView?.cameraState else { return }
            self?.lastCameraCenter = cameraState.center
            self?.lastCameraZoom = cameraState.zoom
            self?.lastCameraPitch = cameraState.pitch
        }
        if let center = lastCameraCenter, let zoom = lastCameraZoom, let pitch = lastCameraPitch {
            let lastState = CameraOptions(center: center, zoom: zoom, pitch: pitch)
            mapView?.camera.ease(to: lastState, duration: 0.5)
        } else {
            mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
        }
        mapView?.ornaments.scaleBarView.isHidden = true
        mapView?.isOpaque = false
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.location.options.puckType = .puck2D(.makeDefault(showBearing: true))
        self.annotationManager = mapView?.annotations.makePointAnnotationManager()
        
        mapView?.ornaments.logoView.alpha = 0.1
        mapView?.ornaments.attributionButton.alpha = 0.1

        mapView?.ornaments.options.logo.position = .bottomLeft
        mapView?.ornaments.options.attributionButton.position = .bottomRight
        mapView?.ornaments.options.logo.margins = CGPoint(x: 10, y: 10)
        mapView?.ornaments.options.attributionButton.margins = CGPoint(x: 0, y: 10)
        mapView?.ornaments.scaleBarView.isHidden = true

    }
}
