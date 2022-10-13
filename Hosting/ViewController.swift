//
//  ViewController.swift
//  Hosting
//
//  Created by Sujay HG on 13/10/22.
//

import UIKit
import ARCore
import Firebase
import RealityKit

class ViewController: UIViewController, ARSessionDelegate, GARSessionDelegate {
    
    //AR View
    var arView:ARView!
    var arConfig=ARWorldTrackingConfiguration()
    
    //GOOGLE CLOUD ANCHORS
    var gSession:GARSession!
    var anchorList=[GARAnchor]()
    
    //INFO LABEL
    var infoLabel:UITextView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initARView()
        self.initGCA()
        self.initInfoLabelUI()
    }

    //Custom Functions
    //Initialize the ARView
    func initARView(){
        self.arView=ARView(frame: self.view.bounds)
        self.arView.session.delegate=self
        self.arView.debugOptions=[.showWorldOrigin,.showFeaturePoints]
        self.view.addSubview(self.arView)
        self.arView.session.run(self.arConfig)
    }
    
    //Initialize Google Cloud Anchors
    func initGCA(){
            var error:NSError!
            
            //Init GCA Session
            do{
                
                gSession = try GARSession.session()
                gSession.setAuthToken("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ijg3OTIzZDM5MzUxZDlmOWU3OWZiNzE2YTZiNmQwZTE0YjcxMWZkNjAifQ.eyJpc3MiOiJ2aWdhY2xvdWRhbmNob3JzQHZpZ2FhcmNvcmUuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJhdWQiOiJodHRwczovL2FyY29yZS5nb29nbGVhcGlzLmNvbS8iLCJleHAiOjE2NjU2Mzk1MzcsImlhdCI6MTY2NTYzNTkzNywic3ViIjoidmlnYWNsb3VkYW5jaG9yc0B2aWdhYXJjb3JlLmlhbS5nc2VydmljZWFjY291bnQuY29tIn0.dD20FZPMhH1R3Z4MEoMOddl4Xjy95AYqSy4vSg1sSlkIzumMwY0CxC4dHaFtKYUu7hFNvTBwQRwcHZFDiQmnPwbeAD4QC1aBzimsvtHQAYST9PFqUQfHHK3VCh5NisxKlw0bxb9MIrtikEEjKT0wKupPruilO0bvHFUmzWu-PVdNk-X0BxK5sFvmvxUs4KM2G0h9jowG_hJKjxkHCAiWDNq-nuF-hlRP3FqGq3L-JUKKGzXfmMV6ADQdIfONBKThyZqF5MN1dM80mXhDBLIYn50RF484LQrl0rhZiSSLN18LU_cH_m3kKT3pbQKSeB46vRWykHbp4bJXnjpzLFSYcQ")
                
            }catch let error{
                print("GCA_ERROR::",error)
            }
            
            //set config
            let GCAConfig=GARSessionConfiguration()
            GCAConfig.cloudAnchorMode=GARCloudAnchorMode.enabled
            gSession.setConfiguration(GCAConfig, error: &error)
            if(error != nil){print("GCA_CONFIG_ERROR::",error)}
            
            gSession.delegate=self
        }
    
    //Initialize the UI INFO LABEL UI
    func initInfoLabelUI(){
        //Init INFO_LABEL for displaying Information
        self.infoLabel=UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        self.infoLabel.text="WELCOME!!"
        self.view.insertSubview(infoLabel, at: 1)
    }
    
    //Touch Functionalities
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch=touches.first
                let touchLoc=touch?.location(in: arView)
        let hitTestResult=arView.hitTest(touchLoc!, types: [.estimatedHorizontalPlane,.estimatedVerticalPlane])
                if(hitTestResult.count > 0){
                    print("HIT AT: ",hitTestResult.first?.worldTransform)
                    tryHostAnchor(transform: hitTestResult.first?.worldTransform)
                }
    }
    
    //Try and Host Google Cloud Anchors at given point
    func tryHostAnchor(transform:matrix_float4x4!){
        infoLabel.text="TRYING TO HOST...."
        //Create an Anchor
        let arAnchor=ARAnchor(transform: transform)
        //Use the Anchor to Host a GCA
        do{
            let gAnchor = try gSession.hostCloudAnchor(arAnchor, ttlDays: 20)
        }catch let error{
            print("ERROR_HOSTING_GCA_ERROR: ",error)
        }
    }
    
    //Add 3D Model For Reference
    func add_3d_model(loc:simd_float4x4){
        let sphereMesh=MeshResource.generateSphere(radius: 0.1)
        let material=SimpleMaterial(color: .red, isMetallic: true)
        let sphereAnchorObject=ModelEntity(mesh: sphereMesh, materials: [material])
                
        let sphereAnchor=AnchorEntity(world: SIMD3(x:0, y:0, z:0))
        sphereAnchor.addChild(sphereAnchorObject)
        sphereAnchor.transform=Transform.init(matrix: loc)
        arView.scene.anchors.append(sphereAnchor)
    }
    
    //ARView Sessions
    //Pass ARView Frames to GCA Session here
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        do{
            try gSession.update(frame)
        }catch let error{
            print("ERROR_PASSING_GCA_SESSION: ",error)
        }
    }
    
    //Google Cloud Anchors Session Delegate
    func session(_ session: GARSession, didHost anchor: GARAnchor) {
        infoLabel.text="SUCESS HOSTING!"
        self.add_3d_model(loc: anchor.transform)
    }
    
    func session(_ session: GARSession, didFailToHost anchor: GARAnchor) {
        infoLabel.text="FAILED TO HOST...TRY AGAIN"
    }
}

