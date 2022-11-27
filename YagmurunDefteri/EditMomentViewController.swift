//
//  EditMomentViewController.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 30.11.2021.
//

import UIKit
import CoreData
import ImageViewer_swift
import Photos
import PhotosUI
import CoreData
import MapKit
import CoreLocation
import ImageViewer_swift
import YPImagePicker
import AVFoundation
import AVKit

class EditMomentViewController: UIViewController,UITextViewDelegate,YPImagePickerDelegate, UIGestureRecognizerDelegate {
    func imagePickerHasNoItemsInLibrary(_ picker: YPImagePicker) {
        print("noitem")
    }
    
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return true
    }
    

    @IBOutlet weak var momentNameTextField: UITextField!
    @IBOutlet weak var momentNoteTextView: UITextView!
    @IBOutlet weak var momentDatePicker: UIDatePicker!
    @IBOutlet weak var editButton: UIButton!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var mainTimer = Timer()
    let formatter = DateFormatter()
    var images = [UIImage]()
    var momentImages = [Images]()
    var convertedImages = [UIImage]()
    var momentName = ""
    var momentNote = ""
    var themeMode = ""
    var fetchedMoment = Moments()
    var collectionViewHeightDefault = 0.0
    var collectionViewHeightMultiLine = 0.0
    let screenSize: CGRect = UIScreen.main.bounds
    lazy var layout = GalleryFlowLayout()
    var picker = YPImagePicker()
//    NEWPICKER
    var selectedItems = [YPMediaItem]()
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
        //Set title
        title = "Anı Düzenle 🌈"
        switch traitCollection.userInterfaceStyle {
            case .dark:
                themeMode = "dark"
            default:
                themeMode = "light"
        }
        //VIEWER
        view.addSubview(collectionView)
        var fetchedMomentImages = self.fetchedMoment.images?.allObjects as! [Images]

        for img in fetchedMomentImages{
            let convertedImage = UIImage(data: img.image!)
            convertedImages.append(convertedImage!)
        }
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.dataSource = self
        //HIDE KEYBOARD
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        //BUTTON CONTROL
        editButton.isEnabled = false
        self.mainTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(self.setButtonStatus), userInfo: nil, repeats: true)
        //SET VALUES
        momentNameTextField.borderStyle = UITextField.BorderStyle.roundedRect
        var borderColor : UIColor
        switch self.themeMode {
        case "dark":
            borderColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 0.5)
            break
        default:
            borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    }
        
        momentNoteTextView.layer.borderWidth = 0.5
        momentNoteTextView.layer.borderColor = borderColor.cgColor
        momentNoteTextView.layer.cornerRadius = 5.0
        momentNameTextField.text = fetchedMoment.name
        momentNoteTextView.text = fetchedMoment.note
        momentNoteTextView.layer.borderWidth = 0.5
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let convertedDate = formatter.string(from: fetchedMoment.date ?? Date())
        let date = formatter.date(from:convertedDate) as! Date
        momentDatePicker.setDate(date, animated: true)
        

        var collectionViewHeight = (screenSize.width - 10) / 3
        if convertedImages.count > 3{
            collectionViewHeight *= 2
        }
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = 5
        collectionView.frame = CGRect(x: 5, y: 110.0, width: screenSize.width - 10.0, height: collectionViewHeight)
        momentNameTextField.frame = CGRect(x: 5, y: 110.0 + collectionViewHeight + 10.0, width: screenSize.width - 10.0, height: 44.0)
        momentNoteTextView.frame = CGRect(x: 5, y: 110.0 + collectionViewHeight + 10.0 + 44.0 + 10.0, width: screenSize.width - 10.0, height: 120.0)
        momentDatePicker.frame = CGRect(x: 5, y: 110.0 + collectionViewHeight + 10.0 + 44.0 + 10.0 + momentNoteTextView.frame.size.height + 10.0, width: screenSize.width - 10.0, height: 140.0)
        editButton.frame = CGRect(x: 5, y: screenSize.height - 120.0, width: screenSize.width - 10.0, height: 44.0)
        
        var accessoryDoneButton: UIBarButtonItem!
        let accessoryToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let codeInput = UITextField()
        accessoryDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(donePressed))
        accessoryToolBar.items = [accessoryDoneButton]
        momentNameTextField.inputAccessoryView = accessoryToolBar
        momentNoteTextView.inputAccessoryView = accessoryToolBar
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.camera, target: self, action: #selector(addPhotoButtonClicked))
        
        var config = YPImagePickerConfiguration()

                /* Uncomment and play around with the configuration 👨‍🔬 🚀 */

                /* Set this to true if you want to force the  library output to be a squared image. Defaults to false */
                // config.library.onlySquare = true
                /* Set this to true if you want to force the camera output to be a squared image. Defaults to true */
                // config.onlySquareImagesFromCamera = false
                /* Ex: cappedTo:1024 will make sure images from the library or the camera will be
                   resized to fit in a 1024x1024 box. Defaults to original image size. */
                // config.targetImageSize = .cappedTo(size: 1024)
                /* Choose what media types are available in the library. Defaults to `.photo` */
                config.library.mediaType = .photo
                config.library.itemOverlayType = .grid
                /* Enables selecting the front camera by default, useful for avatars. Defaults to false */
                config.usesFrontCamera = true
                /* Adds a Filter step in the photo taking process. Defaults to true */
//                config.showsFilters = false
                /* Manage filters by yourself */
                // config.filters = [YPFilter(name: "Mono", coreImageFilterName: "CIPhotoEffectMono"),
                //                   YPFilter(name: "Normal", coreImageFilterName: "")]
                // config.filters.remove(at: 1)
                // config.filters.insert(YPFilter(name: "Blur", coreImageFilterName: "CIBoxBlur"), at: 1)
                /* Enables you to opt out from saving new (or old but filtered) images to the
                   user's photo library. Defaults to true. */
                config.shouldSaveNewPicturesToAlbum = true


                /* Choose the recordingSizeLimit. If not setted, then limit is by time. */
                // config.video.recordingSizeLimit = 10000000
                /* Defines the name of the album when saving pictures in the user's photo library.
                   In general that would be your App name. Defaults to "DefaultYPImagePickerAlbumName" */
                // config.albumName = "ThisIsMyAlbum"
                /* Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
                   Default value is `.photo` */
                config.startOnScreen = .library

                /* Defines which screens are shown at launch, and their order.
                   Default value is `[.library, .photo]` */
                config.screens = [.library, .photo]

                /* Can forbid the items with very big height with this property */
                // config.library.minWidthForItem = UIScreen.main.bounds.width * 0.8
                /* Defines the time limit for recording videos.
                   Default is 30 seconds. */
                // config.video.recordingTimeLimit = 5.0
                /* Defines the time limit for videos from the library.
                   Defaults to 60 seconds. */

                /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
//                config.showsCrop = .rectangle(ratio: (16/9))

                /* Changes the crop mask color */
                // config.colors.cropOverlayColor = .green
                /* Defines the overlay view for the camera. Defaults to UIView(). */
                // let overlayView = UIView()
                // overlayView.backgroundColor = .red
                // overlayView.alpha = 0.3
                // config.overlayView = overlayView
                /* Customize wordings */
        
                config.wordings.libraryTitle = "Gallery"

                /* Defines if the status bar should be hidden when showing the picker. Default is true */
                config.hidesStatusBar = true

                /* Defines if the bottom bar should be hidden when showing the picker. Default is false */
                config.hidesBottomBar = false

                config.maxCameraZoomFactor = 2.0

                config.library.maxNumberOfItems = 10
                config.gallery.hidesRemoveButton = false

                /* Disable scroll to change between mode */
                // config.isScrollToChangeModesEnabled = false
                // config.library.minNumberOfItems = 2
                /* Skip selection gallery after multiple selections */
                // config.library.skipSelectionsGallery = true
                /* Here we use a per picker configuration. Configuration is always shared.
                   That means than when you create one picker with configuration, than you can create other picker with just
                   let picker = YPImagePicker() and the configuration will be the same as the first picker. */

                /* Only show library pictures from the last 3 days */
                //let threDaysTimeInterval: TimeInterval = 3 * 60 * 60 * 24
                //let fromDate = Date().addingTimeInterval(-threDaysTimeInterval)
                //let toDate = Date()
                //let options = PHFetchOptions()
                // options.predicate = NSPredicate(format: "creationDate > %@ && creationDate < %@", fromDate as CVarArg, toDate as CVarArg)
                //
                ////Just a way to set order
                //let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
                //options.sortDescriptors = [sortDescriptor]
                //
                //config.library.options = options
                config.library.preselectedItems = selectedItems
                config.library.mediaType = YPlibraryMediaType.photo
                

                // Customise fonts
                //config.fonts.menuItemFont = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
                //config.fonts.pickerTitleFont = UIFont.systemFont(ofSize: 22.0, weight: .black)
                //config.fonts.rightBarButtonFont = UIFont.systemFont(ofSize: 22.0, weight: .bold)
                //config.fonts.navigationBarTitleFont = UIFont.systemFont(ofSize: 22.0, weight: .heavy)
                //config.fonts.leftBarButtonFont = UIFont.systemFont(ofSize: 22.0, weight: .heavy)
                picker = YPImagePicker(configuration: config)
                
                picker.imagePickerDelegate = self

                /* Change configuration directly */
                // YPImagePickerConfiguration.shared.wordings.libraryTitle = "Gallery2"
                /* Multiple media implementation */
        
        let longPressedGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        longPressedGesture.minimumPressDuration = 0.5
        longPressedGesture.delegate = self
        longPressedGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressedGesture)

    }
    
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if (gestureRecognizer.state != .began) {
            return
        }

        let p = gestureRecognizer.location(in: collectionView)

        if let indexPath = collectionView.indexPathForItem(at: p) {
            var deleteCellAlert = UIAlertController(title: "Fotoğraf Sil", message: "Silmek istediğinize emin misiniz?", preferredStyle: UIAlertController.Style.alert)

            deleteCellAlert.addAction(UIAlertAction(title: "Evet", style: .default, handler: { (action: UIAlertAction!) in
                self.convertedImages.remove(at: indexPath.row)
                self.collectionView.reloadData()
              }))

            deleteCellAlert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Handle Cancel Logic here")
              }))

            present(deleteCellAlert, animated: true, completion: nil)
            
        }
    }
    
    @objc private func addPhotoButtonClicked(){
       
        print(self.convertedImages)
        self.picker.didFinishPicking { [unowned picker] items, cancelled in
            self.images = [UIImage]()
            for item in items {
                switch item {
                case .photo(let photo):
                    self.convertedImages.append(photo.image)
                case .video(let video):
                    print(video)
                }
            }
            DispatchQueue.main.async {
                /*var cvHeight = self.collectionViewHeightDefault - 10
                if items.count > 3{
                    cvHeight = self.collectionViewHeightMultiLine - 10
                }
//                self.collectionView.frame = CGRect(x: 5, y: 101, width: self.screenSize.width - 10.0, height: cvHeight)
                self.momentNameTextField.frame = CGRect(x: 5, y: 110.0 + cvHeight + 10.0, width: self.screenSize.width - 10.0, height: 44)
                self.momentNoteTextView.frame = CGRect(x: 5, y: 110.0 + cvHeight + 10.0 + 44.0 + 10.0, width: self.screenSize.width - 10.0, height: 120.0)
                self.momentDatePicker.frame = CGRect(x: 5, y: 110.0 + cvHeight + 10.0 + 44.0 + 10.0 + self.momentNoteTextView.frame.size.height + 10.0, width: self.screenSize.width - 10.0, height: 140.0)*/
                self.collectionView.reloadData()
//                self.collectionView.isHidden = false
                //self.momentImage.isHidden = true
                picker.dismiss(animated: true, completion: nil)
            }
        }

                present(picker, animated: true, completion: nil)
            }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= 70
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    @objc func donePressed() {
        momentNameTextField.resignFirstResponder()
        momentNoteTextView.resignFirstResponder()
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
    
    @objc func setButtonStatus(){
        if self.momentNoteTextView.text == "Note..." || self.momentNoteTextView.text == "" || self.momentNameTextField.text == "" {
            self.editButton.isEnabled = false
        }else{
            self.editButton.isEnabled = true
        }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if momentNoteTextView.text == "Note..." && momentNoteTextView.isFirstResponder{
            momentNoteTextView.text = nil
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if momentNoteTextView.text.isEmpty || momentNoteTextView.text == ""{
            momentNoteTextView.textColor = .lightGray
            momentNoteTextView.text = "Note..."
        }
    }
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    

    @IBAction func editButtonClicked(_ sender: Any) {
        fetchedMoment.name = momentNameTextField.text
        fetchedMoment.note = momentNoteTextView.text
        fetchedMoment.date = momentDatePicker.date
        var nsImages = [Images]()
        for image in convertedImages {
            let imagesEntity = Images(context: context)
            let compressedImage = image.jpegData(compressionQuality: 0.5)
            imagesEntity.id = UUID()
            imagesEntity.image = compressedImage
            nsImages.append(imagesEntity)
        }
        fetchedMoment.images = NSSet(array: nsImages)
        
        
        do {
            try context.save()
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        catch {
            // Handle Error
        }
    }
}

extension EditMomentViewController:UICollectionViewDataSource {
    
    
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
        cell.imageView.setupImageViewer(
            images: convertedImages,
            initialIndex: indexPath.item,
            options: [ImageViewerOption.theme(backColor)]
        )
        
        return cell
    }

    
}
