//
//  SaveButtonViewController.swift
//  Shortn
//
//  Created by June Kim on 11/10/21.
//

import UIKit
import AVFoundation
import PhotosUI

class SaveButtonViewController: UIViewController {
  var saveButton: UIButton!
  unowned var composition: SpliceComposition

  var savedThisPreview = false
  var shouldSaveUninterrupted: Bool {
    return true
    // disable paywall until there's at least one happy user...
    return composition.assets.count == 1 ||
    ShortnAppProduct.hasFullFeatureAccess() ||
    !ShortnAppProduct.hasReachedFreeUsageLimit()
  }
  
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var saveConfig = UIButton.Configuration.plain()
    saveConfig.image = UIImage(named: "photos-app-icon")
    saveButton = UIButton(configuration: saveConfig, primaryAction: UIAction() { _ in
      if self.shouldSaveUninterrupted {
        self.saveToPhotosAlbum()
      } else {
        self.offerPurchase()
      }
    })
    view.addSubview(saveButton)
    saveButton.fillParent()
    saveButton.setImageScale(to: 0.8)
  }
  
  func saveToPhotosAlbum() {
    guard let asset = composition.exportAsset else { return }
    saveVideoToAlbum(asset.url) { [weak self] err in
      guard let self = self else { return }
      guard err == nil else {
        self.saveButton.isEnabled = false
        self.showSaveFailAlert()
        return
      }
      self.incrementUsageCounterIfNeeded()
      self.showPostSaveAlert()
    }
  }
  
  func showAlreadySavedAlert() {
    let alreadySavedAlert = UIAlertController(title: "Already Saved", message: "Looks like you already saved this one.", preferredStyle: .alert)
    alreadySavedAlert.addAction(UIAlertAction(title: "Go to Photos", style: .default, handler: { action in
      UIApplication.shared.open(URL(string:"photos-redirect://")!)
    }))
    alreadySavedAlert.addAction(UIAlertAction(title: "Stay here", style: .cancel, handler: { action in
      //
    }))
    present(alreadySavedAlert, animated: true)
  }
  
  func showPostSaveAlert() {
    if ShortnAppProduct.hasFullFeatureAccess() ||
        composition.assets.count <= 1 {
      self.showAlbumNavigationAlert()
    } else if ShortnAppProduct.shouldShowFreeForNowReminder() {
      savedThisPreview = true
      let plural = ShortnAppProduct.usageRemaining > 1
      let freeForNowAlert = UIAlertController(
        title: "Thanks for trying Shortn!",
        message: "Your video is now saved to photos.\n\nCombining multiple clips is a paid feature, but you can use it \(String(ShortnAppProduct.usageRemaining)) more time\(plural ? "s" : "").\n\nGet the full version for 1 month free. Cancel any time.",
        preferredStyle: .alert)
      freeForNowAlert.addAction(UIAlertAction(title: "Go to Photos", style: .default, handler: { action in
        UIApplication.shared.open(URL(string:"photos-redirect://")!)
      }))
      freeForNowAlert.addAction(purchaseAlertAction())
      present(freeForNowAlert, animated: true, completion: nil)
    } else {
      self.showAlbumNavigationAlert()
    }
  }
  
  func purchaseAlertAction() -> UIAlertAction {
    return UIAlertAction(title: "Try it free", style: .default, handler: { _ in
      ShortnAppProduct.showSubscriptionPurchaseAlert(){ error in
        if error != nil {
          self.showPurchaseFailureAlert()
        }
      }
    })
  }
  
  func offerPurchase() {
    let notFreeAlert = UIAlertController(
      title: "Thanks for trying Shortn!",
      message: "Combining multiple clips is a paid feature.\n\nGet the full version for 1 month free. Cancel any time.",  
      preferredStyle: .alert)
    notFreeAlert.addAction(UIAlertAction(title: "No thanks", style: .default, handler: { action in
      //
    }))
    notFreeAlert.addAction(purchaseAlertAction())
    present(notFreeAlert, animated: true, completion: nil)
  }
  
  func incrementUsageCounterIfNeeded() {
    if !savedThisPreview {
      ShortnAppProduct.incrementUsageCounter()
    }
    savedThisPreview = true
  }
  
  func showPurchaseFailureAlert() {
    let purchaseFailAlert = UIAlertController(title: "Purchase failed", message: "Oops! Cannot purchase at this time. Please try again later, with an internet connection", preferredStyle: .alert)
    purchaseFailAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
    present(purchaseFailAlert, animated: true, completion: nil)
  }
  
  func showSaveFailAlert() {
    let alertController = UIAlertController(title: "Oops!", message: "Could not save to album", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: ":(", style: .cancel))
    present(alertController, animated: true, completion: nil)
  }
  
  func showAlbumNavigationAlert() {
    let alertController = UIAlertController(title: "Saved to Photos", message: "Go to the Photos app now?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Go to Photos", style: .default, handler: { action in
      UIApplication.shared.open(URL(string:"photos-redirect://")!)
    }))
    alertController.addAction(UIAlertAction(title: "Stay here", style: .cancel, handler: { action in
      //
    }))
    present(alertController, animated: true, completion: nil)
  }
  
  func saveVideoToAlbum(_ outputURL: URL, _ completion: @escaping (Error?) -> ()) {
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .video, fileURL: outputURL, options: nil)
    }) { (result, error) in
      DispatchQueue.main.async {
        if let error = error {
          print(error.localizedDescription)
        }
        completion(error)
      }
    }
  }
  
}
