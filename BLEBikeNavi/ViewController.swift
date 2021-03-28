//
//  ViewController.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 28/03/2021.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        if BLEBikeAccessory.instance == nil {
            BLEBikeAccessory.createAndStart()
            BLEBikeAccessory.instance?.delegate = self
        }
        refreshStatusLabel()
    }

    @IBAction func onTapStartStop(_ sender: Any) {
        if BLEBikeAccessory.instance == nil {
            BLEBikeAccessory.createAndStart()
            BLEBikeAccessory.instance?.delegate = self
        } else {
            BLEBikeAccessory.stopAndDestroy()
        }
        refreshStatusLabel()
    }

    @IBAction func onTapClear(_ sender: Any) {
        BLEBikeAccessory.instance?.fillScreen(color: BikeColor(r: 0, g: 0, b: 0))
    }

    @IBAction func onTapTest1(_ sender: Any) {
        BLEBikeAccessory.instance?.drawLine(from: BikePoint(x: 20, y: 64), to: BikePoint(x: 120, y: 32), color: BikeColor(r: 50, g: 200, b: 100), width: 2)
    }
}

// MARK: - UI related methods
extension ViewController {
    private func setStatusLabel(_ state: BLEBikeAccessoryState?) {
        guard let state = state else {
            statusLabel.text = "Stopped"
            return
        }
        statusLabel.text = "Started, \(state.humanReadableString)"
    }

    private func refreshStatusLabel() {
        guard let instance = BLEBikeAccessory.instance else {
            setStatusLabel(nil)
            return
        }
        instance.getState { (state) in
            self.setStatusLabel(state)
        }
    }
}

// MARK: - BLEBikeDelegate
extension ViewController: BLEBikeDelegate {
    func stateDidChange(_ newState: BLEBikeAccessoryState) {
        setStatusLabel(newState)
    }
}

// MARK: - BLEBike logic
extension ViewController {
}
