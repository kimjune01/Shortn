//
//  AlbumImportViewController.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import UIKit
import PhotosUI

// responsible for getting an array of videos from album

protocol AlbumImportViewControllerDelegate: AnyObject {
  func albumImportViewControllerDidPick(_ importVC: AlbumImportViewController)
}

class AlbumImportViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: AlbumImportViewControllerDelegate?
  var importButton: UIButton!
  let spinner = UIActivityIndicatorView(style: .large)
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    addSpinner()
    addIntroLabel()
    addImportButton()
  }
  
  func addSpinner() {
    spinner.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
    spinner.hidesWhenStopped = true
    view.addSubview(spinner)
  }
  
  func addIntroLabel() {
    let introLabel = UILabel()
    view.addSubview(introLabel)
    introLabel.text = "This app shortens your live photos & videos.\n\nSimply tap & hold the ✂ button to include that portion of video. \n\nPlease send feature requests to june@june.kim ♡"
    introLabel.numberOfLines = 0
    introLabel.textAlignment = .center
    introLabel.font = UIFont.systemFont(ofSize: 18, weight: .light)
    
    introLabel.centerXInParent()
    introLabel.centerYInParent(offset: -24)
    introLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85).isActive = true

  }
  
  func addPermissionButton() {
    let permissionButton = UIButton(type: .system)
    var config = UIButton.Configuration.plain()
    config.title = "Allow Access to Album"
    config.image = UIImage(systemName: "questionmark")
    permissionButton.configuration = config
  }
  
  func addImportButton() {
    importButton = UIButton(type: .roundedRect, primaryAction: UIAction() { _ in
      self.importButton.isEnabled = false
      self.showPicker()
    })
    var config = UIButton.Configuration.gray()
    config.title = "Import Videos from Album"
    config.image = UIImage(systemName: "photo.on.rectangle")
    config.imagePlacement = .top
    config.imagePadding = 8
    config.buttonSize = .large
    importButton.configuration = config
    view.addSubview(importButton)
    importButton.centerXInParent()
    importButton.pinBottomToParent(margin: 36, insideSafeArea: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func showPicker() {
    guard PHPhotoLibrary.authorizationStatus() == .authorized else {
      askForAlbumPermission() { granted in
        if granted {
          self.showPicker()
        } else {
          self.showAlbumAccessAlert()
        }
        self.importButton.isEnabled = true
      }
      return
    }
    
    var pickerConfig = PHPickerConfiguration(photoLibrary: .shared())
    pickerConfig.filter =  PHPickerFilter.any(of: [.livePhotos, .videos])
    pickerConfig.selection = .ordered
    pickerConfig.selectionLimit = 0
    
    let picker = PHPickerViewController(configuration: pickerConfig)
    picker.delegate = self
    present(picker, animated: true) {
      self.importButton.isEnabled = true
    }
  }
  
  func showAlbumAccessAlert() {
    let alert = UIAlertController(title: "Album Access", message: "Allow album access in settings to shorten videos.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "k", style: .cancel, handler: { action in
      let url = URL(string: UIApplication.openSettingsURLString + Bundle.main.bundleIdentifier!)!
      UIApplication.shared.open(url)
    }))
    self.present(alert, animated: true)
  }
  
  func askForAlbumPermission(_ completion: @escaping BoolCompletion) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: { status in
      DispatchQueue.main.async {
        completion(status == .authorized)
      }
    })
    
  }
}

extension AlbumImportViewController: PHPickerViewControllerDelegate {
  
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    let identifiers = results.compactMap(\.assetIdentifier)
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    composition.assetIdentifiers = identifiers
    picker.dismiss(animated: true)
    spinner.startAnimating()
    composition.requestAVAssets(from: fetchResult) {
      self.spinner.stopAnimating()
      self.delegate?.albumImportViewControllerDidPick(self)
    }
  }
  
  
}
