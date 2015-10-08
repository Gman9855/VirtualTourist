//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/3/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var gestureRecognizer: UILongPressGestureRecognizer!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        var error = NSErrorPointer()
        let savedPins = sharedContext.executeFetchRequest(fetchRequest, error: error) as! [Pin]
        let proxyPins = savedPins.map { (pin: Pin) -> ProxyPin in
            return ProxyPin(pin: pin)
        }
        self.mapView.addAnnotations(proxyPins)
        
        restoreMapRegion(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            let touchPoint = self.gestureRecognizer.locationInView(self.mapView)
            let touchCoordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            let pin = Pin(coordinate: touchCoordinate, context: self.sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            let proxyPin = ProxyPin(pin: pin)
            self.mapView.addAnnotation(proxyPin)
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation as? ProxyPin {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view.animatesDrop = true
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let proxyPin = view.annotation as! ProxyPin
        let navController = self.storyboard?.instantiateViewControllerWithIdentifier("photoCollectionNavVC") as! UINavigationController
        let photoCollectionVC = navController.topViewController as! PhotoCollectionViewController
        photoCollectionVC.proxyPin = proxyPin
        self.navigationController?.pushViewController(photoCollectionVC, animated: true)
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func saveMapRegion() {
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePathForMapRegion)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathForMapRegion) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2DMake(latitude, longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            
            let savedRegion = MKCoordinateRegionMake(center, span)
            
            self.mapView.setRegion(savedRegion, animated: animated)
            
            self.mapView.setCenterCoordinate(center, animated: true)
        }
    }
    
    var filePathForMapRegion : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
}
