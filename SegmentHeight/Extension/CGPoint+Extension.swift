//
//  CGPoint+Extension.swift
//  SegmentHeight
//
//  Created by Arun Rathore on 09/04/24.
//

import UIKit

extension CGPoint {
    static func distanceBetween(point p1: CGPoint, andPoint p2: CGPoint) -> CGFloat {
        let deltaX = p2.x - p1.x
        let deltaY = p2.y - p1.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        return distance
    }
}
