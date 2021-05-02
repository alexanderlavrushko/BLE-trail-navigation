//
//  DrawingView.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 02/04/2021.
//

import UIKit
import CoreLocation

struct BikeLine {
    var from: CGPoint
    var to: CGPoint
}

struct BikeCircle {
    var center: CGPoint
    var radius: CGFloat
}

struct BikeTriangle {
    var p1: CGPoint
    var p2: CGPoint
    var p3: CGPoint
}

class BikeSimulationView: UIView {
//    var geoCenter: CLLocationCoordinate2D?
//    var geoRect:
    var lines = [BikeLine]()
    var lineToClosestPoint: BikeLine?
    var linesHeading = [BikeLine]()

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        UIColor.darkGray.setFill()
        context.fill(bounds)

        context.setLineDash(phase: 0, lengths: [])
        UIColor.orange.setStroke()
        lines.forEach { (line) in
            context.move(to: line.from)
            context.addLine(to: line.to)
            context.drawPath(using: .stroke)
        }

        var helperLines = [BikeLine]()
        if let lineToClosestPoint = lineToClosestPoint {
            helperLines.append(lineToClosestPoint)
        }
        context.setLineDash(phase: 0, lengths: [5, 5])
        UIColor.white.setStroke()
        helperLines.forEach { (line) in
            context.move(to: line.from)
            context.addLine(to: line.to)
            context.drawPath(using: .stroke)
        }

        context.setLineDash(phase: 0, lengths: [])
        UIColor.white.setStroke()
        linesHeading.forEach { (line) in
            context.move(to: line.from)
            context.addLine(to: line.to)
            context.drawPath(using: .stroke)
        }
    }
}
