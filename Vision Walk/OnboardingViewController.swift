//
//  OnboardingViewController.swift
//  Vision Walk
//
//  Created by Shashank Verma on 27/04/20.
//  Copyright © 2020 Shashank Verma. All rights reserved.
//

import UIKit
import AVFoundation

class OnboardingViewController: UIViewController {
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func detectBtn(_ sender: Any) {
    }
    
    @IBAction func languageBtn(_ sender: Any) {
    }
    
    
    @IBAction func startBtn(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let mainVC = storyboard.instantiateViewController(withIdentifier: "mainVC") as! CameraVC
//        mainVC.modalPresentationStyle = .fullScreen
        self.present(mainVC, animated: true, completion: nil)
    }
    
    func synthesizeSpeech(fromString string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        //                speechUtterance.voice = AVSpeechSynthesisVoice(language: languageSelection)
        speechSynthesizer.speak(speechUtterance)
    }
    
    
}

extension OnboardingViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    }
}
