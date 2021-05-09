//
//  ViewController.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 28/03/2021.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bikeView: BikeSimulationView!
    @IBOutlet weak var buttonRecenter: UIButton!
    @IBOutlet weak var crosshairView: UIImageView!
    
    private var tileOverlay: MKTileOverlay!
    private let manager = CLLocationManager()
    private var currentCoordinates = [CLLocationCoordinate2D]()
    private var currentLine = MKPolyline()
    private let coordinatesKey = "currentCoordinates"
    private var settings = Settings()
    private let redrawScheduler = TaskScheduler(minTimeBetweenTasks: 0.2)
    private var recentLocations = [CLLocation]()
    private var observers = [NSObjectProtocol]()

    override func viewDidLoad() {
        super.viewDidLoad()
        BLEBikeAccessory.createAndStart()
        Settings.create()
        Settings.instance?.delegate = self

        manager.setupDefaultsForBike()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingForBike()

        setupTileRenderer()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.setUserTrackingMode(.follow, animated: true)
//        workaroundForRandomCrashWhenEnteringBackground()

        if let savedCoordinates = loadCoordinates(fromKey: coordinatesKey) {
            currentCoordinates = savedCoordinates
        }
        reloadCurrentLine()
        scheduleBikeRedraw()
    }
    
    func workaroundForRandomCrashWhenEnteringBackground() {
        // it seems that crash occurs only when debugger is attached
        addObserver(name: UIScene.didActivateNotification) { [weak self] (notification) in
            guard let self = self else {
                return
            }
            self.mapView.addOverlay(self.tileOverlay)
        }
        addObserver(name: UIScene.didEnterBackgroundNotification) { [weak self] (notification) in
            guard let self = self else {
                return
            }
            self.mapView.removeOverlay(self.tileOverlay)
        }
    }
    
    func addObserver(name: NSNotification.Name, block: @escaping (Notification) -> Void) {
        let observer = NotificationCenter.default.addObserver(forName: name,
                                                              object: nil,
                                                              queue: nil,
                                                              using: block)
        observers.append(observer)
    }

    @IBAction func onTapRecenter(_ sender: Any) {
        var newMode = MKUserTrackingMode.follow
        var makeNorthUp = false
        if mapView.userTrackingMode == .follow {
            if mapView.camera.heading == 0 {
                newMode = .followWithHeading
            } else {
                makeNorthUp = true
            }
        } else if mapView.userTrackingMode == .followWithHeading {
            makeNorthUp = true
        }
        mapView.setUserTrackingMode(newMode, animated: true)
        if makeNorthUp {
            let newCamera = MKMapCamera(lookingAtCenter: mapView.camera.centerCoordinate, fromDistance: mapView.camera.centerCoordinateDistance, pitch: mapView.camera.pitch, heading: 0)
            mapView.setCamera(newCamera, animated: true)
        }
    }

    @IBAction func onTapAddPoint(_ sender: Any) {
        let coordinate = mapView.convert(crosshairView.center, toCoordinateFrom: nil)
        currentCoordinates.append(coordinate)
        reloadCurrentLine()
        storeCoordinates(currentCoordinates, forKey: coordinatesKey)
    }

    @IBAction func onTapDeletePoint(_ sender: Any) {
        guard !currentCoordinates.isEmpty else {
            return
        }
        currentCoordinates.removeLast()
        reloadCurrentLine()
        storeCoordinates(currentCoordinates, forKey: coordinatesKey)
    }

//    @IBAction func onTapNewLine(_ sender: Any) {
//        guard currentLine.pointCount > 0 else {
//            return
//        }
//        linesOnMap.append(currentLine)
//        currentLine = MKPolyline()
//        currentPoints.removeAll()
//    }
//
//    @IBAction func onTapRemoveLine(_ sender: Any) {
//        mapView.removeOverlay(currentLine)
//        currentLine = linesOnMap.popLast() ?? MKPolyline()
//        currentPoints = currentLine.coordinates
//        refreshCurrentLine()
//    }

    @IBAction func onTapMenu(_ sender: Any) {
        let menuContentVC = MainMenuTableController()
        let dismissButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissController))
        menuContentVC.navigationItem.rightBarButtonItem = dismissButtonItem

        let menuVC = UINavigationController(rootViewController: menuContentVC)
        present(menuVC, animated: true, completion: nil)
    }

    @objc
    func dismissController() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - SettingsDelegate
extension ViewController: SettingsDelegate {
    func didChangeMetersPerPixel(from oldValue: Double, to newValue: Double) {
        scheduleBikeRedraw()
    }

    func didChangeUpSource(from oldValue: UpSource, to newValue: UpSource) {
        scheduleBikeRedraw()
    }

    func didChangeGpsSource(from oldValue: PositionSource, to newValue: PositionSource) {
        scheduleBikeRedraw()
    }
}

// MARK: - private methods
private extension ViewController {
    func setupTileRenderer() {
        let overlay = MyTileOverlay(urlTemplate: "https://c.tile.openstreetmap.org/{z}/{x}/{y}.png")
        overlay.canReplaceMapContent = true
        overlay.tileSize = CGSize(width: 512, height: 512)
        tileOverlay = overlay
        mapView.addOverlay(overlay, level: .aboveLabels)
    }

    func reloadCurrentLine() {
        mapView.removeOverlay(currentLine)
        currentLine = MKPolyline(coordinates: currentCoordinates, count: currentCoordinates.count)
        mapView.addOverlay(currentLine)
        scheduleBikeRedraw()
    }

    func storeCoordinates(_ coordinates: [CLLocationCoordinate2D], forKey key: String) {
        let locations = coordinates.map { coordinate -> CLLocation in
            return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        if let archived =  try? NSKeyedArchiver.archivedData(withRootObject: locations, requiringSecureCoding: true) {
            UserDefaults.standard.set(archived, forKey: key)
            // TODO: remove syncing every time
            UserDefaults.standard.synchronize()
        }
    }

    func loadCoordinates(fromKey key: String) -> [CLLocationCoordinate2D]? {
        guard let archived = UserDefaults.standard.object(forKey: key) as? Data else {
            print("No UserDefaults value for key: \(key)")
            return nil
        }
        guard let locations = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, CLLocation.self], from: archived) as? [CLLocation] else {
            print("ERROR: failed to unarchive value for key: \(key)")
            return nil
        }

        let coordinates = locations.map { location -> CLLocationCoordinate2D in
            return location.coordinate
        }

        return coordinates
    }

    func locationWithBearing(bearingDegrees: Double, distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6) // earth radius in meters
        let bearingRadians = bearingDegrees * Double.pi / 180

        let lat1 = origin.latitude * Double.pi / 180
        let lon1 = origin.longitude * Double.pi / 180

        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }

    func degreesToRadians(degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    func radiansToDegrees(radians: Double) -> Double {
        radians * 180.0 / .pi
    }

    func getBearingBetween(point1: CLLocationCoordinate2D, point2: CLLocationCoordinate2D) -> Double {

        let lat1 = degreesToRadians(degrees: point1.latitude)
        let lon1 = degreesToRadians(degrees: point1.longitude)

        let lat2 = degreesToRadians(degrees: point2.latitude)
        let lon2 = degreesToRadians(degrees: point2.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansToDegrees(radians: radiansBearing)
    }

    func redrawBikeLines() {
        // read settings
        let positionSource = Settings.instance?.positionSource ?? Settings.defaultPositionSource
        let metersPerPixel = Settings.instance?.metersPerPixel ?? Settings.defaultMetersPerPixel
        let upSource = Settings.instance?.upSource ?? Settings.defaultUpSource
        let simulatedAccuracy = Settings.instance?.simulatedAccuracy ?? Settings.defaultSimulatedAccuracy

        var bikeCenter = MKMapPoint(mapView.convert(crosshairView.center, toCoordinateFrom: nil))//MKMapPoint(mapView.centerCoordinate)
        let defaultAccuracy = CLLocationAccuracy(simulatedAccuracy == .good ? 5 : 40)
        var currentLocation = CLLocation(coordinate: bikeCenter.coordinate,
                                         altitude: 0,
                                         horizontalAccuracy: defaultAccuracy,
                                         verticalAccuracy: 0,
                                         timestamp: Date())
        if let lastLocation = manager.location,
            (positionSource == .real ||
                UIApplication.shared.applicationState == .background) {
            bikeCenter = MKMapPoint(lastLocation.coordinate)
            currentLocation = lastLocation
        }

        if let lastLocation = recentLocations.last {
            if bikeCenter.distance(to: MKMapPoint(lastLocation.coordinate)) > 5 {
                recentLocations.append(currentLocation)
                while recentLocations.count > 21 {
                    recentLocations.removeFirst()
                }
            }
        } else {
            recentLocations.append(currentLocation)
        }

        var customCourse = CLLocationDirection(0)
        let courseCount = 3 // number of recent locations which take part in course computing
        let skipLastCount = 1 // skip most recent coordinates, they can be too close to the current location
        let deltaWeightPerStep = Double(2)
        let accuracyKoeficient = { () -> Double in
            let minValue = Double(2)
            let clampedFromBottom = max(currentLocation.horizontalAccuracy, minValue)
            return minValue / clampedFromBottom
        }()
        if recentLocations.count >= courseCount + skipLastCount {
            var imagineTarget = bikeCenter
            let firstIndex = recentLocations.count - courseCount - skipLastCount
            let lastIndex = recentLocations.count - 1 - skipLastCount
            for i in firstIndex...lastIndex {
                // course from newer locations have bigger multiplier, than course from older ones,
                // but if accuracy of current position is low, the multiplier difference will be less noticeable
                let weight = accuracyKoeficient * deltaWeightPerStep * Double(i - firstIndex)
                let multiplier = Double(1 + weight)
                let from = MKMapPoint(recentLocations[i].coordinate)
                let to = bikeCenter
                let delta = MKMapPoint(x: to.x - from.x, y: to.y - from.y)
                imagineTarget.x += multiplier * delta.x
                imagineTarget.y += multiplier * delta.y
            }
            customCourse = getBearingBetween(point1: bikeCenter.coordinate, point2: imagineTarget.coordinate)
        }

        let upAngle = { () -> CLLocationDegrees in
            switch upSource {
            case .northUp:
                return 0
            case .systemCourseUp:
                return manager.location?.course ?? 0
            case .customCourseUp:
                return customCourse
            case .headingUp:
                return manager.heading?.trueHeading ?? 0
            }
        }()

        let bikeInfo = BLEBikeAccessory.instance?.info ?? BikeInfo(screenWidth: 128, screenHeight: 128)
        let screenCenter = { () -> CGPoint in
            if Double(bikeInfo.screenHeight) / Double(bikeInfo.screenWidth) > 1.3 {
                return CGPoint(x: Int(bikeInfo.screenWidth / 2),
                               y: Int(Double(bikeInfo.screenHeight) * 0.67))
            } else {
                let minSide = Double(min(bikeInfo.screenWidth, bikeInfo.screenHeight))
                return CGPoint(x: Int(bikeInfo.screenWidth / 2),
                               y: Int(Double(bikeInfo.screenHeight) - minSide * 0.45))
            }
        }()
        let bike = BikeGeometryConverter(screenWidth: Double(bikeInfo.screenWidth),
                                         screenHeight: Double(bikeInfo.screenHeight),
                                         metersPerPixel: metersPerPixel,
                                         screenCenter: screenCenter,
                                         mapCenter: bikeCenter,
                                         forwardAngle: upAngle)

        var lines = [BikeLine]()
        var lineToClosestPoint: BikeLine? = nil
        if currentCoordinates.count > 1 {
            for i in 1..<currentCoordinates.count {
                let fromPoint = MKMapPoint(currentCoordinates[i - 1])
                let toPoint = MKMapPoint(currentCoordinates[i])
                let fromPointAsRect = MKMapRect(origin: fromPoint, size: MKMapSize())
                let toPointAsRect = MKMapRect(origin: toPoint, size: MKMapSize())
                let fullRect = fromPointAsRect.union(toPointAsRect)
                if bike.bikeRect.intersects(fullRect) {
                    lines.append(BikeLine(from: bike.convertPoint(fromPoint), to: bike.convertPoint(toPoint)))
                }
            }
            if lines.isEmpty {
                let closestCoordinate = currentCoordinates.min { (coordA, coordB) -> Bool in
                    let distanceA = bikeCenter.distance(to: MKMapPoint(coordA))
                    let distanceB = bikeCenter.distance(to: MKMapPoint(coordB))
                    return distanceA < distanceB
                }
                if let closestCoordinate = closestCoordinate {
                    let toPoint = MKMapPoint(closestCoordinate)
                    lineToClosestPoint = BikeLine(from: bike.convertPoint(bikeCenter), to: bike.convertPoint(toPoint))
                }
            }
        }

        var linesHeading = [BikeLine]()
        var trianglesHeading = [BikeTriangle]()
        let headingLock = upSource == .customCourseUp || upSource == .systemCourseUp
        if headingLock {
            let c = screenCenter
            let pointLeft = CGPoint(x: c.x - 5, y: c.y + 5)
            let pointRight = CGPoint(x: c.x + 5, y: c.y + 5)
            let pointForward = CGPoint(x: c.x, y: c.y - 8)
            let pointBack = CGPoint(x: c.x, y: c.y + 2)
            linesHeading.append(BikeLine(from: pointLeft, to: pointForward))
            linesHeading.append(BikeLine(from: pointForward, to: pointRight))
            linesHeading.append(BikeLine(from: pointRight, to: pointBack))
            linesHeading.append(BikeLine(from: pointBack, to: pointLeft))
            trianglesHeading.append(BikeTriangle(p1: pointLeft, p2: pointForward, p3: pointBack))
            trianglesHeading.append(BikeTriangle(p1: pointForward, p2: pointRight, p3: pointBack))
        }
        else if let lastHeading = manager.heading?.trueHeading {
            let pointLeft = MKMapPoint(locationWithBearing(bearingDegrees: lastHeading + 135, distanceMeters: 7 * bike.bikeMetersPerPixel, origin: bikeCenter.coordinate))
            let pointRight = MKMapPoint(locationWithBearing(bearingDegrees: lastHeading - 135, distanceMeters: 7 * bike.bikeMetersPerPixel, origin: bikeCenter.coordinate))
            let pointForward = MKMapPoint(locationWithBearing(bearingDegrees: lastHeading, distanceMeters: 7 * bike.bikeMetersPerPixel, origin: bikeCenter.coordinate))
            let pointBack = MKMapPoint(locationWithBearing(bearingDegrees: lastHeading + 180, distanceMeters: 4 * bike.bikeMetersPerPixel, origin: bikeCenter.coordinate))
            let points = [pointLeft, pointForward, pointRight, pointBack, pointLeft]
            for i in 1..<points.count {
                linesHeading.append(BikeLine(from: bike.convertPoint(points[i - 1]), to: bike.convertPoint(points[i])))
            }
            trianglesHeading.append(BikeTriangle(p1: bike.convertPoint(pointLeft),
                                                 p2: bike.convertPoint(pointForward),
                                                 p3: bike.convertPoint(pointBack)))
            trianglesHeading.append(BikeTriangle(p1: bike.convertPoint(pointForward),
                                                 p2: bike.convertPoint(pointRight),
                                                 p3: bike.convertPoint(pointBack)))
        }

        let bikeAccuracy = { () -> BikeCircle in
            let accuracyPixels = currentLocation.horizontalAccuracy / bike.bikeMetersPerPixel
            let maxAllowedAccuracy = min(bike.bikeWidthPixels, bike.bikeHeightPixels) * 0.44
            let radius = accuracyPixels < maxAllowedAccuracy ? accuracyPixels : maxAllowedAccuracy
            return BikeCircle(center: screenCenter, radius: CGFloat(radius))
        }()

        var breadCrumbs = [BikeCircle]()
        if recentLocations.count > 0 {
            for i in 0..<recentLocations.count - 1 {
                let point = MKMapPoint(recentLocations[i].coordinate)
                breadCrumbs.append(BikeCircle(center: bike.convertPoint(point), radius: 2))
            }
        }

        bikeView.lines = lines
        bikeView.lineToClosestPoint = lineToClosestPoint
        bikeView.linesHeading = linesHeading
        bikeView.setNeedsDisplay()

        sendBikeFrame(lines: lines,
                      lineToClosestPoint: lineToClosestPoint,
                      center: BikeCircle(center: screenCenter, radius: 3),
                      accuracy: bikeAccuracy,
                      linesHeading: [BikeLine]()/*linesHeading*/,
                      trianglesHeading: /*[BikeTriangle]()*/trianglesHeading,
                      breadCrumbs: breadCrumbs)
    }

    func scheduleBikeRedraw() {
        redrawScheduler.scheduleTask { [weak self] (result) in
            guard result == .canExecuteNow else {
                return
            }
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            print("\(timeFormatter.string(from: Date())) redrawing")
            self?.redrawBikeLines()
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4
            return renderer
        } else if overlay is MKTileOverlay {
            return MKTileOverlayRenderer(overlay: overlay)
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        let image = { () -> UIImage? in
            switch mode {
            case .none:
                return UIImage(systemName: "location")
            case .follow:
                return UIImage(systemName: "location.fill")
            case .followWithHeading:
                return UIImage(systemName: "location.circle")
            @unknown default:
                return UIImage(systemName: "location")
            }
        }()
        buttonRecenter.setImage(image, for: .normal)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController : CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if !manager.hasAuthorization {
            print("ERROR: location permission not granted, status=\(manager.safeAuthorizationStatus.rawValue)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if !manager.hasAuthorization {
            print("ERROR: location permission not granted, status=\(manager.safeAuthorizationStatus.rawValue)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        scheduleBikeRedraw()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        scheduleBikeRedraw()
    }
}

// MARK: - BLEBike logic
extension ViewController {
    func sendBikeFrame(lines: [BikeLine],
                       lineToClosestPoint: BikeLine?,
                       center: BikeCircle,
                       accuracy: BikeCircle,
                       linesHeading: [BikeLine],
                       trianglesHeading: [BikeTriangle],
                       breadCrumbs: [BikeCircle]) {
        guard let bikeAccessory = BLEBikeAccessory.instance else {
            return
        }
        bikeAccessory.newFrame(color: BikeColor(r: 0, g: 0, b: 0))
        lines.forEach { (line) in
            let from = BikePoint(x: line.from.x.safeInt16, y: line.from.y.safeInt16)
            let to = BikePoint(x: line.to.x.safeInt16, y: line.to.y.safeInt16)
            bikeAccessory.drawLine(from: from, to: to, color: BikeColor(r: 200, g: 100, b: 0), width: 4)
        }
        for i in 0..<breadCrumbs.count {
            let fade = 20 * (breadCrumbs.count - i - 1)
            let intensity = UInt8(255 - min(150, fade))
            let circle = breadCrumbs[i]
            bikeAccessory.fillCircle(center: BikePoint(x: circle.center.x.safeInt16, y: circle.center.y.safeInt16), radius: UInt8(circle.radius), color: BikeColor(r: 0, g: intensity, b: 0))
        }
        let bikeCenter = BikePoint(x: center.center.x.safeInt16, y: center.center.y.safeInt16)
        if let lineToClosestPoint = lineToClosestPoint {
            let from = bikeCenter
            let to = BikePoint(x: lineToClosestPoint.to.x.safeInt16, y: lineToClosestPoint.to.y.safeInt16)
            bikeAccessory.drawLine(from: from, to: to, color: BikeColor(r: 100, g: 100, b: 100), width: 1)
        }
        if accuracy.radius < CGFloat(UInt8.max),
           accuracy.radius > 10 {
            bikeAccessory.drawCircle(center: BikePoint(x: accuracy.center.x.safeInt16, y: accuracy.center.y.safeInt16), radius: UInt8(accuracy.radius), color: BikeColor(r: 70, g: 70, b: 70))
        }
        trianglesHeading.forEach { (triangle) in
            let p1 = BikePoint(x: triangle.p1.x.safeInt16, y: triangle.p1.y.safeInt16)
            let p2 = BikePoint(x: triangle.p2.x.safeInt16, y: triangle.p2.y.safeInt16)
            let p3 = BikePoint(x: triangle.p3.x.safeInt16, y: triangle.p3.y.safeInt16)
            bikeAccessory.fillTriangle(p1, p2, p3, color: BikeColor(r: 255, g: 255, b: 255))
        }
        linesHeading.forEach { (line) in
            let from = BikePoint(x: line.from.x.safeInt16, y: line.from.y.safeInt16)
            let to = BikePoint(x: line.to.x.safeInt16, y: line.to.y.safeInt16)
            bikeAccessory.drawLine(from: from, to: to, color: BikeColor(r: 255, g: 255, b: 255), width: 1)
        }
//        bikeAccessory.drawCircle(center: bikeCenter, radius: UInt8(center.radius), color: BikeColor(r: 255, g: 255, b: 255))
        bikeAccessory.showCurrentFrame()
    }
}

extension CGFloat {
    var safeInt16: Int16 {
        if self.native < Double(Int16.min + 1) {
            return Int16.min
        } else if self.native > Double(Int16.max - 1) {
            return Int16.max
        }
        return Int16(self.native)
    }
}
