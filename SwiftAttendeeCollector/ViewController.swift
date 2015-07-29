//
//  ViewController.swift
//  SwiftAttendeeCollector
//
//  Created by Zhu, Hongyu on 7/27/15.
//  Copyright (c) 2015 Zhu, Hongyu. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import MultipeerConnectivity


class ViewController: UIViewController, CBPeripheralManagerDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, UITableViewDataSource, UITableViewDelegate {


    @IBOutlet weak var startSearchButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var peripheralManager:CBPeripheralManager!
    var advertiser:MCNearbyServiceAdvertiser!
    var localPeerID:MCPeerID!
    var session : MCSession!
    var tableArrayDate = Array<Attendee>()
    var includedAttendees = Set<Attendee>()
    var attendeeManager:AttendeeManager!
    var isAdvertising:Bool = false
    var isRanging:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.localPeerID = MCPeerID(displayName:UIDevice.currentDevice().name)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        self.advertiser = MCNearbyServiceAdvertiser(peer:session.myPeerID, discoveryInfo:nil, serviceType:"cl-attendees")
        self.advertiser.delegate = self
        self.attendeeManager = AttendeeManager()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        //for test
        var a = Attendee(firstName: "a", lastName: "b", headLine: "c", attendeeID: "d")
        self.attendeeManager.addAttendee(newAttendee: a)
        self.tableArrayDate = Array(self.attendeeManager.attendeeArray)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapStartButton(sender: UIButton) {
        self.toggleAdvertising();
        
    }
    
    //Only react when it's poweredOn
    func toggleAdvertising(){
        if(self.peripheralManager.state == CBPeripheralManagerState.PoweredOn){
            if(self.isAdvertising){
                self.stopAdvertising()
            } else {
                self.startAdvertising()
            }
        }
    }
    
    func startAdvertising(){
        println("start advertising")
        self.clearCurrentAttendees()
        self.startSearchButton.setTitle("stop searching", forState: .Normal)
        
        var uuid = NSUUID()
        var region = CLBeaconRegion(proximityUUID: uuid, identifier: "AttendeeCollector")
        
        var advertisementData = region.peripheralDataWithMeasuredPower(nil)
        self.peripheralManager.startAdvertising(advertisementData as [NSObject : AnyObject])
        self.advertiser.startAdvertisingPeer()
        self.isAdvertising = true
    }
    
    func stopAdvertising(){
        println("stop advertising")
        self.startSearchButton.setTitle("start searching", forState: .Normal)
        self.peripheralManager.stopAdvertising()
        self.isAdvertising = false
    }
    
    
    //clear all attendees in the includedAttendees set
    func clearCurrentAttendees(){
        self.includedAttendees.removeAll(keepCapacity: false)
    }

    
    func addAttendeeToTable(){
//        var nextRow : Int = { return (self.tableArrayDate.count-1)}()
//        var indexPath = NSIndexPath(forRow: nextRow, inSection: 1)
//        var indexPaths = [indexPath]

        self.tableView.reloadData()
        
//        self.tableView.beginUpdates()
//        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
//        self.tableView.reloadData()
//        self.tableView.endUpdates()
    }
    
    
// MARK:implementing UITableViewDataSource and UITableViewDelegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.tableArrayDate.count;
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        cell.textLabel?.text = self.tableArrayDate[indexPath.row].firstName + " " + self.tableArrayDate[indexPath.row].lastName
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("You selected cell #\(indexPath.row)!")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        return 60
    }
    
    
// MARK:implementing MCSessionDelegate
    
    // Remote peer changed state
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState){
        switch (state) {
        case MCSessionState.NotConnected:
            println("didChangeState: Not Connected");
            break;
        case MCSessionState.Connected:
            println("didChangeState: Connected");
            break;
        case MCSessionState.Connecting:
            println("didChangeState: Connecting");
            break;
        }
    }
    
    
    
    
    // Received data from remote peer
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!){
        println("didReveiveData from  \(peerID.displayName)")
        println("\(data)")
        var attendee: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(data)
        println("Attendee: \(attendee)")
        
        //for test
        var a = Attendee(firstName: peerID.displayName, lastName: "b", headLine: "c", attendeeID: "d")
        self.attendeeManager.addAttendee(newAttendee: a)
        self.tableArrayDate = Array(self.attendeeManager.attendeeArray)
        
        dispatch_sync(dispatch_get_main_queue(), {
            self.addAttendeeToTable()
        })
//        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
//            self.addAttendeeToTable()
//        })
    }
    
    // Received a byte stream from remote peer
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!){
        println("didReceiveStream")
    }
    
    // Start receiving a resource from remote peer
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!){
        println("didStartReceivingResourceWithName from "+peerID.displayName)
    }
    
    // Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!){
        println("didFinishReceivingResourceWithName from "+peerID.displayName)
    }


// MARK:implementing MCNearbyServiceAdvertiserDelegate
    
    // Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!){
        self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        self.session.delegate = self
        invitationHandler(true,self.session)
        println("didReceiveInvitation")
    }
    
    // Advertising did not start due to an error
//    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!){
//    }
    
    
    
// MARK:implementing CBPeripheralManagerDelegate
    
    /*!
    *  @method peripheralManagerDidUpdateState:
    *
    *  @param peripheral   The peripheral manager whose state has changed.
    *
    *  @discussion         Invoked whenever the peripheral manager's state has been updated. Commands should only be issued when the state is
    *                      <code>CBPeripheralManagerStatePoweredOn</code>. A state below <code>CBPeripheralManagerStatePoweredOn</code>
    *                      implies that advertisement has paused and any connected centrals have been disconnected. If the state moves below
    *                      <code>CBPeripheralManagerStatePoweredOff</code>, advertisement is stopped and must be explicitly restarted, and the
    *                      local database is cleared and all services must be re-added.
    *
    *  @see                state
    *
    */
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!){
        var stateLabel:String!
        switch (peripheral.state) {
        case CBPeripheralManagerState.PoweredOff:
            stateLabel = "Powered Off";
            break;
        case CBPeripheralManagerState.PoweredOn:
            stateLabel = "Powered On";
            break;
        case CBPeripheralManagerState.Resetting:
            stateLabel = "Resetting";
            break;
        case CBPeripheralManagerState.Unauthorized:
            stateLabel = "Unauthorized";
            break;
        case CBPeripheralManagerState.Unknown:
            stateLabel = "Unknown";
            break;
        case CBPeripheralManagerState.Unsupported:
            stateLabel = "Unsupported";
            break;
        }
        println("peripheralManagerDidUpdateState \(stateLabel)")
    }
    
    /*!
    *  @method peripheralManager:willRestoreState:
    *
    *  @param peripheral	The peripheral manager providing this information.
    *  @param dict			A dictionary containing information about <i>peripheral</i> that was preserved by the system at the time the app was terminated.
    *
    *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
    *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
    *						Bluetooth system.
    *
    *  @seealso            CBPeripheralManagerRestoredStateServicesKey;
    *  @seealso            CBPeripheralManagerRestoredStateAdvertisementDataKey;
    *
    */
    func peripheralManager(peripheral: CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!){
    }
    
    /*!
    *  @method peripheralManagerDidStartAdvertising:error:
    *
    *  @param peripheral   The peripheral manager providing this information.
    *  @param error        If an error occurred, the cause of the failure.
    *
    *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
    *                      not be started, the cause will be detailed in the <i>error</i> parameter.
    *
    */
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!){
        if(error==nil){
            println("start advertising")
        } else {
            println("\(error)")
        }
    }
    
    /*!
    *  @method peripheralManager:didAddService:error:
    *
    *  @param peripheral   The peripheral manager providing this information.
    *  @param service      The service that was added to the local database.
    *  @param error        If an error occurred, the cause of the failure.
    *
    *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
    *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
    *
    */
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!){
    }
    
    /*!
    *  @method peripheralManager:central:didSubscribeToCharacteristic:
    *
    *  @param peripheral       The peripheral manager providing this update.
    *  @param central          The central that issued the command.
    *  @param characteristic   The characteristic on which notifications or indications were enabled.
    *
    *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
    *                          It should be used as a cue to start sending updates as the characteristic value changes.
    *
    */
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didSubscribeToCharacteristic characteristic: CBCharacteristic!){
    }
    
    /*!
    *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
    *
    *  @param peripheral       The peripheral manager providing this update.
    *  @param central          The central that issued the command.
    *  @param characteristic   The characteristic on which notifications or indications were disabled.
    *
    *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
    *
    */
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic!){
    }
    
    /*!
    *  @method peripheralManager:didReceiveReadRequest:
    *
    *  @param peripheral   The peripheral manager requesting this information.
    *  @param request      A <code>CBATTRequest</code> object.
    *
    *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
    *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
    *
    *  @see                CBATTRequest
    *
    */
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!){
        println("didReceiveReadRequest \(request)")
        peripheral.respondToRequest(request, withResult: CBATTError.Success)
    }
    
    /*!
    *  @method peripheralManager:didReceiveWriteRequests:
    *
    *  @param peripheral   The peripheral manager requesting this information.
    *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
    *
    *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
    *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
    *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
    *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
    *
    *  @see                CBATTRequest
    *
    */
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveWriteRequests requests: [AnyObject]!){
    }
    
    /*!
    *  @method peripheralManagerIsReadyToUpdateSubscribers:
    *
    *  @param peripheral   The peripheral manager providing this update.
    *
    *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
    *                      ready to send characteristic value updates.
    *
    */
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager!){
    }



}

