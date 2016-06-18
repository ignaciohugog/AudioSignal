//
//  ViewController.swift
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet weak var sendTextView: UITextField!
	@IBOutlet weak var receiveTextView: UITextField!

	var playState = AudioPlayer()
	var recordState = AudioRecorder()


	override func viewDidLoad() {
		super.viewDidLoad()
		recordState.startRecording()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.update(_:)), name: "incoming", object: nil)
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	@IBAction func sendClicked(sender: AnyObject) {
		// TODO: when stop sending start recorder again
		if let message = sendTextView.text {
			recordState.stopRecording()
			playState.playMessage("@"+message+"@")
		}
	}

	@IBAction func receiveClicked(sender: AnyObject) {
		
		//recordState.startRecording()
	}

	func update(notification: NSNotification) {
		let message = notification.userInfo!["text"] as! String
		if checker(message) {
			recordState.stopRecording()
			showAlert(message)
			receiveTextView.text = message
		}else{
			print(message)
			recordState.startRecording()
		}
	}

	func showAlert(message:String) {
		let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Destructive, handler: { action in
			self.recordState.startRecording()
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}

	func checker(message: String) -> Bool {
		return message.characters.first == "@" && message.characters.last == "@"
	}



}

