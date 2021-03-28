//
//  BLEBikeDataTypes.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 28/03/2021.
//

import Foundation

class BLEBikeDataEncoder {
    func buildFillScreen(color: BikeColor) -> Data {
        var data = BLEBikeCommand.fillScreen.data
        data.append(color.data)
        return data
    }

    func buildDrawLine(from: BikePoint, to: BikePoint, color: BikeColor, width: UInt8) -> Data {
        var data = BLEBikeCommand.drawLine.data
        data.append(from.data)
        data.append(to.data)
        data.append(color.data)
        data.append(contentsOf: [width])
        return data
    }
}
