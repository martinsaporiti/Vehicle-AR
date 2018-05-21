//
//  Utils.swift
//  Vehicle
//
//  Created by Martin Saporiti on 19/05/2018.
//  Copyright © 2018 Martin Saporiti. All rights reserved.
//

import Foundation
import ARKit

func getCurrentPositionOfCamera(pointOfView: SCNNode) -> SCNVector3 {
    let transform = pointOfView.transform
    let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
    let location = SCNVector3(transform.m41, transform.m42, transform.m43)
    return  orientation + location
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}
