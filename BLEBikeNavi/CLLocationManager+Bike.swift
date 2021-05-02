//
//  BikeLocationManager.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 05/04/2021.
//

import UIKit
import CoreLocation

extension CLLocationManager {
    var hasAuthorization: Bool {
        let status = safeAuthorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var safeAuthorizationStatus: CLAuthorizationStatus {
        var status = CLAuthorizationStatus.notDetermined
        if #available(iOS 14.0, *) {
            status = authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        return status
    }

    func setupDefaultsForBike() {
        activityType = .fitness//.otherNavigation
        desiredAccuracy = kCLLocationAccuracyBest
        distanceFilter = kCLDistanceFilterNone //3
        headingFilter = 10
        allowsBackgroundLocationUpdates = true
    }

    func startUpdatingForBike() {
        startUpdatingLocation()
        startUpdatingHeading()
    }

    func stopUpdatingForBike() {
        stopUpdatingLocation()
        stopUpdatingHeading()
    }
}
