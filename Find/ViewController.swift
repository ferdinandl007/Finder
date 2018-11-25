//
//  ViewController.swift
//  Find
//
//  Created by Ferdinand Lösch on 24/11/2018.
//  Copyright © 2018 Ferdinand Lösch. All rights reserved.
//
import UIKit
import SceneKit
import ARKit
import AVFoundation
import Vision
import SceneKit.ModelIO
import Firebase
import FirebaseDatabase
import Intents




class ViewController: UIViewController, ARSCNViewDelegate, AVSpeechSynthesizerDelegate , UITableViewDataSource , UITableViewDelegate{
    
    
    var ls = [String]()
    var data = NSDictionary()
    
    func returnPresent() -> [String]{
        
        var present_objects = [String]()
        for (obj_name,i) in data{
            let rooms = i as! NSDictionary
            for (_,j) in rooms{
                let room = j as! NSDictionary
                if (room["present"] as! String == "true"){
                    present_objects.append(obj_name as! String)
                }
            }
            
        }
        return present_objects
    }
    
    func returnObjectData(obj_name: String) -> [[String]]{
        let rooms = data[obj_name] as! NSDictionary
        
        var output = [[String]]()
        
        for (j,k) in rooms{
            let room = k as! NSDictionary
            let room_name = j as! String
            if (room["present"] as! String == "true"){
                
                var temp = [String]()
                
                temp.append(room_name)
                temp.append(room["ls"] as! String)
                temp.append(room["picture_url"] as! String)
                temp.append(room["nearest_object"] as!String)
                
                output.append(temp)
            }
        }
        
        print(output)
        
        return output
        
    }
    
    
    func getData(){
        let databaseRef = Database.database().reference()
        
        databaseRef.child("101").queryOrderedByKey().observe(.value, with: { snapshot in
            
           let snapshotValue = snapshot.value as? NSDictionary
            //print(snapshotValue)
            self.ls = snapshotValue?.allKeys as! [String]
            
            
            self.data = snapshotValue!
            
            
            
            self.tabelView.reloadData()
            
        }) { (Error) in
            print(Error)

                 print("noooooo")
            
        }
 
    }
    
 
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.ImpactGenerator.impactOccurred()
        let temp = returnPresent()[indexPath.row]
        let room_list = returnObjectData(obj_name: temp)
        
        var room = room_list[0]
        

        imageView.downloaded(from: room[2])
        imageView.contentMode = .scaleToFill
        label1.text = room[0]
        let time =  (Int(NSDate().timeIntervalSince1970) - Int(room[1])!) / 60
        label2.text = "\(time) minutes since last seen"
        label3.text = temp
        UIView.animate(withDuration: 0.3, animations: {
            self.viewb.frame.origin.y -= 150
            self.tabelView.alpha = 0
        }) { (Bool) in
            self.tabelView.isHidden = true
        }
        
        if (room[3] == "") {
            objToFind = ["",""]
            objToFind[0] = temp
        }
        else{
            objToFind = ["",""]
            objToFind[0] = room[3]
            objToFind[1] = temp
        }
        if objToFind[1] == "" {
            sppec(text: "We have localized the " + temp + " in " + room[0] + ". Happy hunting!")
        } else {
              sppec(text: "The " + temp + " is next to the " + room[3])
        }
      
        
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return returnPresent().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let temp = returnPresent()[indexPath.row]
        let room_list = returnObjectData(obj_name: temp)
        
        var room = room_list[0]
        
        cell.textLabel?.text = "\(returnPresent()[indexPath.row]) in \(room.first!)"
        return cell
    }
    
    
    // SCENE
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var ImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @IBOutlet weak var tabelView: UITableView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var viewb: UIVisualEffectView!
    let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    var latestPredictionPos = SCNVector3()
    var hasfund = false;
    var objToFind = ["",""]
    let dispatchQ = DispatchQueue(label: "com.hw.dis") // A Serial Queue
    
    // COREML
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    
    let synth = AVSpeechSynthesizer()
    var node = SCNNode()
    var origin = CGPoint()
    
    var screenCentre : CGPoint = CGPoint()
    @IBOutlet weak var debugTextView: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        donateInteraction()
       
        self.tabelView.delegate = self
        self.tabelView.dataSource = self
        
        viewb.layer.cornerRadius = 25
        tabelView.layer.cornerRadius = 25
        viewb.clipsToBounds = true
        // Set the scene to the view
        sceneView.scene = scene
        origin = viewb.frame.origin
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.scene.rootNode.addChildNode(node)
        
        //////////////////////////////////////////////////
        // Tap Gesture Recognizer
         screenCentre = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        Auth.auth().signInAnonymously(completion: { (user, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
              print("yesss")
            self.getData()
        })
        
        
        //////////////////////////////////////////////////
        
        // Set up Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: ImageClassifier().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
    }
    
    func donateInteraction() {
        let intent = PhotoOfTheDayIntent()
        
        intent.suggestedInvocationPhrase = "Energize"
        
        let interaction = INInteraction(intent: intent, response: nil)
        
        interaction.donate { (error) in
            if error != nil {
               
            }
        }
    }
    
    
    
    public func sayHi() {
        usleep(2000000)
        let temp = "Water Bottle"
        let room_list = returnObjectData(obj_name: temp)
        
        var room = room_list[0]
        
        
        imageView.downloaded(from: room[2])
        imageView.contentMode = .scaleToFill
        label1.text = room[0]
        let time =  (Int(NSDate().timeIntervalSince1970) - Int(room[1])!) / 60
        label2.text = "\(time) minutes since last seen"
        label3.text = temp
        UIView.animate(withDuration: 0.3, animations: {
            self.viewb.frame.origin.y -= 150
            self.tabelView.alpha = 0
        }) { (Bool) in
            self.tabelView.isHidden = true
        }
        
        if (room[3] == "null") {
            objToFind = ["",""]
            objToFind[0] = temp
        }
        else{
            objToFind = ["",""]
            objToFind[0] = room[3]
            objToFind[1] = temp
        }
        sppec(text: "The " + temp + " is next to the " + room[3])
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        //1. Check We Have A Valid ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        //2. Get It's Alignment
        if planeAnchor.alignment == .vertical{
            
            
            let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
            
            if let closestResult = arHitTestResults.first {
                // Get Coordinates of HitTest
                let transform : matrix_float4x4 = closestResult.worldTransform
                let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                let d = distanceFromCamera(x: worldCoord.x, y: worldCoord.y, z: worldCoord.z)
                if d < 2.0 {
                   sppec(text: "terrain!... terrain!... \(String(format:"%.2f", d)) metres ahead Watch out!" )
                    
                    
                    
                }
            }
            
        }
    }
    
    
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Interaction
    
    
    func sppec(text: String){
        var myUtterance = AVSpeechUtterance(string: "")
        myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.5
        synth.speak(myUtterance)
    }
    
    func makeNode(){
        // HIT TEST : REAL WORLD
        // Get Screen Centre
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create 3D Text
            let node : SCNNode = createNewBubbleParentNode(latestPrediction)
            sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
            node.name = "label"
            latestPredictionPos = worldCoord
            
        }
    }
    
     func nodeForURL() -> SCNNode
    {
        guard let url = Bundle.main.url(forResource: "model", withExtension: "obj") else {
            fatalError("Failed to find model file.")
        }
        
        let asset = MDLAsset(url:url)
        let object = asset.object(at: 0)
        let node = SCNNode(mdlObject: object)
        
        return node
    }
    
    
    
    
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        //let billboardConstraint = SCNBillboardConstraint()
        //billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.4, 0.4, 0.4)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = nodeForURL()
        bubbleNodeParent.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat(Double.pi / 2), z: 0, duration: 3)))
        bubbleNodeParent.scale = SCNVector3Make(2, 2, 2)
        //bubbleNodeParent.addChildNode(bubbleNodeParent)
       // bubbleNodeParent.addChildNode(sphereNode)
        //bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    // MARK: - CoreML Vision Handling
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            //self.chackDist()
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
        
    }
    

    var bb = false;
    var bbb = false
    func chackDist(){
        
        
        
        let d =  self.distanceFromCamera(x: self.latestPredictionPos.x,y: self.latestPredictionPos.y,z: self.latestPredictionPos.z)
        
        let cameraPosition =  self.sceneView.session.currentFrame!.camera.transform.columns.3
      
        let vector = SCNVector3Make(cameraPosition.x, cameraPosition.y - 0.4, cameraPosition.z)

        if abs(d) > 2.0 {
            node.removeFromParentNode()
            node = CylinderLine(parent: SCNNode(), v1: vector, v2: latestPredictionPos, radius: 0.02, radSegmentCount: 22, color: UIColor.red)
            sceneView.scene.rootNode.addChildNode(node)
            self.ImpactGenerator.impactOccurred()
            bb = false

        } else if abs(d) < 2.0 && !bb{
            node.runAction(SCNAction.sequence([SCNAction.fadeOut(duration: 1.5),SCNAction.run({ (SCNNode) in
                self.node.removeFromParentNode()
                self.node.removeAllActions()

            })]))

            bb = true
        }
       
        if abs(d) > 2.0 && !bbb{
            sppec(text: "you are moving too far away! Please go back and followe the Red Line!")
            bbb = true
            var timer = Timer()
            timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false, block: { (Timer) in
                self.bbb = false
            })
            
            
        }
    }
    
    
    var hasfund2 = false
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...0] // top 2 results
            .compactMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier)\(String(format:"-%.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Print Classifications
            
             let d =  self.distanceFromCamera(x: self.latestPredictionPos.x,y: self.latestPredictionPos.y,z: self.latestPredictionPos.z)
            
            // Display Debug Text on screen
            var debugText:String = ""
            debugText += classifications
            self.debugTextView.text = " "
            
            // Store the latest prediction
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            guard let value = Float(classifications.components(separatedBy: "-")[1]) else {return}
           
            
            
            print(self.objToFind)
            if self.objToFind[1] != "" {
                if (value >= 0.87 && !self.hasfund && self.objToFind[0] == objectName) {
                    self.latestPrediction = objectName
                    self.makeNode()
                    self.synth.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
                    self.sppec(text: "your " + self.objToFind[0] + "is within 1.5 metres of you")
                    self.hasfund = true;
                   
                    
                } else if (value >= 0.85 && !self.hasfund2 && self.objToFind[1] == objectName) {
                    
                    let node = self.sceneView.scene.rootNode.childNode(withName: "label", recursively: false)
                    node?.removeFromParentNode()
                    
                    var timer = Timer()
                    timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false, block: { (Timer) in
                        self.hasfund = false;
                        self.hasfund2 = false;
                        let node = self.sceneView.scene.rootNode.childNode(withName: "label", recursively: false)
                        node?.removeFromParentNode()
                        self.objToFind = ["",""]
                    })
                
                    self.ImpactGenerator.impactOccurred()
                    self.makeNode()
                    self.hasfund2 = true;
                    self.synth.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
                    self.sppec(text: "you have found your " + self.objToFind[1] + " it is approximately " + String(format:"-%.2f", abs(d) ) + " metres in front of you" )
                    UIView.animate(withDuration: 2, animations: {
                        self.viewb.frame.origin = self.origin
                        self.tabelView.alpha = 1
                    }) { (Bool) in
                        self.tabelView.isHidden = false
                    }
                   
                }
                
            } else {
                if (value >= 0.85 && !self.hasfund && self.objToFind[0] == objectName) {
                    
                    self.ImpactGenerator.impactOccurred()
                    self.makeNode()
                    self.hasfund = true;
                    self.synth.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
                    self.sppec(text: "you have found your " + self.objToFind[0] + " it is approximately " + String(format:"-%.2f", abs(d) ) + " metres in front of you" )
                    UIView.animate(withDuration: 1, animations: {
                        self.viewb.frame.origin = self.origin
                        self.tabelView.alpha = 1
                    }) { (Bool) in
                        self.tabelView.isHidden = false
                    }
                    
                    var timer = Timer()
                    timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false, block: { (Timer) in
                        self.objToFind = ["",""]
                        self.hasfund = false;
                        self.hasfund2 = false;
                        let node = self.sceneView.scene.rootNode.childNode(withName: "label", recursively: false)
                        node?.removeFromParentNode()
                    })
                    
                }
            }
        
            
            if self.hasfund || self.hasfund2{
                self.latestPrediction = objectName
                self.debugTextView.text = String(format:"%.2f", abs(d)) + " m"
                self.chackDist()
               
            }
           
            
            
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
    }
    
    func distanceFromCamera(x: Float, y:Float, z:Float) -> Float {
        let cameraPosition =  self.sceneView.session.currentFrame!.camera.transform.columns.3
      
        let vector = SCNVector3Make(cameraPosition.x - x, cameraPosition.y - y, cameraPosition.z - z)
        
        // Scene units map to meters in ARKit.
        return sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }

    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
}

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}



extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
