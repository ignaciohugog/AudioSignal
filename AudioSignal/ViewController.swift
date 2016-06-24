//
//  ViewController.swift
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class ViewController: UIViewController {

	@IBOutlet weak var sendTextView: UITextField!

	@IBOutlet weak var activityIndicator: NVActivityIndicatorView!
	@IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
	var playState = AudioPlayer()
	var recordState = AudioRecorder()


	override func viewDidLoad() {
		super.viewDidLoad()
		activityIndicator.type = .BallPulse
		activityIndicator.color = UIColor.blackColor()
		activityIndicator.hidesWhenStopped = true


		activityIndicatorView.type = .LineScale
		activityIndicatorView.color = UIColor.blackColor()
		activityIndicatorView.hidesWhenStopped = true

		recordState.startRecording()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.update(_:)), name: "incoming", object: nil)
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	@IBAction func sendClicked(sender: UIButton) {
		sender.selected = !sender.selected
		if sender.selected {
			recordState.stopRecording()
			playState.playMessage("@"+self.sendTextView.text!+"@")
			activityIndicator.startAnimation()
			activityIndicatorView.startAnimation()
		}else{
			activityIndicator.stopAnimation()
			activityIndicatorView.stopAnimation()
			playState.stopPlaying();
			recordState.startRecording()
		}
	}

	func update(notification: NSNotification) {
		let message = notification.userInfo!["text"] as! String
		if checker(message) {
			showAlert(message)
		}else{
			print(message)
		}
	}

	func showAlert(message:String) {
		let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Destructive, handler: { action in
			self.recordState.stopRecording()
			self.recordState.startRecording()
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}

	func checker(message: String) -> Bool {
		return message.characters.first == "@" && message.characters.last == "@"
	}
}

