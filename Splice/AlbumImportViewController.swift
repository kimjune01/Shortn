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
    view.backgroundColor = .white
    addSpinner()
//    addPermissionButton()
    addImportButton()
  }
  
  func addSpinner() {
    spinner.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
    spinner.hidesWhenStopped = true
    view.addSubview(spinner)
  }
  
  func addPermissionButton() {
    let permissionButton = UIButton(type: .system)
    var config = UIButton.Configuration.plain()
    config.title = "Allow Access to Album"
    config.image = UIImage(systemName: "questionmark")
    permissionButton.configuration = config
  }
  
  func addImportButton() {
    let importButton = UIButton(type: .system, primaryAction: UIAction() { _ in
      self.showPicker()
    })
    var config = UIButton.Configuration.plain()
    config.title = "Import Videos from Album"
    config.image = UIImage(systemName: "photo.on.rectangle")
    config.imagePlacement = .top
    config.imagePadding = 8
    config.buttonSize = .large
    importButton.configuration = config
    view.addSubview(importButton)
    importButton.translatesAutoresizingMaskIntoConstraints = false
    importButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    importButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func showPicker() {
    var pickerConfig = PHPickerConfiguration(photoLibrary: .shared())
    pickerConfig.filter =  PHPickerFilter.any(of: [.livePhotos, .videos])
    pickerConfig.selection = .ordered
    pickerConfig.selectionLimit = 0
    
    let picker = PHPickerViewController(configuration: pickerConfig)
    picker.delegate = self
    present(picker, animated: true) {
      //
    }
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
