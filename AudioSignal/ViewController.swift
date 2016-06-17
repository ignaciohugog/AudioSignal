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

	var playState = AMPlayer()
	var recordState = AMRecorder()


	override func viewDidLoad() {
		super.viewDidLoad()
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextView) name:@"incoming" object:nil];
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.update(_:)), name: "incoming", object: nil)
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	@IBAction func sendClicked(sender: AnyObject) {
		//receiveTextView.text = sendTextView.text
		playState.playMessage("hello world!")


	}

	@IBAction func receiveClicked(sender: AnyObject) {
		
		recordState.startRecording()
	}

	func update(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			receiveTextView.text = userInfo["text"] as? String
		}
	}

}

