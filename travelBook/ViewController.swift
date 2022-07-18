//
//  ViewController.swift
//  travelBook
//
//  Created by Doğukan Doğan on 22.06.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    let mapView = MKMapView()
    var width = Double()
    var height = Double()
    var locationManager = CLLocationManager()
    var titleTextField = UITextField()
    var commentTextField = UITextField()
    var saveButton = UIButton()
    var longitude = Double()
    var latitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        width = view.frame.size.width
        height = view.frame.size.height
        
        if selectedTitle != ""{
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId!.uuidString
            request.predicate = NSPredicate(format: "id = %@", idString)
            request.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(request)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "comment") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let cordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = cordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        titleTextField.text = annotationTitle
                                        commentTextField.text = annotationSubtitle
                                        saveButton.isHidden = true
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: cordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("error")
            }
            
        }else{
        }
        
        titleTextField.placeholder = "Title"
        titleTextField.textAlignment = .center
        titleTextField.layer.borderWidth = 1
        titleTextField.frame = CGRect(x: width * 0.5 - width * 0.5 / 2, y: height * 0.2 - height * 0.05 / 2, width: width * 0.5, height: height * 0.05)
        view.addSubview(titleTextField)
        
        commentTextField.placeholder = "Comment"
        commentTextField.textAlignment = .center
        commentTextField.layer.borderWidth = 1
        commentTextField.frame = CGRect(x: width * 0.5 - width * 0.5 / 2, y: height * 0.27 - height * 0.05 / 2, width: width * 0.5, height: height * 0.05)
        view.addSubview(commentTextField)
        
        saveButton.setTitle("Save", for: UIControl.State.normal)
        saveButton.setTitleColor(UIColor.black, for: UIControl.State.normal)
        saveButton.layer.borderWidth = 1
        saveButton.frame = CGRect(x: width * 0.5 - width * 0.5 / 2, y: height * 0.36 - height * 0.05, width: width * 0.5, height: height * 0.05)
        view.addSubview(saveButton)
        
        saveButton.addTarget(self, action: #selector(saveClick), for: UIControl.Event.touchUpInside)
        
        
        mapView.delegate = self
        mapView.frame = CGRect(x: width * 0.5 - width / 2, y: height * 0.7 - height * 0.5 / 2, width: width, height: height * 0.5)
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        view.addSubview(mapView)
        
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chosenLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
    }
    
    @objc func saveClick(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(titleTextField.text, forKey: "title")
        newPlace.setValue(commentTextField.text, forKey: "comment")
        newPlace.setValue(longitude, forKey: "longitude")
        newPlace.setValue(latitude, forKey: "latitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("succed")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func chosenLocation(gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchCordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            longitude = touchCordinates.longitude
            latitude = touchCordinates.latitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCordinates
            annotation.title = titleTextField.text
            annotation.subtitle = commentTextField.text
            mapView.addAnnotation(annotation)
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.gray
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            
            pinView?.annotation = annotation
            
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                
                if let placemark = placemarks {
                    
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeKey]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }

}

