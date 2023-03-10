//
//  ViewController.swift
//  TravelBook
//
//  Created by Ecem Öztürk on 10.03.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var noteText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        //konumun verisi ne kadar keskinlikle bulunacak
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //kullanıcıdan izin istemek
        locationManager.requestWhenInUseAuthorization()
        //kullanıcının yerini almaya başla
        locationManager.startUpdatingLocation()
        
        //Harita üzerinde pinleme yapmak için ekrana uzun basıldığında algılanması
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3 // 3 sn basınca algıla
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" {
            //CoreData
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        noteText.text = annotationSubtitle
                                    }
                                }
                            }
                        }
                    }
                }
                
            } catch {
                print("error")
            }
            
        } else {
            // Add new data
        }
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        //tıklanılan yerin koordinatlarını al
        
        //gesture recognizer başladıysa (bir dokunma işlemi görüyor isek):
        if gestureRecognizer.state == .began {
            //dokunulan noktaları alalım
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            //dokunulan noktayı koordinata çevir
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //saveButtonClicked() 'de koordinatların alınması için dışardaki değişkenlere burada değer atadık
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            //pinin (annotation'un) oluşturulması
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = noteText.text
            //Oluşturulan pinin eklenmesi
            self.mapView.addAnnotation(annotation)
        }
    }
    
    
    //Bu fonksyion bize güncellenen lokasyonları bir dizi içerisinde ([CLLocation]) verir
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //locations[0] // CLLocation Objesi : İçinde enlem ve boylam barındıran bir obje
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom seviyesi, değerler (0.05) ne kadar küçük olursa o kadar zoomlamış oluruz
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        //merkez neresi alınsın ve ne kadar zoomlansın
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(noteText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
    }
    
}

