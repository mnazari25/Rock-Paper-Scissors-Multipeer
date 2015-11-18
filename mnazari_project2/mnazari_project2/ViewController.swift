//
//  ViewController.swift
//  mnazari_project2
//
//  Created by Mirabutaleb Nazari on 2/25/15.
//  Copyright (c) 2015 Bug Catcher Studios. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate {
	
	//MARK: - Label and Button Outlets
	@IBOutlet weak var winNlosses: UILabel!
	@IBOutlet weak var countdownLabel: UILabel!
	@IBOutlet var rpsButtons: [UIButton]!
	@IBOutlet weak var readyButtonOutlet: UIButton!
	@IBOutlet weak var myImage: UIImageView!
	@IBOutlet weak var opponentImage: UIImageView!
	
	
	//MARK: - Variables and Constants
	let cManager = MPConnectionManager.instance
	let serviceID = "rpsMayhem"
	
	// default player objects
	var thisPlayer : DataPacket = DataPacket(ready: false)
	var opponentPlayer : DataPacket = DataPacket(ready: false)
	
	// win/losses counter variables
	var wins : Int = 0
	var losses : Int = 0
	var draws : Int = 0
	
	// countdown messages
	var theMessageArray = ["Both players are ready", "Make your pick!", "Rock...", "Paper...", "Scissors...", "Shoot!"]

	// sets currently selected button for adding border
	var currentActiveButton : UIButton?
	
	// holds connection status rawValue
	var connectionStatus : Int = 100
	
	
	//MARK: - Functions
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		/* Set up connection manager basics */
		cManager.setDisplayName(UIDevice.currentDevice().name)
		cManager.setupSession()
		cManager.advertiseSelf(true , serviceID: serviceID)
		
		readyButtonOutlet.enabled = false // disables ready button. This will be enabled when a connection is made to another player.
		toggleButtons() // runs toggle function to turn off game selection buttons
		
		//MARK: - Notification Listeners
		
		/* Set up our notification observers to listen for specific broadcasts and call a selector method when it hears a broadcast. */
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "connectChangedState:", name: cManager.stateChangedBroadcastID, object: nil)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReceived:", name: cManager.dataReceivedBroadcastID, object: nil)
		
		
	}
	
	// runs connection view controller
	@IBAction func connectTap(sender: UIBarButtonItem) {
		
		if cManager.session != nil {
			
			cManager.setupBrowser(serviceID)
			cManager.browser.delegate = self
			self.presentViewController(cManager.browser, animated: true, completion: nil)
			
		}
		
	}
	
	/**
	Call back function to catch changed state of MPConnectionManager session
	
	- parameter notification: NSNotification being broadcasted
	
	*/
	
	func connectChangedState(notification : NSNotification) {
		
		//TODO: Do something to indicate connection has changed
		
		let stateChange = notification.userInfo as Dictionary!
		
		if let state = stateChange["state"] as? Int {
			
			if state == MCSessionState.Connected.rawValue {
				
				connectionStatus = MCSessionState.Connected.rawValue
				
			}
			else if state == MCSessionState.Connecting.rawValue {
				
				connectionStatus = MCSessionState.Connecting.rawValue
				readyButtonOutlet.enabled = true // on connection enables ready button
				
			}
			else { //Not connected
				
				connectionStatus = MCSessionState.NotConnected.rawValue
				readyButtonOutlet.enabled = false // on disconnect disable ready button
				
				// resets win/losses
				wins = 0
				losses = 0
				draws = 0
				// removes border from currently selected button
				if let v = currentActiveButton {
					
					v.layer.borderWidth = 0
					
				}
				
				// turns off rps selection buttons
				for button in rpsButtons {
					
					button.enabled = false
					
				}
				
				// notifies user that they have been disconnected
				countdownLabel.text = "Disconnected. Press Connect to find opponent!"
				// hides any images up
				myImage.hidden = true
				opponentImage.hidden = true
				// shows disconnect message
				countdownLabel.hidden = false
				
			}
			
		}
		
		
	}
	
	@IBAction func readySend(sender: UIButton) {
		
		/* Init custom class */
		thisPlayer.ready = true
		sendPacket()
		checkReady()
		
		sender.enabled = false
		
	}
	
	func sendPacket(){
		
		/* Wrap up our Packet in an NSData Black Box */
		let dataBox:NSData! = NSKeyedArchiver.archivedDataWithRootObject(thisPlayer)
		
		var error: NSError?
		
		do {
			//Send our transmission to Peer
			try cManager.session.sendData(dataBox, toPeers: cManager.session.connectedPeers,
				withMode: MCSessionSendDataMode.Reliable)
		} catch let error1 as NSError {
			error = error1
		}
		
		if let err = error?.description { print(err) }
		
	}
	
	func dataReceived(notification : NSNotification) {
		
		//TODO: Do something to indicate connection has changed
		let transmission = notification.userInfo as Dictionary!
		
		//Access the entries in the dictionary and cast from AnyObject to NSData Object/MCPeerID
		let recievedData:NSData! = transmission["data"] as! NSData!
		let entity:MCPeerID! = transmission["peerID"] as! MCPeerID!
		
		//Decode the NSData Object into a DataPacket() object using DataPacket's init with Decoder.
		if var playerTwo = NSKeyedUnarchiver.unarchiveObjectWithData(recievedData) as? DataPacket{
			
			// checks to see if packet is true and has default selection value
			// this will be set to false only on packet being sent after countdown
			if playerTwo.playerSelection == 3 && playerTwo.ready == true {
				
				opponentPlayer = playerTwo // sets opponent player to received data packet
				checkReady() // runs ready check
				
			} else if playerTwo.ready == false {
				
				opponentPlayer = playerTwo // sets opponent player to received data packet
				compareResults() // compares the two player selections
				
			}
			
			
		}
	
	}
	
	func checkReady() {
		
		// if both players are ready starts a countdown and resets all UI for new game in case there was already a game played
		if thisPlayer.ready == true && opponentPlayer.ready == true {
			
			myImage.hidden = true
			opponentImage.hidden = true
			myImage.layer.borderWidth = 0
			opponentImage.layer.borderWidth = 0
			countdownLabel.text = "Let's Play!"
			countdownLabel.hidden = false
			opponentPlayer.ready = false
			thisPlayer.ready = false
			if let v = currentActiveButton {
				
				v.layer.borderWidth = 0
				
			}
			startCountdown() // runs countdown function
			
		}
		
	}
	
	func startCountdown() {
		
		toggleButtons()
		/* Make a Queue */
		let myQueue = dispatch_queue_create("com.gameCountdown.mdf2.now", DISPATCH_QUEUE_CONCURRENT)
		
		
		/* Weak self creates a temporary reference to self instead of retaining its information. */
		/* This is to avoid memory leaks later */
		dispatch_async(myQueue, {
			
			for var i = 0; i < self.theMessageArray.count + 1; i++ {
				
				[NSThread .sleepForTimeInterval(NSTimeInterval(1.5))] // sleeps 1.5 seconds in background
				
				dispatch_sync(dispatch_get_main_queue(), {
					
					if i != self.theMessageArray.count {
						
						self.countdownLabel.text = self.theMessageArray[i] // sets label to new message
						
						// if message is "Shoot" disables selection buttons
						if self.theMessageArray[i] == "Shoot!" {
							
							self.toggleButtons()
							
						}
						
					} else {
						
						self.sendPacket() // waits additional 1.5 seconds to send packet
						
					}
					
					
				})
				
			}
			
		})
		
	}
	
	@IBAction func rpsButton(sender: UIButton) {

		print("You chose \(sender.tag)")
		thisPlayer.playerSelection = sender.tag // sets player selection
		
		// turns off border of currentActiveButton if any have been selected yet
		if let v = currentActiveButton {
			
			v.layer.borderWidth = 0
			
		}
		
		/* Set tapped view to current view */
		currentActiveButton = sender
		currentActiveButton?.layer.borderColor = UIColor.whiteColor().CGColor
		currentActiveButton?.layer.borderWidth = 3
		
	}
	
	func compareResults(){
		
		print("Me: \(thisPlayer.playerSelection) Them: \(opponentPlayer.playerSelection)")
		countdownLabel.hidden = true // hides countdown label
		
		
		/* Game Logic */
		/* Determines winner and loser and applies appropiate image and border colors */
		switch thisPlayer.playerSelection {
			
		case 0:
			
			myImage.image = UIImage(named: "Rock")
			
			switch opponentPlayer.playerSelection{
				
			case 0:
				++draws
				updateScore()
				opponentImage.image = UIImage(named: "Rock")
				myImage.hidden = false
				opponentImage.hidden = false
			case 1:
				++losses
				updateScore()
				opponentImage.image = UIImage(named: "Paper")
				myImage.hidden = false
				opponentImage.hidden = false
				myImage.layer.borderWidth = 3
				myImage.layer.borderColor = UIColor.redColor().CGColor
				opponentImage.layer.borderWidth = 3
				opponentImage.layer.borderColor = UIColor.greenColor().CGColor
				
			case 2:
				++wins
				updateScore()
				opponentImage.image = UIImage(named: "Scissors")
				myImage.hidden = false
				opponentImage.hidden = false
				myImage.layer.borderWidth = 3
				myImage.layer.borderColor = UIColor.greenColor().CGColor
				opponentImage.layer.borderWidth = 3
				opponentImage.layer.borderColor = UIColor.redColor().CGColor
				
			default:
				print("You didn't press anything!!")
			}
			
		case 1:
			
			myImage.image = UIImage(named: "Paper")
			
			switch opponentPlayer.playerSelection{
				
			case 0:
				++wins
				updateScore()
				opponentImage.image = UIImage(named: "Rock")
				myImage.hidden = false
				opponentImage.hidden = false
				myImage.layer.borderWidth = 3
				myImage.layer.borderColor = UIColor.greenColor().CGColor
				opponentImage.layer.borderWidth = 3
				opponentImage.layer.borderColor = UIColor.redColor().CGColor
			case 1:
				++draws
				updateScore()
				opponentImage.image = UIImage(named: "Paper")
				myImage.hidden = false
				opponentImage.hidden = false
			case 2:
				++losses
				updateScore()
				opponentImage.image = UIImage(named: "Scissors")
				myImage.hidden = false
				opponentImage.hidden = false
				myImage.layer.borderWidth = 3
				myImage.layer.borderColor = UIColor.redColor().CGColor
				opponentImage.layer.borderWidth = 3
				opponentImage.layer.borderColor = UIColor.greenColor().CGColor
				
			default:
				print("You didn't press anything!!")
			}
		case 2:
			
			myImage.image = UIImage(named: "Scissors")
			switch opponentPlayer.playerSelection{
				
			case 0:
				++losses
				updateScore()
				opponentImage.image = UIImage(named: "Rock")
				myImage.hidden = false
				opponentImage.hidden = false
				myImage.layer.borderWidth = 3
				myImage.layer.borderColor = UIColor.redColor().CGColor
				opponentImage.layer.borderWidth = 3
				opponentImage.layer.borderColor = UIColor.greenColor().CGColor
				
			case 1:
				++wins
				updateScore()
				opponentImage.image = UIImage(named: "Paper")
				myImage.hidden = false
				opponentImage.hidden = false
				myImage.layer.borderWidth = 3
				myImage.layer.borderColor = UIColor.greenColor().CGColor
				opponentImage.layer.borderWidth = 3
				opponentImage.layer.borderColor = UIColor.redColor().CGColor
			case 2:
				++draws
				updateScore()
				opponentImage.image = UIImage(named: "Scissors")
				myImage.hidden = false
				opponentImage.hidden = false
			default:
				print("You didn't press anything!!")
				
			}
		default:
			switch opponentPlayer.playerSelection{
				
			case 3:
				print("You both suck! Press a button")

			default:
				break;
				
			}
			
		}
		
	}
	
	// updates score labels and sets players back to default values
	// reenables ready button for restart
	func updateScore() {
		
		/* Make a Queue */
		let myQueue = dispatch_queue_create("com.gameCountdown.mdf2.updatePause", DISPATCH_QUEUE_CONCURRENT)
		
		dispatch_async(myQueue, { [unowned self]() -> Void in
			
			[NSThread .sleepForTimeInterval(NSTimeInterval(2))]
			
			dispatch_sync(dispatch_get_main_queue(), {
				
				self.winNlosses.text = "W: \(self.wins) L: \(self.losses) D: \(self.draws)"
				
				self.thisPlayer = DataPacket(ready: false)
				self.opponentPlayer = DataPacket(ready: false)
				self.readyButtonOutlet.enabled = true
				
			})
			
		})
		
	}
	
	func toggleButtons() {
		
		for button in rpsButtons {
			
			button.enabled = !button.enabled
			
		}
		
	}

	// Notifies the delegate, when the user taps the done button
	func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
		
		cManager.browser.dismissViewControllerAnimated(true, completion: nil)
		
	}
	
	// Notifies delegate that the user taps the cancel button.
	func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
		
		browserViewController.dismissViewControllerAnimated(true, completion: nil)
		
	}
	
}

