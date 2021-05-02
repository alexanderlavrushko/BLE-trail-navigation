//
//  Settings.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 02/05/2021.
//

import Foundation

enum PositionSource {
    case real
    case mapViewCenter
}

enum UpSource {
    case northUp
    case systemCourseUp
    case customCourseUp
    case headingUp
}

enum SimulatedAccuracy {
    case good
    case bad
}

protocol SettingsDelegate: AnyObject {
    func didChangeMetersPerPixel(from oldValue: Double, to newValue: Double)
    func didChangeUpSource(from oldValue: UpSource, to newValue: UpSource)
    func didChangeGpsSource(from oldValue: PositionSource, to newValue: PositionSource)
}

class Settings {
    private(set) static var instance: Settings?

    static func create() {
        guard instance == nil else { return }
        instance = Settings()
    }

    static func destroy() {
        Settings.instance = nil
    }

    weak var delegate: SettingsDelegate?
    
    // default values
    static var defaultPositionSource: PositionSource { .real }
    static var defaultUpSource: UpSource { .customCourseUp }
    static var defaultMetersPerPixel: Double { 1.5 }
    static var defaultSimulatedAccuracy: SimulatedAccuracy { .good }

    // settings properties
    var positionSource = defaultPositionSource {
        didSet {
            delegate?.didChangeGpsSource(from: oldValue, to: positionSource)
        }
    }
    var upSource = defaultUpSource {
        didSet {
            delegate?.didChangeUpSource(from: oldValue, to: upSource)
        }
    }
    var metersPerPixel = defaultMetersPerPixel {
        didSet {
            delegate?.didChangeMetersPerPixel(from: oldValue, to: metersPerPixel)
        }
    }
    var simulatedAccuracy = defaultSimulatedAccuracy

    // methods
    func switchPositionSource() {
        if positionSource == .real {
            positionSource = .mapViewCenter
        } else {
            positionSource = .real
        }
    }

    func switchUpSource() {
        if upSource == .northUp {
            upSource = .systemCourseUp
        } else if upSource == .systemCourseUp {
            upSource = .customCourseUp
        } else if upSource == .customCourseUp {
            upSource = .headingUp
        } else {
            upSource = .northUp
        }
    }

    func switchMetersPerPixel() {
        if metersPerPixel == 1 {
            metersPerPixel = 1.5
        } else if metersPerPixel == 1.5 {
            metersPerPixel = 2
        } else if metersPerPixel == 2 {
            metersPerPixel = 3
        } else if metersPerPixel == 3 {
            metersPerPixel = 4
        } else {
            metersPerPixel = 1
        }
    }
}
