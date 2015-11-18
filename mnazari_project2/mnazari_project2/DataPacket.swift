//
//  DataPacket.swift
//  mnazari_project2
//
//  Created by Mirabutaleb Nazari on 2/25/15.
//  Copyright (c) 2015 Bug Catcher Studios. All rights reserved.
//

import Foundation

class DataPacket: NSObject, NSCoding {
	
	var ready:Bool! // ready check variable
	var playerSelection:Int! // players selection
	
	private override init() {
		super.init()
	}
	
	/* Convenience Init */
	// sets player selection to default value unless new value is given
	convenience init(ready: Bool, playerSelection : Int = 3) {
		
		self.init()
		self.ready = ready
		self.playerSelection = playerSelection
		
	}
	
	/* Convenience Init */
	required convenience init?(coder aDecoder: NSCoder) {
		
		self.init()
		
		// rules for unpacking an NSData object
		ready  = aDecoder.decodeObjectForKey("ready") as! Bool
		playerSelection = aDecoder.decodeObjectForKey("playerSelection") as! Int
		
	}
	
	
	/* Instance Methods */
	
	func encodeWithCoder(coder: NSCoder) {
		
		coder.encodeObject(ready, forKey: "ready")
		coder.encodeObject(playerSelection, forKey: "playerSelection")
		
	}
	
}
