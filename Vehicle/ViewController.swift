//
//  ViewController.swift
//  Floor is Lava
//
//  Created by Martin Saporiti on 11/05/2018.
//  Copyright © 2018 Martin Saporiti. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration();
    let motionManager = CMMotionManager()
    
    var vehicle = SCNPhysicsVehicle()
    
    var orientation : CGFloat = 0;
    
    
    var accelerationValues = [UIAccelerationValue(0), UIAccelerationValue(0)]
    
    var touched : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                       ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(configuration);
        self.configuration.planeDetection = .horizontal
        self.sceneView.delegate = self
        self.setUpAccelerometer()
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let concreteNode = self.createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        let concreteNode = self.createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        var engineForce : CGFloat = 0;
        self.vehicle.setSteeringAngle(-orientation, forWheelAt: 2)
        self.vehicle.setSteeringAngle(-orientation, forWheelAt: 3)
        
        
        var brakingForce : CGFloat = 0;
        
        if self.touched == 1 {
            engineForce = 50
        } else if self.touched == 2 {
            engineForce = -50
        } else if self.touched == 3 {
            brakingForce = 100
        } else {
            engineForce = 0
        }
        
        self.vehicle.applyEngineForce(engineForce, forWheelAt: 0)
        self.vehicle.applyEngineForce(engineForce, forWheelAt: 1)
        self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 0)
        self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 1)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else {return}
        self.touched += touches.count
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touched = 0
    }
    
    /**
 
    */
    func setUpAccelerometer(){
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1/60
            motionManager.startAccelerometerUpdates(to: .main, withHandler: {
                (accelerometerData, error) in
                if let error = error {
                    print(error.localizedDescription);
                    return
                }
                
                self.accelerometerDidChange(acceleration: accelerometerData!.acceleration)
                
            })
            
        } else {
            print("accelerometer is not available");
        }
    }
    
    
    /**
        Función que se ejecuta cuando se rota el celular.
    */
    func accelerometerDidChange(acceleration: CMAcceleration){
        
        self.accelerationValues[0] = filtered(previousAcceleration: self.accelerationValues[0], UpdatedAcceleration: acceleration.x)
        self.accelerationValues[1] = filtered(previousAcceleration: accelerationValues[1], UpdatedAcceleration: acceleration.y)
        
        // La siguiente condición se utiliza para poder hacer funcionar correctamente las ruedas del
        // vehículo inclusive cuando se utiliza el celular al revés (siempre en modo horizontal).
        // De esta forma podemos utilizar la aplicación independientemente de la orientación del celular.
        
        if(acceleration.x > 0){
            self.orientation = -CGFloat(self.accelerationValues[1])
        } else {
            self.orientation = CGFloat(self.accelerationValues[1])
        }
        
//        if(acceleration.x > 0){
//            self.orientation = -CGFloat(acceleration.y)
//        } else {
//            self.orientation = CGFloat(acceleration.y)
//        }
    }
    
    
    /**
     
     
     */
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        return concreteNode
    }
    
    
    
    /**
 
 
    */
    @IBAction func addCar(_ sender: Any) {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        
        let currentPositionCamera = getCurrentPositionOfCamera(pointOfView: pointOfView)
        
        let scene = SCNScene(named: "Car - Scene.scn")
        let chassis = (scene?.rootNode.childNode(withName: "chassis", recursively: false))!
        
        // Se crean las ruedas del vehículo.
        let fronLeftWheel = chassis.childNode(withName: "frontLeftParent", recursively: false)!;
        let fronRightWheel = chassis.childNode(withName: "frontRightParent", recursively: false)!;
        let rearLeftWheel = chassis.childNode(withName: "rearLeftParent", recursively: false)!;
        let rearRightWheel = chassis.childNode(withName: "rearRightParent", recursively: false)!;
        
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: fronLeftWheel);
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: fronRightWheel);
        let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeftWheel);
        let v_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel);
        
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound : true]))
        
        body.mass = 5
        
        chassis.physicsBody = body
        self.vehicle = SCNPhysicsVehicle(chassisBody: chassis.physicsBody!, wheels: [v_rearRightWheel, v_rearLeftWheel, v_frontRightWheel, v_frontLeftWheel]);
        
        
        self.sceneView.scene.physicsWorld.addBehavior(vehicle)
        chassis.position = currentPositionCamera;
        self.sceneView.scene.rootNode.addChildNode(chassis)
    }
    

    func filtered(previousAcceleration: Double, UpdatedAcceleration: Double) -> Double {
        let kfilteringFactor = 0.5
        return UpdatedAcceleration * kfilteringFactor + previousAcceleration * (1-kfilteringFactor)
    }
}


