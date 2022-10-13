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
import AppAuth

class ViewController: UIViewController, ARSessionDelegate, GARSessionDelegate {
    
    //Export the data to database when done
    @IBOutlet weak var ExportButton: UIButton!
    
    
    //AR View
    var arView:ARView!
    var arConfig=ARWorldTrackingConfiguration()
    
    //GOOGLE CLOUD ANCHORS
    var gSession:GARSession!
    
    //INFO LABEL
    var infoLabel:UITextView!
    
    //Firebase Database
    var database:DatabaseReference!
    
    var AuthTokenString=String()
    
    //DATA FOR STORAGE
    //List Of Anchor Data
    var anchorData=[String]()
    //List Of Buttons for deleting Anchors
    @IBOutlet weak var AnchorButtonList: UIButton!
    
    
    //State Trackers
    var noOfAnchorsHosted:Int!=nil
    var isHosting:Bool=true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initFirebase()
        self.initARView()
        
        self.initInfoLabelUI()
        self.repositionButtons()
        
        self.initGCA()
    }

    //Custom Functions
    //Initialize the ARView
    func initARView(){
        self.arView=ARView(frame: self.view.bounds)
        self.arView.session.delegate=self
        self.arView.debugOptions=[.showWorldOrigin,.showFeaturePoints]
        self.view.insertSubview(self.arView, at: 1)
        self.arView.session.run(self.arConfig)
    }
    
    //Initialize Google Cloud Anchors
    func initGCA(){
            var error:NSError!
        
            //Init GCA Session
            do{
                
                gSession = try GARSession.session()
                gSession.setAuthToken(self.AuthTokenString)
                
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
        self.view.insertSubview(infoLabel, at: 9)
    }
    
    //Reposition Buttons
    func repositionButtons(){
        self.ExportButton.frame=CGRectMake(200, 0, 100, 50)
        self.view.insertSubview(self.ExportButton, at: 9)
        
        self.AnchorButtonList.frame=CGRectMake(300, 0, 100, 50)
        self.view.insertSubview(self.AnchorButtonList, at: 9)
    }
    
    //Init Firebase
    func initFirebase(){
        //Configure Firebase
        FirebaseApp.configure()
        //init database Reference
        self.database=Database.database().reference()
        //Get the oAuth Token Stored in Firebase
        self.database.child("Token").observeSingleEvent(of: .value) { data in
            self.AuthTokenString=(data.value as? String)!
        }
    }
    
    //Touch Functionalities
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(self.AuthTokenString != nil && self.isHosting == true){
            gSession.setAuthToken(self.AuthTokenString)
            let touch=touches.first
            let touchLoc=touch?.location(in: arView)
            let hitTestResult=arView.hitTest(touchLoc!, types: [.estimatedHorizontalPlane,.estimatedVerticalPlane])
            if(hitTestResult.count > 0){
                print("HIT AT: ",hitTestResult.first?.worldTransform)
                tryHostAnchor(transform: hitTestResult.first?.worldTransform)
            }
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
        infoLabel.text="SUCCESS HOSTING!"
        //Update the Anchor List
        self.anchorData.append(anchor.cloudIdentifier!)
        self.noOfAnchorsHosted=self.anchorData.count
        if(self.noOfAnchorsHosted == 5){self.isHosting=false;self.ExportButton.setTitle("Upload", for: .normal)}
        self.add_3d_model(loc: anchor.transform)
    }
    
    func session(_ session: GARSession, didFailToHost anchor: GARAnchor) {
        infoLabel.text="FAILED TO HOST...TRY AGAIN"
    }
    
    //BUTTON FUNCTIONS
    
    //Update Button on Screen based on Anchor List
    @IBAction func UpdateButtonList(_ sender: Any) {
            print("KELA")
            let kela={(action:UIAction) in
                print(action.title)
            }
        
            self.AnchorButtonList.menu=UIMenu(children: [
                UIAction(title: "0",state: .on, handler: kela),
                UIAction(title: "1", handler: kela),
            ])
        
            self.AnchorButtonList.showsMenuAsPrimaryAction=true
            self.AnchorButtonList.changesSelectionAsPrimaryAction=true
        
    }
    
    @IBAction func ExportData(_ sender: Any) {
        if(self.isHosting == true){
            self.ExportButton.setTitle("Upload", for: .normal)
            self.isHosting=false
        }else{
            self.database.child("Anchors").setValue(self.anchorData)
            infoLabel.text="SUCCESS UPLOADING TO DATABASE"
        }
    }
}

