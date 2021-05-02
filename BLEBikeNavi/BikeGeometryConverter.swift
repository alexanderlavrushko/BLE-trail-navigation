//
//  BikeGeometryConverter.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 05/04/2021.
//

import Foundation
import CoreGraphics
import MapKit

class BikeGeometryConverter {
    let bikeWidthPixels: Double
    let bikeHeightPixels: Double
    let bikeMetersPerPixel: Double
    let bikeScreenCenter: CGPoint
    let mapCenter: MKMapPoint
    let mapPointsPerMeter: Double
    let bikePointsPerPixel: Double
    let bikePixelsPerPoint: Double
    let bikeWidthMapPoints: Double
    let bikeHeightMapPoints: Double
    let bikeTopLeft: MKMapPoint
    let bikeRect: MKMapRect
    let forwardAngle: CLLocationDegrees

    init(screenWidth: Double, screenHeight: Double, metersPerPixel: Double, screenCenter: CGPoint, mapCenter: MKMapPoint, forwardAngle: CLLocationDegrees) {
        bikeWidthPixels = screenWidth
        bikeHeightPixels = screenHeight
        bikeMetersPerPixel = metersPerPixel
        bikeScreenCenter = screenCenter
        self.mapCenter = mapCenter

        mapPointsPerMeter = MKMapPointsPerMeterAtLatitude(mapCenter.coordinate.latitude)
        bikePointsPerPixel = bikeMetersPerPixel * mapPointsPerMeter
        bikePixelsPerPoint = 1 / bikePointsPerPixel
        bikeWidthMapPoints = bikeWidthPixels * bikePointsPerPixel
        bikeHeightMapPoints = bikeHeightPixels * bikePointsPerPixel
        bikeTopLeft = MKMapPoint(x: mapCenter.x - bikePointsPerPixel * Double(bikeScreenCenter.x),
                                 y: mapCenter.y - bikePointsPerPixel * Double(bikeScreenCenter.y))
        bikeRect = MKMapRect(origin: bikeTopLeft, size: MKMapSize(width: bikeWidthMapPoints, height: bikeHeightMapPoints))
        self.forwardAngle = forwardAngle
    }

    private func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + byDegrees * CGFloat(Double.pi / 180.0) // convert it to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }

    func convertPoint(_ mapPoint: MKMapPoint) -> CGPoint {
        let x = (mapPoint.x - bikeTopLeft.x) * bikePixelsPerPoint
        let y = (mapPoint.y - bikeTopLeft.y) * bikePixelsPerPoint
        let cgPointRotated = rotatePoint(target: CGPoint(x: x, y: y), aroundOrigin: bikeScreenCenter, byDegrees: CGFloat(-forwardAngle))
        return cgPointRotated
    }
}
