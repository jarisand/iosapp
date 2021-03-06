//
//  MapViewController.swift
//  Bacon
//
//  Created by iosdev on 22.4.2016.
//  Copyright © 2016 iosdev. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, ESTBeaconManagerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var checkpointButton: UIButton!
    
    @IBOutlet weak var hint1View: UITextView!
    @IBOutlet weak var hint2View: UITextView!
    @IBOutlet weak var extraHintBtn: UIButton!
    
    let appDelegate     = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var beaconMajorMinor = String()
    var eventID = Int()
    var extraSeen = false
    var visitedBeacons : [String] = []
    var numberOfCheckpoints = Int()
    var moc: NSManagedObjectContext?
    var i = 0
    var nextCheckpoint = String()
    
    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 1.0, regionRadius * 1.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    //1
    let beaconManager = ESTBeaconManager()
    let beaconRegion = CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "DBB26A86-A7FD-45F7-AEEA-3A1BFAC8D6D9")!,
        identifier: "ranged region")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("1INDEX: ", i)
        moc = appDelegate.managedObjectContext
        hint1View.hidden = true
        hint2View.hidden = true
        extraHintBtn.hidden = true
        checkpointButton.hidden = true
        getHints()
        
        // set initial location to Metropolia
        let initialLocation = CLLocation(latitude: 60.221803, longitude: 24.804408)
        centerMapOnLocation(initialLocation)
        // 3. Set the beacon manager's delegate
        self.beaconManager.delegate = self
        // 4. We need to request this authorization for every beacon manager
        self.beaconManager.requestAlwaysAuthorization()
        
        print(eventID)
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Bordered, target: self, action:"back:")
        self.navigationItem.leftBarButtonItem = newBackButton;
    }
    
    func back(sender: UIBarButtonItem) {
        let nextController = self.navigationController!.viewControllers[4] as! EventViewController
        self.navigationController?.popToViewController(nextController, animated: true)
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    
    @IBAction func hintAction(sender: UIButton) {
        if hint1View.hidden == true && extraSeen == false{
        hint1View.hidden = false
        extraHintBtn.hidden = false
        }
        else if hint1View.hidden == false && extraSeen == false{
            hint1View.hidden = true
            extraHintBtn.hidden = true
        }
        else if hint1View.hidden == true && extraSeen == true{
            hint1View.hidden = false
            hint2View.hidden = false
            extraHintBtn.hidden = false
        }
        else if hint1View.hidden == false && extraSeen == true{
            hint1View.hidden = true
            hint2View.hidden = true
            extraHintBtn.hidden = true
        }
        
    }
    
    
    
    @IBAction func extraHintAction(sender: UIButton) {
        extraSeen = true
        hint2View.hidden = false
        extraHintBtn.enabled = true
    }
    
    
    let placesByBeacons = [
        "57832:7199": [
            "Blueberry beacon": 250,
        ],
        "911:912": [
            "Mint Beacon": 350,
        ],
        "1319:50423": [
            "Huutista!": 50,
            "Green & Green Salads": 150,
            "Mini Panini": 325
        ]
    ]
    
    func placesNearBeacon(beacon: CLBeacon) -> [String] {
        let beaconKey = "\(beacon.major):\(beacon.minor)"
        if let places = self.placesByBeacons[beaconKey] {
            let sortedPlaces = Array(places).sort() { $0.1 < $1.1 }.map { $0.0 }
            return sortedPlaces
        }
        return []
    }
    
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon],
                       inRegion region: CLBeaconRegion) {
        if let nearestBeacon = beacons.first {
            let places = placesNearBeacon(nearestBeacon)
            // TODO: update the UI here
            var nearest = String(nearestBeacon.major)
            print("Ennen if: ", nearestBeacon.major)
            
            //testaa, täsmääkö vihjeet ja lähin beacon
            if (places.first != nil && nextCheckpoint.containsString(nearest)){
                print("ifissä: ", places.first)
                checkpointButton.hidden = false
                beaconMajorMinor = "\(nearestBeacon.major):\(nearestBeacon.minor)"
                print(beaconMajorMinor)
                print("i after finding beacon")
                
            }
            else {
                checkpointButton.hidden = true
            }
        }
    }
    
    func manageBeacons(manager: AnyObject, didRangeBeacons beacons: [CLBeacon],
                       inRegion region: CLBeaconRegion) {
        if let nearestBeacon = beacons.first {
            let places = placesNearBeacon(nearestBeacon)
            // TODO: update the UI here
            print(places) // TODO: remove after implementing the UI
        }
    }
    
    
    func getHints(){
        let checkpointsFetch = NSFetchRequest(entityName: "Checkpoint")
        print(eventID)
        //let fetchRequest = NSFetchRequest()
        print("2INDEX: ", i)
        checkpointsFetch.predicate = NSPredicate(format: "eventID == %d", eventID)
        
        do {
            let fetchedCheckpoints = try moc!.executeFetchRequest(checkpointsFetch) as! [Checkpoint]
            nextCheckpoint = fetchedCheckpoints[i].beacon!
            hint1View.text = fetchedCheckpoints[i].hint
            hint2View.text = fetchedCheckpoints[i].hint2
            
            for Checkpoint in fetchedCheckpoints {
                print("CheckpointEntityData", Checkpoint.checkpointDescription)
            }

        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let DestViewController: CheckpointViewController = segue.destinationViewController as! CheckpointViewController
        DestViewController.eventID = eventID
        DestViewController.nearestBeacon = beaconMajorMinor
        DestViewController.visitedBeacons = visitedBeacons
        DestViewController.numberOfCheckpoints = numberOfCheckpoints
        i += 1
        DestViewController.i = i
    }
    
}

