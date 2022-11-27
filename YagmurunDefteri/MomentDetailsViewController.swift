//
//  MomentDetailsViewController.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 30.11.2021.
//

import UIKit
import MapKit
import CoreData
import ImageViewer_swift



class MomentDetailsViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var momentNameLabel: UILabel!
    @IBOutlet weak var momentNoteTextView: UITextView!
    @IBOutlet weak var momentMap: MKMapView!
    
    let formatter = DateFormatter()
    var momentName = ""
    var momentNote = ""
    var momentDate = ""
    var fetchedMoment:Moments!
    var momentLatitude = Double()
    var momentLongitude = Double()
    var locations:[Locations] = []
    var momentImages:[Images] = []
    var convertedImages:[UIImage] = []
    var themeMode = ""
    let screenSize: CGRect = UIScreen.main.bounds

    lazy var layout = GalleryFlowLayout()
    lazy var collectionView:UICollectionView = {
        // Flow layout setup
        let cv = UICollectionView(
            frame: .zero, collectionViewLayout: layout)
        cv.register(
            ThumbCell.self,
            forCellWithReuseIdentifier: ThumbCell.reuseIdentifier)
        cv.dataSource = self
        return cv
       }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        switch traitCollection.userInterfaceStyle {
            case .dark:
                themeMode = "dark"
            default:
                themeMode = "light"
        }
        
        var borderColor : UIColor
        switch self.themeMode {
        case "dark":
            borderColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.5)
            break
        default:
            borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    }
        momentNoteTextView.backgroundColor = .clear
        momentNoteTextView.layer.cornerRadius = 5.0
        formatter.dateFormat = "dd/MM/YYYY"
        momentDate = formatter.string(from: fetchedMoment.date ?? Date())
        momentName = fetchedMoment.name ?? ""
        momentNote = fetchedMoment.note ?? ""
        locations = fetchedMoment.locations?.allObjects as! [Locations]
        momentImages = fetchedMoment.images?.allObjects as! [Images]
        title = momentDate
        momentNameLabel.text = momentName
        momentNoteTextView.text = momentNote
        momentMap.delegate = self
        let images = fetchedMoment.images?.allObjects as! [Images]
        for location in locations{
            let momentAnotation = ImageAnnotation()
            momentAnotation.title = momentName
            momentAnotation.subtitle = momentNote
            momentAnotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude,longitude: location.longitude)
            momentAnotation.image = UIImage(data: (images.first?.image)!,scale: UIScreen.main.scale)
            momentMap.addAnnotation(momentAnotation)
        }
        
        
        for img in momentImages{
            let convertedImage = UIImage(data: img.image!)
            convertedImages.append(convertedImage!)
        }
        var collectionViewHeight = (screenSize.width - 10) / 3
        if convertedImages.count > 3{
            collectionViewHeight *= 2
        }
        let initMomentAnnotation = CLLocationCoordinate2D(latitude: locations[0].latitude,longitude: locations[0].longitude)
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = 5
        momentMap.layer.masksToBounds = true
        momentMap.layer.cornerRadius = 5
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.frame = CGRect(x: 5, y: 110, width: screenSize.width - 10.0, height: collectionViewHeight)
        view.addSubview(collectionView)
        let coordinateRegion = MKCoordinateRegion(center: initMomentAnnotation, latitudinalMeters: 400000, longitudinalMeters: 400000)
        momentNoteTextView.frame = CGRect(x: 5, y: screenSize.height - 220.0, width: screenSize.width - 10.0, height: 180.0)
        momentMap.frame = CGRect(x: 5, y: 110.0 + collectionViewHeight + 10.0, width: screenSize.width - 10.0, height: self.view.frame.height - (110.0 + collectionViewHeight + 180.0 + 60.0))
        momentMap.setRegion(coordinateRegion, animated: true)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.compose, target: self, action: #selector(editMomentButtonClicked))
        
    }
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    @objc func editMomentButtonClicked(){
        performSegue(withIdentifier: "toEditMomentVC", sender: nil)

    }
    
    override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            updateLayout(view.frame.size)
    }
    
    private func updateLayout(_ size:CGSize) {
            if size.width > size.height {
                layout.columns = 4
            } else {
                layout.columns = 3
            }
        }
    
    override func viewWillTransition(
            to size: CGSize,
            with coordinator: UIViewControllerTransitionCoordinator) {
            updateLayout(size)
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toEditMomentVC"{
                var destinationVC = segue.destination as! EditMomentViewController
                print(self.fetchedMoment)
                destinationVC.fetchedMoment = self.fetchedMoment
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

}

extension MomentDetailsViewController:UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        return convertedImages.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:ThumbCell = collectionView
            .dequeueReusableCell(withReuseIdentifier: ThumbCell.reuseIdentifier,
                                 for: indexPath) as! ThumbCell
        cell.imageView.image = convertedImages[indexPath.item]
            var backColor:ImageViewerTheme
                switch self.themeMode {
                case "dark":
                    backColor = .dark
                default:
                    backColor = .light
            }
        // Setup Image Viewer with [UIImage]
            cell.imageView.layer.masksToBounds = true
            cell.imageView.layer.cornerRadius = 10
        cell.imageView.setupImageViewer(
            images: convertedImages,
            initialIndex: indexPath.item,
            options: [ImageViewerOption.theme(backColor)]
        )
        
        return cell
    }
}
