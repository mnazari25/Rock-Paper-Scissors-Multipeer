//
//  MPConnectionManager.swift
//  1502MP_Chat
//
//  Created by JamieBrown on 2/19/15.
//  Copyright (c) 2015 JamieBrown. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MPConnectionManager: NSObject, MCSessionDelegate {

    
    /* Make this class a singleton. 
    Provide access to a static instance of this class.
    That will be the only instance of this class that ever exists.*/
    
    class var instance: MPConnectionManager {
        struct theStruct{
            static let staticInstance: MPConnectionManager = MPConnectionManager(); }
            return theStruct.staticInstance
    }
    
    /* All init's must be private so our staticInstance is the only one.
        Otherwise we could accidentally create a second instance. */
    override private init() {}
    
    
    //MARK: - Properties
  
    let serviceID = "mdf2-chat"
    
    let stateChangedBroadcastID = "CM_StateChanged"
    let dataReceivedBroadcastID = "CM_ReceivedData"
    
    
    /* The Four Main Building Block of a MultiPeer App */
    
    var pID:MCPeerID! //The Name of the device that we are running on.
    
    var session:MCSession! // The 'connection' between devices.
    
    var browser:MCBrowserViewController! // Prebuilt VC that searches for nearby Advertisers
    
    var advertiser:MCAdvertiserAssistant! //Helps us easily advertise ourselves to nearby MCBrowser.
    
    
    //MARK: - Instance Methods
    
    /**
    Setup our Display Name that will be  visible to others in the browser VC
    
    - parameter displayName: Will represent our device to other Browsers
    
    - returns: none
    */
    func setDisplayName(displayName: String) {
        pID = MCPeerID(displayName: displayName)
    }
    
    
    /**
    Call after PeerID is set to instantiate an MCSession
    
    We create an MCSession using our PeerID, and set it's delegate to self (MPConnectionManager).
    This lets us catch the delegate methods like data tranfers and connection changes. 
    Also lets us handle them right inside of our MPConnectionManager Singleton.
    */
    func setupSession() {
        session = MCSession(peer: pID)
        session.delegate = self;
    }
    
    
    /**
    Creates an MCBRowserVC that searches the specified 'channel' serviceID
    
    - parameter serviceID: the 'channel' that the browser will search for advertisers on. Must be 1-15 lowercase characters. Only letters numbers and hyphen.
    */
    func setupBrowser(serviceID: String) { 
       
        browser = MCBrowserViewController(serviceType: serviceID, session: session)
    }
    
    
    /**
    Turns advertising On/Off for a given session and serviceID
    
    - parameter shouldAdvertise: Turns Advertising On(true) / Off(false)
    - parameter serviceID: serviceType that the advertiser will advertise to. 
    Must be 1-15 lowercase characters. Only letters numbers and hyphen.
    
    */
    func advertiseSelf(shouldAdvertise: Bool, serviceID: String = "") {
        
        if shouldAdvertise && serviceID != "" {
            advertiser = MCAdvertiserAssistant(serviceType: serviceID,
                                discoveryInfo: nil, session: session)
            advertiser.start()
        }
        else {
            if advertiser != nil {
                advertiser.stop()
                advertiser = nil
            }
        }
    }
    
    
    //MARK: - MCSession Delegate Methods
    
    // Remote peer changed state
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState){
        
        let sessionInfo:[String: AnyObject] = ["peerID": peerID, "state": state.rawValue]
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName( self.stateChangedBroadcastID, object: nil, userInfo: sessionInfo)
        })
    }
    
    // Received data from remote peer
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
   
        let transmission:[String: AnyObject] = ["peerID": peerID, "data": data]
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName( self.dataReceivedBroadcastID, object: nil, userInfo: transmission)
        })
    }
    
    // Received a byte stream from remote peer
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    // Start receiving a resource from remote peer
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}
    
    // Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?){}
}
