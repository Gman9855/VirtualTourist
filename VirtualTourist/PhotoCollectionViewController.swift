//
//  PhotoCollectionViewController.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/4/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var proxyPin: ProxyPin!
    var cache = ImageCache.Caches.imageCache
    var downloadInProgress = false
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [self.proxyPin.pin])
        fetchRequest.predicate = predicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    //MARK: View Controller life cycle
    
    override func viewDidLoad() {
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        mapView.delegate = self
        mapView.scrollEnabled = false
        
        setMapRegionFromPin()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fetchPhotosFromFlickr()
    }
    
    //MARK: Action Methods
    
    @IBAction func buttonTapped(sender: UIButton) {
        self.toggleButtonsDuringDownload(false, navButtonHidden: true, downloadInProgress: true)
        
        deleteAllPhotos() { result in
            if result {
                self.fetchPhotosFromFlickr()
            } else {
                println("error")
            }
        }
    }
    
    // MARK: Collection View Delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! PhotoCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        configureCell(cell, photo: photo)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if !downloadInProgress {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            deletePhoto(photo)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if !downloadInProgress {
            switch type {
            case .Delete:
                collectionView.deleteItemsAtIndexPaths([indexPath!])
            case .Update:
                let cell = collectionView.cellForItemAtIndexPath(indexPath!) as! PhotoCell
                let photo = controller.objectAtIndexPath(indexPath!) as! Photo
                configureCell(cell, photo: photo)
            default:
                return
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }
    
    func configureCell(cell: PhotoCell, photo: Photo) {
        var newImage = UIImage(named: "placeholder")
        cell.imageView!.image = nil
        
        if photo.imagePath == nil || photo.imagePath == "" {
            newImage = UIImage(named: "noImage")
        } else if photo.photoImage != nil {
            newImage = photo.photoImage
        } else {
            var flickr = Flickr(lat: proxyPin.latitude, lon: proxyPin.longitude)
            
            let task = flickr.taskForImage(photo.imagePath!) { data, error in
                if let error = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        newImage = UIImage(named: "noImage")
                    }
                }
                
                if let data = data {
                    let image = UIImage(data: data)
                    self.sharedContext.performBlockAndWait({ () -> Void in
                        photo.photoImage = image
                    })
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                    }
                }
            }
            
            cell.taskToCancelIfCellIsReused = task
        }
        cell.imageView!.image = newImage
    }
    
    //MARK:  Flickr
    
    func fetchPhotosFromFlickr() {
        
        if proxyPin.pin.photos.isEmpty {
            self.toggleButtonsDuringDownload(false, navButtonHidden: true, downloadInProgress: true)
            
            var flickr = Flickr(lat: proxyPin.latitude, lon: proxyPin.longitude)
            flickr.search() {JSONResult, error in
                if let error = error {
                    println("Download Error")
                } else {
                    if let result = JSONResult as? [[String: AnyObject]] {
                        
                        if result.isEmpty {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                let label = UILabel(frame: CGRectMake(0, 0, 200, 30))
                                label.text = "No photos found."
                                label.sizeToFit()
                                label.center = CGPointMake(self.view.bounds.width / 2, self.view.bounds.height / 4)
                                self.collectionView.addSubview(label)
                            })
                            
                        } else {
                            self.sharedContext.performBlockAndWait({ () -> Void in
                                var photos = result.map() { (dictionary: [String : AnyObject]) -> Photo in
                                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                    photo.pin = self.proxyPin.pin
                                    return photo
                                }
                                self.sharedContext.save(nil)
                            })
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            var delay = 0 * Double(NSEC_PER_SEC)
                            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                            if !result.isEmpty {
                                self.collectionView.reloadData()
                                
                                delay = 1 * Double(NSEC_PER_SEC)
                            }
                            
                            dispatch_after(time, dispatch_get_main_queue()) {
                                self.toggleButtonsDuringDownload(!result.isEmpty, navButtonHidden: false, downloadInProgress: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Core Data
    
    func deletePhoto(photo: Photo) {
        cache.deletePhotoCache(photo)
        sharedContext.deleteObject(photo)
        sharedContext.save(nil)
    }
    
    // Explicitly delete all photos
    func deleteAllPhotos(completionHandler: (succeeded: Bool) -> Void) {
        for photo in proxyPin.pin.photos {
            deletePhoto(photo)
        }
        completionHandler(succeeded: proxyPin.pin.photos.isEmpty)
    }
    
    //MARK: View State
    
    func setMapRegionFromPin() {
        if let pin = proxyPin {
            var location = CLLocationCoordinate2D(
                latitude: pin.latitude,
                longitude: pin.longitude
            )
            
            var span = MKCoordinateSpanMake(0.5, 0.5)
            var region = MKCoordinateRegion(center: location, span: span)
            
            mapView.addAnnotation(pin)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func toggleButtonsDuringDownload(newCollectionButtonEnabled: Bool, navButtonHidden: Bool, downloadInProgress: Bool) {
        self.downloadInProgress = downloadInProgress
        newCollectionButton.enabled = newCollectionButtonEnabled
        navigationItem.setHidesBackButton(navButtonHidden, animated: true)
        
        toggleButtonTitle()
    }
    
    // Helper function to change title during download.
    func toggleButtonTitle() {
        newCollectionButton.setTitle(downloadInProgress ? "Download in Progress" : "New Collection", forState: UIControlState.Normal)
    }
}
