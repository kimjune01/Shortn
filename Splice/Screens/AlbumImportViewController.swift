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
  func albumImportVCDidRequestAlbumPicker(_ importVC: AlbumImportViewController)
}

class AlbumImportViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: AlbumImportViewControllerDelegate?
  let contentView = UIView()
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
    view.backgroundColor = .clear
    addContentView()
    addIntroStack()
    addSpinner()
    addImportButton()
    addSecretGesture()
  }
  
  func addContentView() {
    let sideMargin: CGFloat = 30
    let verticalMargin: CGFloat = 50
    view.addSubview(contentView)
    contentView.pinLeadingToParent(margin: sideMargin)
    contentView.pinTrailingToParent(margin: sideMargin)
    contentView.pinTopToParent(margin: verticalMargin)
    contentView.pinBottomToParent(margin: verticalMargin)
    contentView.backgroundColor = .systemBackground
    contentView.roundCorner(radius: 16, cornerCurve: .continuous)
  }
  
  func addSpinner() {
    spinner.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
    spinner.hidesWhenStopped = true
    contentView.addSubview(spinner)
  }
  
  func addIntroStack() {
    let introStack = UIStackView()
    contentView.addSubview(introStack)
    introStack.axis = .vertical
    introStack.alignment = .leading
    introStack.distribution = .fillEqually
    introStack.centerXInParent()
    introStack.centerYInParent(offset: -12)
    introStack.set(height: 300)
    introStack.set(width: 280)

    introStack.addArrangedSubview(makeStepView(image: UIImage(systemName: "film"),
                                               text: "Select Videos",
                                               subtext: "in order"))
    introStack.addArrangedSubview(makeStepView(image: UIImage(systemName: "scissors.circle.fill"),
                                               text: "Tap & Hold",
                                               subtext: "to include"))
    introStack.addArrangedSubview(makeStepView(image: UIImage(named: "photos-app-icon"),
                                               text: "Preview & Save",
                                               subtext: "to share"))
  }
  
  func makeStepView(image: UIImage?, text: String, subtext: String) -> UIView {
    let stepView = UIView()
    
    let padding: CGFloat = 8
    
    let imageView = UIImageView(image: image)
    imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
    imageView.contentMode = .scaleAspectFit
    stepView.addSubview(imageView)
    
    let stepLabel = UILabel()
    stepLabel.numberOfLines = 1
    stepLabel.textAlignment = .left
    stepLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    stepLabel.text = text
    stepLabel.sizeToFit()
    stepLabel.frame = CGRect(x: imageView.maxX + padding,
                             y: 0,
                             width: stepLabel.width,
                             height: imageView.height)
    stepView.addSubview(stepLabel)
    
    let subLabel = UILabel()
    subLabel.numberOfLines = 1
    subLabel.textAlignment = .left
    subLabel.font = UIFont.systemFont(ofSize: 18, weight: .light)
    subLabel.text = subtext
    subLabel.sizeToFit()
    subLabel.frame = CGRect(x: stepLabel.maxX + padding,
                            y: 0,
                            width: subLabel.width,
                            height: imageView.height)
    stepView.addSubview(subLabel)
    
    stepView.sizeToFit()
    return stepView
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
      self.requestAlbumPicker()
    })
    var config = UIButton.Configuration.gray()
    config.title = "Let's go"
    config.image = UIImage(systemName: "photo.on.rectangle")
    config.imagePlacement = .top
    config.imagePadding = 8
    config.buttonSize = .large
    importButton.configuration = config
    contentView.addSubview(importButton)
    importButton.centerXInParent()
    importButton.pinBottomToParent(margin: 36, insideSafeArea: true)
  }

  func addSecretGesture() {
    let secretGesture = UILongPressGestureRecognizer(target: self, action: #selector(secretGestureRecognized))
    secretGesture.numberOfTouchesRequired = 2
    secretGesture.minimumPressDuration = 2.0
    contentView.addGestureRecognizer(secretGesture)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func requestAlbumPicker() {
    guard PHPhotoLibrary.authorizationStatus() != .denied else {
      askForAlbumPermission() { granted in
        if granted {
          self.requestAlbumPicker()
        }
        self.importButton.isEnabled = true
      }
      return
    }
    delegate?.albumImportVCDidRequestAlbumPicker(self)
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
        switch status {
        case .authorized:
          completion(status == .authorized)
        case .denied:
          self.showAlbumAccessAlert()
        default:
          break
        }
      }
    })
    
  }
  
  // reset state to first fresh install
  @objc func secretGestureRecognized() {
    Tutorial.shared.nuke()
    ShortnAppProduct.resetUsageCounter()
    let alert = UIAlertController(title: "Reset.", message: "Tutorial & usage counter has been reset. Enjoy!", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Nice.", style: .default, handler: { _ in
      //
    }))
    present(alert, animated: true, completion: nil)
  }
  
  override var prefersStatusBarHidden: Bool { return true }
  
}

extension AlbumImportViewController: Spinnable {
  func spin() {
    spinner.startAnimating()
  }
  
  func stopSpinning() {
    spinner.stopAnimating()
  }
}
