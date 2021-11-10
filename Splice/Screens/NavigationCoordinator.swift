//
//  NavigationCoordinator.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import AVFoundation
import PhotosUI

class NavigationCoordinator: NSObject {
  let navController: UINavigationController
  let composition = SpliceComposition()
  override init() {
    let albumImportVC = AlbumImportViewController(composition: composition)
    let spliceVC = SpliceViewController(composition: composition)
    navController = UINavigationController(rootViewController: albumImportVC)
//    navController = UINavigationController(rootViewController: BpmConfigViewController())
//    navController = UINavigationController(rootViewController: spliceVC)
    super.init()
    albumImportVC.delegate = self
    spliceVC.delegate = self
    navController.delegate = self
    navController.interactivePopGestureRecognizer?.isEnabled = false
    navController.isNavigationBarHidden = true
    
    subscribeToPurchaseStatus()
  }
  
  func showPreviewVC() {
    let previewVC = PreviewViewController(composition: composition)
    previewVC.delegate = self
    let presenter = navController.topViewController
    presenter?.view.isUserInteractionEnabled = false
    navController.present(previewVC, animated: true) {
      presenter?.view.isUserInteractionEnabled = true
    }
  }
  
  func showAlbumPicker() {
    var pickerConfig = PHPickerConfiguration(photoLibrary: .shared())
    pickerConfig.filter =  PHPickerFilter.any(of: [.livePhotos, .videos])
    pickerConfig.selection = .ordered
    pickerConfig.selectionLimit = 0 // ShortnAppProduct.PHPickerSelectionLimit
    pickerConfig.preselectedAssetIdentifiers = composition.assetIdentifiers
    
    let picker = PHPickerViewController(configuration: pickerConfig)
    picker.delegate = self
    self.navController.topViewController?.view.isUserInteractionEnabled = false
    navController.present(picker, animated: true) {
      self.navController.topViewController?.view.isUserInteractionEnabled = true
    }
  }
  
  func subscribeToPurchaseStatus() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handlePurchaseNotification(_:)),
                                           name: .IAPHelperPurchaseNotification,
                                           object: nil)
  }
  
  @objc func handlePurchaseNotification(_ notification: Notification) {
    guard let _ = notification.object as? String  else { return }
    ShortnAppProduct.updatePHPickerSelectionLimit()
  }
}

extension NavigationCoordinator: UINavigationControllerDelegate {
  
}

extension NavigationCoordinator: AlbumImportViewControllerDelegate {
  
  func albumImportVCDidRequestAlbumPicker(_ importVC: AlbumImportViewController) {
    showAlbumPicker()
  }
  
}

extension NavigationCoordinator: PreviewViewControllerDelegate {
  func previewVCDidCancel(_ previewVC: PreviewViewController) {
    previewVC.dismiss(animated: true, completion: nil)
  }
  
  func previewVCDidFailExport(_ previewVC: PreviewViewController, err: Error?) {
    previewVC.dismiss(animated: true)
    let alertController = UIAlertController(title: "Oops!",
                                            message: "Something went wrong while processing the video. Please try again.\n\(err?.localizedDescription ?? "Unknown error")",
                                            preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    navController.present(alertController, animated: true)
    
  }
  
  func previewVCDidApprove(_ previewVC: PreviewViewController) {
    
  }
  
  
}

extension NavigationCoordinator: SpliceViewControllerDelegate {
  func spliceVCDidRequestPreview(_ spliceVC: SpliceViewController) {
    showPreviewVC()
  }
  
  func spliceVCDidRequestAlbumPicker(_ spliceVC: SpliceViewController) {
    showAlbumPicker()
  }
}

extension NavigationCoordinator: PHPickerViewControllerDelegate {
  
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

    var identifiers = results.compactMap(\.assetIdentifier)
    var fetchResult: PHFetchResult<PHAsset>
    var shouldShowPostPickAlert = false
    
    
    guard identifiers.count > 0 else {
      picker.dismiss(animated: true)
      return
    }
    
    // paywall for multiple selection
    if !ShortnAppProduct.canImportMultipleClips(),
        identifiers.count > ShortnAppProduct.freeTierPickerSelectionLimit {
      identifiers = [identifiers.first!]
      // user cannot import multiple clips anymore
      shouldShowPostPickAlert = true
    }
    fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    
    // picked nothing new
    guard composition.assetIdentifiers != identifiers else {
      picker.dismiss(animated: true)
      pickerDidPick()
      return
    }
    // appended to previous selection
    if identifiers.count > composition.assetIdentifiers.count,
       Array(identifiers.prefix(upTo: composition.assetIdentifiers.count)) == composition.assetIdentifiers {
      // nop. Do not clear splices if appending to the end of selection.
    } else {
      composition.splices = []
    }
    
        
    composition.assetIdentifiers = identifiers
    
    
    picker.dismiss(animated: true)
    navController.topViewController?.view.isUserInteractionEnabled = false
    composition.requestAVAssets(from: fetchResult) {
      self.navController.topViewController?.view.isUserInteractionEnabled = true
      self.pickerDidPick(shouldShowPostPickAlert: shouldShowPostPickAlert)
    }
  }
  
  func pickerDidPick(shouldShowPostPickAlert: Bool = false) {
    guard composition.assets.count > 0 else { return }
    if let spliceVC = navController.topViewController as? SpliceViewController {
      spliceVC.composition = composition
      spliceVC.renderFreshAssets()
    } else {
      let spliceViewController = SpliceViewController(composition: composition)
      spliceViewController.delegate = self
      if shouldShowPostPickAlert {
        showPostPickAlert() {
          self.navController.pushViewController(spliceViewController, animated: true)
        }
      } else {
        navController.pushViewController(spliceViewController, animated: true)
      }
    }
  }
  
  func showPostPickAlert(_ completion: @escaping Completion) {
    let postPickAlert = UIAlertController(title: "Free usage limit reached", message: "I hope you enjoyed using Shortn. The app won't combine clips anymore, but you can use it for shortning single clips anytime.\n\nOr, access the features with a monthly subscription.", preferredStyle: .alert)
    postPickAlert.addAction(UIAlertAction(title: "Import one clip", style: .cancel, handler: { _ in
      completion()
    }))
    postPickAlert.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { _ in
      ShortnAppProduct.showSubscriptionPurchaseAlert()
    }))
    navController.present(postPickAlert, animated: true, completion: nil)
 }
  
}
