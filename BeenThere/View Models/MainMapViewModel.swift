//
//  MapViewModel(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import UIKit
import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation

class MainMapViewModel: TemplateMapViewModel {
    let directions = Directions(credentials: .init(accessToken: "pk.eyJ1IjoiamFyZWRqb25lcyIsImEiOiJjbG9ubTFlY2Eya3ZtMnRxZWY1MmFjaXJ3In0.OpGzi3aW6fpFmuwVu53TjQ"))
    var routeResponse: RouteResponse?
    var routeOptions: NavigationRouteOptions? // Add this property

    
    // Closure to inform when navigation should start
    var onNavigationStart: ((Route) -> Void)?
    
    func requestDirections(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let waypoints = [
            Waypoint(coordinate: origin, name: "Start"),
            Waypoint(coordinate: destination, name: "Finish")
        ]
        let routeOptions = NavigationRouteOptions(waypoints: waypoints)
        
        directions.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print("Error calculating directions: \(error)")
            case .success(let response):
                self?.routeResponse = response
                guard let route = response.routes?.first else { return }
                self?.onNavigationStart?(route)
            }
        }
    }
}

struct NavigationViewControllerRepresentable: UIViewControllerRepresentable {
    let route: Route
    let routeOptions: NavigationRouteOptions
    let routeResponse: RouteResponse
        let routeIndex: Int

    func makeUIViewController(context: Context) -> NavigationViewController {
        print("Route: \(route)")
            print("RouteOptions: \(routeOptions)")
            print("RouteResponse: \(routeResponse)")
            print("RouteIndex: \(routeIndex)")
            let navigationService = MapboxNavigationService(routeResponse: routeResponse, routeIndex: routeIndex, routeOptions: routeOptions)
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            return NavigationViewController(for: routeResponse, routeIndex: routeIndex, routeOptions: routeOptions, navigationOptions: navigationOptions)
        }

        func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {
            // Update logic if needed
        }

}
