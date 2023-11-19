//
//  MapViewModel(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI

class MainMapViewModel: TemplateMapViewModel {
}



struct Location: Codable, Hashable {
    var lowLatitude: Double
    var highLatitude: Double
    var lowLongitude: Double
    var highLongitude: Double
}
