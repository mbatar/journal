//
//  ViewController.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 30.11.2021.
//

import UIKit
import CoreData
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,CLLocationManagerDelegate {
   

    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var momentsTableView: UITableView!
    
    let formatter = DateFormatter()
    var fetchedMoments:[Moments]?
    var fetchedImages:[Images]?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var selectedMoment:Moments?
    let locationManager = CLLocationManager()
    let screenSize: CGRect = UIScreen.main.bounds
    var emptyImage = UIImageView()
    var mainTimer = Timer()
    var locTest = UILabel()
    var trackingStarted = false
    var drawCoordinates = [CLLocation]()
//    var prevLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var prevLocation = CLLocation(latitude: 0.0, longitude: 0.0)

    override func viewDidLoad() {
        super.viewDidLoad()
         var shouldAutorotate: Bool {
                return false
            }
        title = "Yağmur'un Defteri 🌻"
        momentsTableView.delegate = self
        momentsTableView.dataSource = self
        momentsTableView.rowHeight = 100.0
//        self.mainTimer = Timer.scheduledTimer(timeInterval: 48, target: self, selector: #selector(self.yagmurTrack), userInfo: nil, repeats: true)
        locationManager.delegate = self
            
        let addMomentButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addMomentButtonClicked))
        let startTrackButtonItem = UIBarButtonItem(title: "🤸🏿‍♀️", style: UIBarButtonItem.Style.plain, target: self, action: #selector(startTrackButtonClicked))
        navigationItem.rightBarButtonItems = [addMomentButtonItem,startTrackButtonItem]
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addPlaceButtonClicked))
        
        navigationItem.backButtonTitle = "Geri"
        emptyImage.image = UIImage(named: "emptyimage")
        emptyImage.frame = CGRect(x: screenSize.width / 4.5, y: screenSize.height / 3, width: screenSize.width / 1.8, height: screenSize.height / 4)
        view.addSubview(emptyImage)
    }

    
    func alwaysAuthorization(){
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//            guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
            var locValue = locations.last
        if locValue != nil {
            if locValue?.coordinate.latitude != self.prevLocation.coordinate.latitude && locValue?.coordinate.longitude != self.prevLocation.coordinate.longitude{
                self.drawCoordinates.append(locValue!)
                self.prevLocation = locValue!
            }
        }
       
    }
    @IBAction func mapViewButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        self.formatter.dateFormat = "dd/MM/YYYY"
        fetchMoments()
    }
    
    func fetchMoments(){
        do{
            self.fetchedMoments = try context.fetch(Moments.fetchRequest())
            DispatchQueue.main.async {
                let flCount = self.fetchedMoments!.count
                if flCount > 0 {
                    self.emptyImage.isHidden = true
                }
                self.momentsTableView.reloadData()
            }
        }catch{
            
        }
    }
    
    
    @objc func addMomentButtonClicked(){
        performSegue(withIdentifier: "toCreateMomentVC", sender: nil)
    }
    @objc func startTrackButtonClicked(){
        if self.trackingStarted == false {
            var deleteCellAlert = UIAlertController(title: "Konum Takibi", message: "Konum takibi başlatılsın mı?", preferredStyle: UIAlertController.Style.alert)

            deleteCellAlert.addAction(UIAlertAction(title: "Evet", style: .default, handler: { (action: UIAlertAction!) in
                self.locationManager.distanceFilter = kCLLocationAccuracyBest
                self.locationManager.allowsBackgroundLocationUpdates = true
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.alwaysAuthorization()
                self.locationManager.startUpdatingLocation()
                self.navigationController!.navigationBar.backgroundColor = .systemBlue.withAlphaComponent(0.2)
              }))

            deleteCellAlert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Handle Cancel Logic here")
              }))

            present(deleteCellAlert, animated: true, completion: nil)
            self.trackingStarted = true
        }else{
            var deleteCellAlert = UIAlertController(title: "Konum Takibi", message: "Konum takibi durdurulsun mu?", preferredStyle: UIAlertController.Style.alert)

            deleteCellAlert.addAction(UIAlertAction(title: "Evet", style: .default, handler: { (action: UIAlertAction!) in
                self.locationManager.stopUpdatingLocation()
                self.navigationController!.navigationBar.backgroundColor = .clear
                
                let drawsEntity = Draws(context: self.context)
                drawsEntity.id = UUID()

                var nsDrawCoordinates = [DrawCoordinates]()
                for dCoordinate in self.drawCoordinates {
                    let drawCoordinateEntity = DrawCoordinates(context: self.context)
                    drawCoordinateEntity.id = UUID()
                    drawCoordinateEntity.latitude = dCoordinate.coordinate.latitude
                    drawCoordinateEntity.longitude = dCoordinate.coordinate.longitude
                    drawCoordinateEntity.date = dCoordinate.timestamp
                    nsDrawCoordinates.append(drawCoordinateEntity)
                }
                drawsEntity.addToCoordinates(NSSet(array:nsDrawCoordinates))
                
                do{
                    try! self.context.save()
                }catch{
                    print("error")
                }
              }))

            deleteCellAlert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Handle Cancel Logic here")
              }))

            present(deleteCellAlert, animated: true, completion: nil)
            self.trackingStarted = false

        }
        
        
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") {_, _, _ in
            self.context.delete(self.fetchedMoments![indexPath.row])
            try! self.context.save()
            self.fetchedMoments?.remove(at: indexPath.row)
            DispatchQueue.main.async {
                let flCount = self.fetchedMoments!.count
                if flCount == 0 {
                    self.emptyImage.isHidden = false
                }
                self.momentsTableView.reloadData()
            }
            self.momentsTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [delete])
        return swipeConfiguration
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style:.default , reuseIdentifier: "cell")
        let fetchedImages = self.fetchedMoments![indexPath.row].images?.allObjects as! [Images]
        var randomImageIndex = 0
        let fetchedCellImage = UIImage(data: fetchedImages[0].image!)
        let cellImageView = UIImageView(image: fetchedCellImage)
        cellImageView.frame = CGRect(x:0,y:cell.frame.height - 34 ,width:80,height:80)
        cellImageView.frame.size = CGSize(width: 80, height: 80)
        cellImageView.layer.masksToBounds = true
        cellImageView.layer.cornerRadius = cellImageView.frame.width / 7.0
        cellImageView.contentMode = .scaleAspectFill
        
        cell.addSubview(cellImageView)
        let cellNameLabel = UILabel(frame: CGRect(x:95,y:cell.frame.height - 18 ,width:cell.frame.width - 60,height:20))
        cellNameLabel.font = UIFont.systemFont(ofSize: 16.0)
        cellNameLabel.text = self.fetchedMoments?[indexPath.row].name
        cell.addSubview(cellNameLabel)
        let cellDateLabel = UILabel(frame: CGRect(x:95,y:cell.frame.height + 5 ,width:cell.frame.width - 60,height:20))
        cellDateLabel.font = UIFont.systemFont(ofSize: 14.0)
        cellDateLabel.text = self.formatter.string(from: self.fetchedMoments?[indexPath.row].date ?? Date())
        cell.addSubview(cellDateLabel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedMoments?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedMoment = self.fetchedMoments?[indexPath.row]
        performSegue(withIdentifier: "toMomentDetailsVC", sender: nil)
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMomentDetailsVC" {
            let destinationVC = segue.destination as! MomentDetailsViewController
            destinationVC.fetchedMoment = self.selectedMoment!
        }else if segue.identifier == "toMapVC"{
            let destinationVC = segue.destination as! LocationsViewController
            destinationVC.fetchedMoments = self.fetchedMoments!
        }else if segue.identifier == "toEditMomentVC"{
            let destinationVC = segue.destination as! EditMomentViewController
            destinationVC.fetchedMoment = self.selectedMoment!
        }
    }

}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

