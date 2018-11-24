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

class ViewController: UIViewController, ARSCNViewDelegate, AVSpeechSynthesizerDelegate {
    
    // SCENE
    @IBOutlet var sceneView: ARSCNView!
    let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    var latestPredictionPos = SCNVector3()
    var hasfund = false;
    var objToFind = ["water bottle","cassette"]
    let dispatchQ = DispatchQueue(label: "com.hw.dis") // A Serial Queue
    
    // COREML
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    
    let synth = AVSpeechSynthesizer()
    var node = SCNNode()
    
    @IBOutlet weak var debugTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.scene.rootNode.addChildNode(node)
        
        //////////////////////////////////////////////////
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        
        //////////////////////////////////////////////////
        
        // Set up Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal
        
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
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Interaction
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        sppec(text: "your " + objToFind[1] + " is in the kitchen next to the " + objToFind[0])
    }
    
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
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
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
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(nodeForURL())
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
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
        print("Camera: \(cameraPosition)")
        let vector = SCNVector3Make(cameraPosition.x, cameraPosition.y - 0.4, cameraPosition.z)

        if abs(d) > 2.0 {
            node.removeFromParentNode()
            node = CylinderLine(parent: SCNNode(), v1: vector, v2: latestPredictionPos, radius: 0.02, radSegmentCount: 22, color: UIColor.red)
            sceneView.scene.rootNode.addChildNode(node)

        } else if abs(d) < 2.0 && bb{
            node.runAction(SCNAction.sequence([SCNAction.fadeOut(duration: 1.5),SCNAction.run({ (SCNNode) in
                self.node.removeFromParentNode()
                self.node.removeAllActions()
                
            })]))
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
            print(classifications)
            print("--")
            
            // Display Debug Text on screen
            var debugText:String = ""
            debugText += classifications
            self.debugTextView.text = debugText
            
            // Store the latest prediction
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            guard let value = Float(classifications.components(separatedBy: "-")[1]) else {return}
            print(objectName)
            print(value)
            
            
            let d =  self.distanceFromCamera(x: self.latestPredictionPos.x,y: self.latestPredictionPos.y,z: self.latestPredictionPos.z)
            
            
            if self.objToFind.count > 1 {
                if (value >= 0.65 && !self.hasfund && self.objToFind[0] == objectName) {
                    self.latestPrediction = objectName
                    self.makeNode()
                    self.synth.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
                    self.sppec(text: "your " + self.objToFind[1] + "is with him 1.5 metres of you")
                    self.hasfund = true;
                } else if (value >= 0.65 && !self.hasfund2 && self.objToFind[1] == objectName) {
                    let node = self.sceneView.scene.rootNode.childNode(withName: "label", recursively: false)
                    node?.removeFromParentNode()
                    self.makeNode()
                    self.hasfund2 = true;
                    self.synth.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
                    self.sppec(text: "you have found your " + self.objToFind[1] + " it is approximately " + String(format:"-%.2f", abs(d) ) + " metres in front of you" )
                }
                
            } else {
                if (value >= 0.65 && !self.hasfund && self.objToFind[0] == objectName) {
                    self.latestPrediction = objectName
                    self.makeNode()
                    self.synth.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
                    self.sppec(text: "your " + self.objToFind[1] + "is with him 1.5 metres of you")
                    self.hasfund = true;
                }
            }
        
            
            if self.hasfund || self.hasfund2{
                self.latestPrediction = objectName
                self.debugTextView.text = String(format:"-%.2f", d)
                self.chackDist()
            }
           
            
            
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
    }
    
    func distanceFromCamera(x: Float, y:Float, z:Float) -> Float {
        let cameraPosition =  self.sceneView.session.currentFrame!.camera.transform.columns.3
        print("Camera: \(cameraPosition)")
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
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}

