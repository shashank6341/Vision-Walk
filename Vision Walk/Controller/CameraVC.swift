//
//  ViewController.swift
//  Vision Walk
//
//  Created by Shashank Verma on 14/02/20.
//  Copyright © 2020 Shashank Verma. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraVC: UIViewController {
    
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    
    var flashControlState: FlashState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    var reachability: Reachability?
    var languageSelection: String = "en-US"
    var languageChangedString: String = ""

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureImageView: UIImageView!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var langBtn: UIButton!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var roundedLblView: UIView!
    @IBOutlet weak var internetView: UIView!
    @IBOutlet weak var internetLbl: UILabel!
    //    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reachability = Reachability.init()
        
        reachability?.whenReachable = { _ in
            DispatchQueue.main.async {
                self.internetLbl.text! = "Internet Available"
            }
        }
        reachability?.whenUnreachable = { _ in
            DispatchQueue.main.async {
                self.internetLbl.text! = "Internet Not Available"
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(internetChanged), name: Notification.Name.reachabilityChanged, object: reachability)
        do{
            try reachability?.startNotifier()
        }catch{
            print("Couldn't Start Notifier")
        }
        
    }
    
    @objc func internetChanged(note: Notification){
        let reachability = note.object as! Reachability
        if reachability.isReachable{
            DispatchQueue.main.async {
                self.internetLbl.text! = "Internet Available"
                self.internetView.backgroundColor = .green
                self.internetViewVisibility()
                
            }
        }else{
            DispatchQueue.main.async {
                self.internetLbl.text! = "Internet Not Available"
                self.internetView.backgroundColor = .red
                self.internetViewVisibility()
            }
        }
    }
    
    func internetViewVisibility(){
     UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
         
         self.internetView.alpha = 1.0
         
     }) { (finished: Bool) in
         
         self.internetView.isHidden = false
     }
     
     UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
         
         self.internetView.alpha = 0.0
         
     }) { (finished: Bool) in
         
         self.internetView.isHidden = true
     }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch {
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView() {
//        self.cameraView.isUserInteractionEnabled = false
//        self.spinner.isHidden = false
//        self.spinner.startAnimating()
//
        let settings = AVCapturePhotoSettings()
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        settings.flashMode = .auto
//        if flashControlState == .off {
//            settings.flashMode = .off
//        } else {
//            settings.flashMode = .on
//        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        
        for classification in results {
            if classification.confidence < 0.5 {
                var unknownObjectMessage = "Not Sure, Please Try Again."
                self.identificationLbl.text = unknownObjectMessage
                self.confidenceLbl.text = "CONFIDENCE: --"
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                if languageSelection == "en-US" {
                    synthesizeSpeech(fromString: unknownObjectMessage)
                    break
                } else {
                    unknownObjectMessage = "निश्चित नहीं है, कृपया पुनः प्रयास करें"
                    synthesizeSpeech(fromString: unknownObjectMessage)
                    break
                }
//
//                synthesizeSpeech(fromString: unknownObjectMessage)
//                self.confidenceLbl.text = ""
//                break
            } else {
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "CONFIDENCE: \(confidence)%"
                if languageSelection == "en-US" {
                    let completeSentence = "Looks like a \(identification), \(confidence)% Sure"
                    synthesizeSpeech(fromString: completeSentence)
                    break
                } else {
                    let completeSentence = "ये है \(identification), \(confidence) प्रतिशत यकीन है"
                    synthesizeSpeech(fromString: completeSentence)
                    break
                }
//                let completeSentence = "Looks like a \(identification), \(confidence)% Sure"
//                synthesizeSpeech(fromString: completeSentence)
//                break
            }
        }
    }
    
    func synthesizeSpeech(fromString string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
//        let speechUtterance = AVSpeechUtterance(string: "Pineapple 100% sure")
//        speechUtterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        speechUtterance.voice = AVSpeechSynthesisVoice(language: languageSelection)
        speechSynthesizer.speak(speechUtterance)
    }
    
    @IBAction func flashBtnWasPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
        }
    }
    
    @IBAction func langBtnWasPressed(_ sender: Any) {
        
        if languageSelection == "en-US" {
            languageSelection = "hi_IN"
            langBtn.setTitle("Language: Hindi", for: .normal)
            languageChangedString = "भाषा हिंदी में बदल गई"
            synthesizeSpeech(fromString: languageChangedString)
        } else {
            languageSelection = "en-US"
            langBtn.setTitle("Language: English", for: .normal)
            languageChangedString = "Language Changed to English"
            synthesizeSpeech(fromString: languageChangedString)
        }
    }
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: Inceptionv3().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
            
            captureImageView.isHidden = false
            captureImageView.alpha = 1.0
            
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                
                self.captureImageView.alpha = 0.0
                
            }) { (finished: Bool) in
                
                self.captureImageView.isHidden = true
            }
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        self.cameraView.isUserInteractionEnabled = false
//        self.spinner.isHidden = false
//        self.spinner.stopAnimating()
    }
}
