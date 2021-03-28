//
//  BLEBikeDataTypes.swift
//  BLEBikeNavi
//
//  Created by Alexander Lavrushko on 28/03/2021.
//

import Foundation

enum BLEBikeCommand: UInt8 {
    case fillScreen = 1
    case drawLine = 2

    var data: Data {
        Data([self.rawValue])
    }
}

struct BikePoint {
    var x = UInt8(0)
    var y = UInt8(0)
    init(x: UInt8, y: UInt8) {
        self.x = x
        self.y = y
    }

    var data: Data {
        Data([x, y])
    }
}

struct BikeColor {
    var r = UInt8(0)
    var g = UInt8(0)
    var b = UInt8(0)

    init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    var color565: UInt16 {
        ((UInt16(r) & 0xF8) << 8) | ((UInt16(g) & 0xFC) << 3) | (UInt16(b) >> 3)
    }

    var data: Data {
        var color565 = self.color565
        return Data(bytes: &color565, count: MemoryLayout<UInt16>.size)
    }
}
