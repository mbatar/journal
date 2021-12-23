//
//  CreateMomentViewController.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 30.11.2021.
//

import Photos
import PhotosUI
import UIKit
import CoreData
import MapKit
import CoreLocation
import ImageViewer_swift
import YPImagePicker
import AVFoundation
import AVKit
class CreateMomentViewController: UIViewController,UINavigationControllerDelegate,UITextViewDelegate, CLLocationManagerDelegate,UISearchBarDelegate,MKLocalSearchCompleterDelegate,MKMapViewDelegate, YPImagePickerDelegate {
    func imagePickerHasNoItemsInLibrary(_ picker: YPImagePicker) {
        print("noitem")
    }
    
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return true
    }
    
    @IBOutlet weak var momentImage: UIImageView!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var momentNameTextField: UITextField!
    @IBOutlet weak var momentDatePicker: UIDatePicker!
    @IBOutlet weak var momentNoteTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var images = [UIImage]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var mainTimer = Timer()
    let formatter = DateFormatter()
    var momentLatitude = 0.0
    var momentLongitude = 0.0
    let locationManager = CLLocationManager()
    var testImageArray = [String]()
    var colIndex = 0
    var themeMode = ""
    var locationSearched = false
    var mapViewInit = false
    var updatedLatitude = 0.0
    var updatedLongitude = 0.0
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    let screenSize: CGRect = UIScreen.main.bounds
    var collectionViewHeightDefault = 0.0
    var collectionViewHeightMultiLine = 0.0
    var selectedLocations = [CLLocation]()
    var picker = YPImagePicker()
//    NEWPICKER
    var selectedItems = [YPMediaItem]()

    lazy var layout = GalleryFlowLayout()
    
    lazy var collectionView:UICollectionView = {
        // Flow layout setup
        layout.scrollDirection = .horizontal
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
        self.collectionViewHeightDefault = screenSize.width / 3
        self.collectionViewHeightMultiLine = (screenSize.width / 3) * 2
        //Set title
        title = "Yeni Anı 🌈"
        switch traitCollection.userInterfaceStyle {
            case .dark:
                themeMode = "dark"
            default:
                themeMode = "light"
        }
//        self.view.backgroundColor = .systemPink
        //AUTOLOCATION
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        //Set styles to texfield etc...
        momentNoteTextView.delegate = self
        momentNoteTextView.text = "Not..."
        momentNoteTextView.autocapitalizationType = .sentences
        momentNoteTextView.layer.cornerRadius = 5
        momentNoteTextView.layer.borderWidth = 1
        momentNoteTextView.textColor = .red
        var borderColor : UIColor
        switch self.themeMode {
        case "dark":
            borderColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.5)
            momentImage.tintColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.5)
            momentNoteTextView.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.9)
            break
        default:
            borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            momentImage.tintColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            momentNoteTextView.textColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    }
        momentNoteTextView.layer.borderWidth = 0.5
        momentNoteTextView.layer.borderColor = borderColor.cgColor
        momentNoteTextView.layer.cornerRadius = 5.0
        //VIEWERmomentNoteTextView
        view.addSubview(collectionView)
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = 5.0
        collectionView.dataSource = self
        collectionView.isHidden = true
        let addPhotoButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.camera, target: self, action: #selector(addPhotoButtonClicked))
        let addLocationButtonItem = UIBarButtonItem(title: "Harita", style: UIBarButtonItem.Style.plain, target: self, action: #selector(addLocationButtonClicked))
        navigationItem.rightBarButtonItems = [addPhotoButtonItem,addLocationButtonItem]
        
        mapContainerView.layer.masksToBounds = true
        mapContainerView.layer.cornerRadius = 10
        mapContainerView.frame = CGRect(x: 0, y: screenSize.height, width:screenSize.width, height: screenSize.height - 100)
        let mapContainerSize: CGRect = mapContainerView.bounds

        mapView.delegate = self
        mapView.showsCompass = true
        mapView.frame = CGRect(x: 0, y: 0, width: mapContainerSize.width, height: mapContainerSize.height)
        searchBar.frame = CGRect(x: 8.0, y: 8.0, width: mapContainerSize.width - 16.0, height: 44.0)
        searchTableView.frame = CGRect(x: 16.0, y: 54.0, width: mapContainerSize.width - 32.0, height: 280.0)
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.layer.masksToBounds = true
        mapView.layer.cornerRadius = 10
        mapContainerView.layer.zPosition = 999999
        saveButton.isEnabled = false

//        SEARCH
        searchCompleter.delegate = self
        searchBar.delegate = self
        searchTableView?.delegate = self
        searchTableView?.dataSource = self
        searchTableView.isHidden = true
        searchTableView.layer.cornerRadius = 10
        self.mainTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(self.setButtonStatus), userInfo: nil, repeats: true)
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecogniser)
        momentImage.frame = CGRect(x: 0, y: 110.0, width: screenSize.width, height: screenSize.height / 4.0)
        momentNameTextField.frame = CGRect(x: 5, y: 110.0 + momentImage.frame.size.height + 10.0, width: screenSize.width - 10.0, height: 44)
        momentNoteTextView.frame = CGRect(x: 5, y: 110.0 + momentImage.frame.size.height + 10.0 + 44.0 + 10.0, width: screenSize.width - 10.0, height: 120.0)
        momentDatePicker.frame = CGRect(x: 5, y: 110.0 + momentImage.frame.size.height + 10.0 + 44.0 + 10.0 + momentNoteTextView.frame.size.height + 10.0, width: screenSize.width - 10.0, height: 140.0)
        saveButton.frame = CGRect(x: 5, y: screenSize.height - 120.0, width: screenSize.width - 10.0, height: 44.0)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //        IMAGEPICKER
        var config = YPImagePickerConfiguration()
                config.library.mediaType = .photo
                config.library.itemOverlayType = .grid
                config.usesFrontCamera = true
                config.shouldSaveNewPicturesToAlbum = true
                config.startOnScreen = .library
                config.screens = [.library, .photo]
                config.wordings.libraryTitle = "Gallery"
                config.hidesStatusBar = false
                config.hidesBottomBar = false
                config.maxCameraZoomFactor = 2.0
                config.library.maxNumberOfItems = 10
                config.gallery.hidesRemoveButton = false
                config.library.preselectedItems = selectedItems
                config.library.mediaType = YPlibraryMediaType.photo
                picker = YPImagePicker(configuration: config)
                picker.imagePickerDelegate = self
        var accessoryDoneButton: UIBarButtonItem!
        let accessoryToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let codeInput = UITextField()
        accessoryDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(donePressed))
        accessoryToolBar.items = [accessoryDoneButton]
        momentNameTextField.inputAccessoryView = accessoryToolBar
        momentNoteTextView.inputAccessoryView = accessoryToolBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    @objc func donePressed() {
        momentNameTextField.resignFirstResponder()
        momentNoteTextView.resignFirstResponder()
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 && self.mapViewInit == false{
                self.view.frame.origin.y -= 70
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .began { return }

        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let momentAnotation = MKPointAnnotation()
        self.updatedLatitude = touchMapCoordinate.latitude
        self.updatedLongitude = touchMapCoordinate.longitude
        
        momentAnotation.coordinate = CLLocationCoordinate2D(latitude: touchMapCoordinate.latitude,longitude: touchMapCoordinate.longitude)
                let geoCoder = CLGeocoder()
                let location = CLLocation(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude)
                var locationText = ""
                var locationDesc = ""
        geoCoder.reverseGeocodeLocation(location, completionHandler:
                    {
                        placemarks, error -> Void in

                        guard let placeMark = placemarks?.first else { return }
                        if let city = placeMark.subAdministrativeArea {
                            momentAnotation.title = city
                        }
                        if let street = placeMark.thoroughfare {
                            locationText += ", \(street)"
                            momentAnotation.title! += ", \(street)"

                        }
                      
//                        // Zip code
//                        if let zip = placeMark.isoCountryCode {
//                            print("zip" + zip)
//                            momentAnotation.subtitle! += zip
//
//                        }
//                        // Country
//                        if let country = placeMark.country {
//                            print("country" + country)
//                            momentAnotation.subtitle! += " \(country)"
//                        }
            // Location name
            if let locationName = placeMark.location {
                locationText += "\(locationName)"
            }
                })
        
        mapView.addAnnotation(momentAnotation)
        self.selectedLocations.append(location)
    }
  
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKMarkerAnnotationView else { return nil }
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
          print("calloutAccessoryControlTapped")
       }

       func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
           var annotationTitle = view.annotation!.title
           var annotationLatitude = view.annotation!.coordinate.latitude
           var annotationLongitude = view.annotation!.coordinate.longitude
           for (index,selected) in self.selectedLocations.enumerated() {
               if selected.coordinate.latitude == annotationLatitude && selected.coordinate.longitude == annotationLongitude{
                   self.selectedLocations.remove(at: index)
               }
           }
           for annotation in self.mapView.annotations {
                   if let title = annotation.title, title == annotationTitle {
                       self.mapView.removeAnnotation(annotation)
                   }
               
            }
       }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.searchTableView.isHidden = true
        }
        searchCompleter.queryFragment = searchText
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        if(self.searchTableView.isHidden == true){
            self.searchTableView.isHidden = false
        }
        searchResults = completer.results
        self.searchTableView.reloadData()
    }
    


    // This method is called when there was an error with the searchCompleter
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Error
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
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchTableView.isHidden = true
        self.searchBar.text = ""
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.momentLatitude = locValue.latitude
        self.momentLongitude = locValue.longitude
        if let location = locations.first {
            let span = MKCoordinateSpan.init(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: manager.location!.coordinate, span: span)
            if(self.locationSearched == false){
                mapView.setRegion(region, animated: true)
            }
            self.locationManager.stopUpdatingLocation()
        }
        
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: (error)")
    }
    
    @objc func setButtonStatus(){
        if self.images.count == 0 || self.momentNoteTextView.text == "Not..." || self.momentNoteTextView.text == "" || self.momentNameTextField.text == "" {
            self.saveButton.isEnabled = false
        }else{
            self.saveButton.isEnabled = true
        }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if momentNoteTextView.text == "Not..." && momentNoteTextView.isFirstResponder{
            momentNoteTextView.text = nil
            if self.themeMode == "dark"{
                momentNoteTextView.textColor = .white
            }else{
                momentNoteTextView.textColor = .black
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if momentNoteTextView.text.isEmpty || momentNoteTextView.text == ""{
            if self.themeMode == "dark"{
                momentNoteTextView.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.9)
            }else{
                momentNoteTextView.textColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            }
            momentNoteTextView.text = "Not..."
        }
    }
        
    @objc func addLocationButtonClicked(){
        UIView.transition(with: self.mapContainerView, duration: 0.5,
                          options: .curveEaseInOut,
                          animations: {
            if self.mapViewInit == false {
                self.mapContainerView.frame = CGRect(x: 0, y: self.screenSize.height - (self.screenSize.height - 100), width:self.screenSize.width, height: self.screenSize.height - 100)
                self.mapViewInit = true
            }else {
                self.mapContainerView.frame = CGRect(x: 0, y: self.screenSize.height, width:self.screenSize.width, height: self.screenSize.height - 100)
                self.mapViewInit = false
            }
        })
        self.view.bringSubviewToFront(mapContainerView)
    }
    
    @objc private func addPhotoButtonClicked(){
        
        self.picker.didFinishPicking { [unowned picker] items, cancelled in
            self.images = [UIImage]()
            for item in items {
                switch item {
                case .photo(let photo):
                    self.images.append(photo.image)
                case .video(let video):
                    print(video)
                }
            }
            DispatchQueue.main.async {
                var cvHeight = self.collectionViewHeightDefault - 10
                if items.count > 3{
                    cvHeight = self.collectionViewHeightMultiLine - 10
                }
                self.collectionView.frame = CGRect(x: 5, y: 101, width: self.screenSize.width - 10.0, height: cvHeight)
                self.momentNameTextField.frame = CGRect(x: 5, y: 110.0 + cvHeight + 10.0, width: self.screenSize.width - 10.0, height: 44)
                self.momentNoteTextView.frame = CGRect(x: 5, y: 110.0 + cvHeight + 10.0 + 44.0 + 10.0, width: self.screenSize.width - 10.0, height: 120.0)
                self.momentDatePicker.frame = CGRect(x: 5, y: 110.0 + cvHeight + 10.0 + 44.0 + 10.0 + self.momentNoteTextView.frame.size.height + 10.0, width: self.screenSize.width - 10.0, height: 140.0)
                self.collectionView.reloadData()
                self.collectionView.isHidden = false
                self.momentImage.isHidden = true
                picker.dismiss(animated: true, completion: nil)
            }
        }
                present(picker, animated: true, completion: nil)
            }
    
    
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
            
        self.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = self.formatter.string(from: momentDatePicker.date)
        let momentDate = self.formatter.date(from: dateString)
                
        // LANDS
        let momentsEntity = Moments(context: context)
        
        momentsEntity.id = UUID()
        momentsEntity.name = momentNameTextField.text
        momentsEntity.date = momentDate
        momentsEntity.note = momentNoteTextView.text
        
        //IMAGES
        var nsImages = [Images]()
        for image in images {
            let imagesEntity = Images(context: context)
            let compressedImage = image.jpegData(compressionQuality: 0.5)
            imagesEntity.id = UUID()
            imagesEntity.image = compressedImage
            nsImages.append(imagesEntity)
        }
        momentsEntity.addToImages(NSSet(array: nsImages))

        var nsLocations = [Locations]()
        
        if selectedLocations.count > 0 {
            for location in selectedLocations {
                let locationsEntity = Locations(context: context)
                locationsEntity.id = UUID()
                locationsEntity.latitude = location.coordinate.latitude
                locationsEntity.longitude = location.coordinate.longitude
                locationsEntity.name = self.momentNameTextField.text
                locationsEntity.note = self.momentNoteTextView.text
                nsLocations.append(locationsEntity)
            }
        }else{
            let locationsEntity = Locations(context: context)
            locationsEntity.id = UUID()
            locationsEntity.latitude = self.momentLatitude
            locationsEntity.longitude = self.momentLongitude
            locationsEntity.name = self.momentNameTextField.text
            locationsEntity.note = self.momentNoteTextView.text
            nsLocations.append(locationsEntity)
        }

        momentsEntity.addToLocations(NSSet(array: nsLocations))

        
        do{
            try! context.save()
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }catch{
            print("error")
        }
        
        
    }
}

extension CreateMomentViewController: UITableViewDataSource {
func numberOfSections(in tableView: UITableView) -> Int {
    return 1
}

func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
   let searchResult = searchResults[indexPath.row]
   let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "searchCell")

   cell.textLabel?.text = searchResult.title
   cell.detailTextLabel?.text = searchResult.subtitle
    cell.selectionStyle = UITableViewCell.SelectionStyle.default
    
    return cell
  }
}

extension CreateMomentViewController: UITableViewDelegate {
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
   tableView.deselectRow(at: indexPath, animated: true)
   let result = searchResults[indexPath.row]
   let searchRequest = MKLocalSearch.Request(completion: result)

   let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let coordinate = response?.mapItems[0].placemark.coordinate else {
                return
            }

       guard let name = response?.mapItems[0].name else {
             return
       }

       let lat = coordinate.latitude
       let lon = coordinate.longitude
            self.locationSearched = true
            let span = MKCoordinateSpan.init(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
            self.searchTableView.isHidden = true
     }
  }
}

extension CreateMomentViewController:UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
   
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:ThumbCell = collectionView
            .dequeueReusableCell(withReuseIdentifier: ThumbCell.reuseIdentifier,
                                 for: indexPath) as! ThumbCell
        cell.imageView.image = images[indexPath.item]
        var backColor:ImageViewerTheme
            switch self.themeMode {
            case "dark":
                backColor = .dark
            default:
                backColor = .light
        }
        
        cell.imageView.setupImageViewer(
            images: images,
            initialIndex: indexPath.row,
            options: [ImageViewerOption.theme(backColor)]
        )
        
        
        return cell
    }
}
