//
//  LocationsViewController.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 30.11.2021.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class ImageAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    var colour: UIColor?

    override init() {
        self.coordinate = CLLocationCoordinate2D()
        self.title = nil
        self.subtitle = nil
        self.image = nil
        self.colour = UIColor.white
    }
}

class ImageAnnotationView: MKAnnotationView {
    private var imageView: UIImageView!

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(x: 0, y: 0, width: 50, height: 60)
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
        self.imageView.contentMode = .scaleAspectFill
        self.addSubview(self.imageView)

        self.imageView.layer.cornerRadius = 5.0
        self.imageView.layer.masksToBounds = true
        self.canShowCallout = true
    }

    override var image: UIImage? {
        get {
            return self.imageView.image
        }

        set {
            self.imageView.image = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LocationsViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedMoments = [Moments]()
    fileprivate var polygon: MKPolygon? = nil
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        for moment in fetchedMoments{
            let locations = moment.locations?.allObjects as! [Locations]
            let images = moment.images?.allObjects as! [Images]
            for location in locations {
                let momentAnotation = ImageAnnotation()
                momentAnotation.title = moment.name
                momentAnotation.subtitle = moment.note
                momentAnotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude,longitude: location.longitude)
                momentAnotation.image = UIImage(data: (images.first?.image)!,scale: UIScreen.main.scale)
                mapView.addAnnotation(momentAnotation)
            }
            
        }
        

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {  //Handle user location annotation..
                    return nil  //Default is to let the system handle it.
                }

                if !annotation.isKind(of: ImageAnnotation.self) {  //Handle non-ImageAnnotations..
                    var pinAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "DefaultPinView")
                    if pinAnnotationView == nil {
                        pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "DefaultPinView")
                    }
                    return pinAnnotationView
                }

                //Handle ImageAnnotations..
                var view: ImageAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: "imageAnnotation") as? ImageAnnotationView
                if view == nil {
                    view = ImageAnnotationView(annotation: annotation, reuseIdentifier: "imageAnnotation")
                }

                let annotation = annotation as! ImageAnnotation
                view?.image = annotation.image
                view?.annotation = annotation

                return view
    }
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        fetchDraws()
    }
    func fetchDraws(){
        do{
            let fetchedDraws:[Draws] = try context.fetch(Draws.fetchRequest())
            DispatchQueue.main.async {
                let fdCount = fetchedDraws.count
                if fdCount > 0 {
                    for fetchedDraw in fetchedDraws{
                        var coordinates = [CLLocationCoordinate2D]()
                        let fetchedCoordinates = fetchedDraw.coordinates?.allObjects as! [DrawCoordinates]
                        var sortedFetchedCoortidates:[DrawCoordinates]{
                            return fetchedCoordinates.sorted{$0.date! < $1.date!}
                        }
                        if sortedFetchedCoortidates.count > 0{
                            for coordinate in sortedFetchedCoortidates{
                                //print("\(coordinate.latitude) - \(coordinate.longitude)")
                                var coor = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                coordinates.append(coor)
                            }
                        }
//                        print(coordinates)
                        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                        self.mapView.addOverlay(polyline)
                    }
                }
//
            }
        }catch{
            
        }
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let routePolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.strokeColor = UIColor.red.withAlphaComponent(0.7)
            renderer.lineWidth = 13
            return renderer
        }

        return MKOverlayRenderer()
    }
    

}
