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

enum ColorScheme {
    case dark
    case light
}

enum SimulatedAccuracy {
    case good
    case bad
}

protocol SettingsDelegate: AnyObject {
    func settingsDidChange()
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
    static var defaultLineWidthScale: Double { 2 }
    static var defaultColorScheme: ColorScheme { .dark }
    static var defaultSimulatedAccuracy: SimulatedAccuracy { .good }

    // settings properties
    var positionSource = defaultPositionSource {
        didSet {
            delegate?.settingsDidChange()
        }
    }
    var upSource = defaultUpSource {
        didSet {
            delegate?.settingsDidChange()
        }
    }
    var metersPerPixel = defaultMetersPerPixel {
        didSet {
            delegate?.settingsDidChange()
        }
    }
    var lineWidthScale = defaultLineWidthScale {
        didSet {
            delegate?.settingsDidChange()
        }
    }
    var colorScheme = defaultColorScheme {
        didSet {
            delegate?.settingsDidChange()
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
        if metersPerPixel == 0.67 {
            metersPerPixel = 1
        } else if metersPerPixel == 1 {
            metersPerPixel = 1.5
        } else if metersPerPixel == 1.5 {
            metersPerPixel = 2
        } else if metersPerPixel == 2 {
            metersPerPixel = 3
        } else if metersPerPixel == 3 {
            metersPerPixel = 4
        } else {
            metersPerPixel = 0.67
        }
    }

    func switchLineWidthScale() {
        if lineWidthScale == 1 {
            lineWidthScale = 2
        } else if lineWidthScale == 2 {
            lineWidthScale = 3
        } else if lineWidthScale == 3 {
            lineWidthScale = 4
        } else if lineWidthScale == 4 {
            lineWidthScale = 5
        } else if lineWidthScale == 5 {
            lineWidthScale = 6
        } else {
            lineWidthScale = 1
        }
    }

    func switchColorScheme() {
        if colorScheme == .dark {
            colorScheme = .light
        } else {
            colorScheme = .dark
        }
    }
}
