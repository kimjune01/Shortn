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
  let navController: AppNavController
  var topVC: UIViewController? {
    return navController.topViewController
  }
  let composition = SpliceComposition()
  override init() {
//    let albumImportVC = AlbumImportViewController(composition: composition)
    let spliceVC = SpliceViewController(composition: composition)
//    navController = AppNavController(rootViewController: albumImportVC)
//    navController = AppNavController(rootViewController: BpmConfigViewController())
    navController = AppNavController(rootViewController: spliceVC)
    super.init()
//    albumImportVC.delegate = self
    spliceVC.delegate = self
    navController.delegate = self
    navController.interactivePopGestureRecognizer?.isEnabled = false
    navController.isNavigationBarHidden = true
    
    subscribeToPurchaseStatus()    
  }
  
  func showPreviewVC() {
    let previewVC = PreviewViewController(composition: composition)
    previewVC.delegate = self
    let presenter = topVC as? Spinnable
    presenter?.spin()
    navController.present(previewVC, animated: true) {
      presenter?.stopSpinning()
    }
  }
  
  func showAlbumPicker() {
    var pickerConfig = PHPickerConfiguration(photoLibrary: .shared())
    pickerConfig.filter =  PHPickerFilter.any(of: [.videos])
    pickerConfig.selection = .ordered
    pickerConfig.selectionLimit = 0 // ShortnAppProduct.PHPickerSelectionLimit
    pickerConfig.preselectedAssetIdentifiers = composition.assetIdentifiers
    
    let picker = PHPickerViewController(configuration: pickerConfig)
    picker.delegate = self
    let presenter = topVC as? Spinnable
    presenter?.spin()
    navController.present(picker, animated: true) {
      presenter?.stopSpinning()
    }
  }
  
  func subscribeToPurchaseStatus() {
//    ShortnAppProduct.resetUsageCounter()
//    ShortnAppProduct.store.restorePurchases()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handlePurchaseNotification(_:)),
                                           name: .IAPHelperPurchaseNotification,
                                           object: nil)
  }
  
  @objc func handlePurchaseNotification(_ notification: Notification) {
    guard let _ = notification.object as? String  else { return }
    ShortnAppProduct.updatePHPickerSelectionLimit()
  }
  
  func pushAnimated(_ vc: UIViewController) {
    navController.pushViewController(vc, animated: true)
  }
}

extension NavigationCoordinator: UINavigationControllerDelegate {
  
}

extension NavigationCoordinator: AlbumImportViewControllerDelegate {
  
  func albumImportVCDidRequestAlbumPicker(_ importVC: AlbumImportViewController) {
    // assume that importVC is presented modally
    importVC.dismiss(animated: true) {
      self.showAlbumPicker()
    }
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
  func presentAlbumImportVC() {
    let albumImportVC = AlbumImportViewController(composition: composition)
    albumImportVC.delegate = self
    navController.modalPresentationStyle = .overCurrentContext
    navController.present(albumImportVC, animated: true)
  }
}

extension NavigationCoordinator: PHPickerViewControllerDelegate {
  
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    let identifiers = results.compactMap(\.assetIdentifier)

    // picked nothing, or canceled.
    guard identifiers.count > 0 else {
      return
    }
    // do nothing if identifiers hasn't changed
    guard composition.assetIdentifiers != identifiers else {
      return
    }
    // full featured access
    if ShortnAppProduct.hasFullFeatureAccess() {
      handleFullFeatureFlow(identifiers)
      return
    }
    // free tier access, not yet reached limit
    if !ShortnAppProduct.hasReachedFreeUsageLimit() {
      handleFreeTierFlow(identifiers)
      return
    }
    // reached usage limit, but picked within the limit.
    if identifiers.count <= ShortnAppProduct.freeTierPickerSelectionLimit {
      handleFreeTierFlow(identifiers)
      return
    }
    // reached limit, paywall for multiple selection
    if identifiers.count > ShortnAppProduct.freeTierPickerSelectionLimit {
      handleRestrictedTierFlow(identifiers)
      return
    }
    assert(false)
  }
  
  func handleFullFeatureFlow(_ identifiers: [String]) {
    resetSplicesIfNeeded(identifiers)
    composition.assetIdentifiers = identifiers
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    let presenter = topVC as? Spinnable
    presenter?.spin()
    composition.saveAssetsToTempDirectory(from: fetchResult) { success in
      guard success else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self.handleFullFeatureFlow(identifiers)
        }
        return
      }
      assert(self.composition.assets.count > 0)
      presenter?.stopSpinning()
      self.pushOrStayOnSpliceVC()
    }
  }
  
  // identical to full feature flow for now..
  func handleFreeTierFlow(_ identifiers: [String]) {
    handleFullFeatureFlow(identifiers)
  }
  
  func handleRestrictedTierFlow(_ identifiers: [String]) {
    // user cannot import multiple clips anymore
    let oneIdentifier = [identifiers.first!]
    resetSplicesIfNeeded(identifiers)
    composition.assetIdentifiers = oneIdentifier
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: oneIdentifier, options: nil)

    let presenter = topVC as? Spinnable
    presenter?.spin()
    composition.saveAssetsToTempDirectory(from: fetchResult) { success in
      guard success else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self.handleRestrictedTierFlow(identifiers)
        }
        return
      }
      assert(self.composition.assets.count > 0)
      presenter?.stopSpinning()

      var spliceVC: SpliceViewController! = self.topVC as? SpliceViewController
      if spliceVC == nil {
        spliceVC = SpliceViewController(composition: self.composition)
        spliceVC.delegate = self
      } else {
        spliceVC.composition = self.composition
        spliceVC.renderFreshAssets()
      }
      self.showPostPickAlert() {
        if self.topVC != spliceVC {
          self.pushAnimated(spliceVC)
        }
      }
    }
  }
  
  func resetSplicesIfNeeded(_ identifiers: [String]) {
    let oldAssetsCount = composition.assetIdentifiers.count
    // appended to previous selection
    if identifiers.count > oldAssetsCount,
       Array(identifiers.prefix(upTo: oldAssetsCount)) == composition.assetIdentifiers {
      // nop. Do not clear splices if appending to the end of selection.
    } else {
      composition.splices = []
    }
  }
  
  func pushOrStayOnSpliceVC() {
    if let spliceVC = topVC as? SpliceViewController {
      spliceVC.composition = composition
      spliceVC.renderFreshAssets()
      return
    }
    let spliceViewController = SpliceViewController(composition: composition)
    spliceViewController.delegate = self
    pushAnimated(spliceViewController)
  }
  
  func showPostPickAlert(_ completion: @escaping Completion) {
    let postPickAlert = UIAlertController(title: "Free usage limit reached", message: "I hope you enjoyed using Shortn. The app won't combine clips anymore, but you can use it for shortning single clips anytime.\n\nOr, access the features with a monthly subscription.", preferredStyle: .alert)
    postPickAlert.addAction(UIAlertAction(title: "Import first clip", style: .cancel, handler: { _ in
      completion()
    }))
    postPickAlert.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { _ in
      ShortnAppProduct.showSubscriptionPurchaseAlert()
      completion()
    }))
    navController.present(postPickAlert, animated: true, completion: nil)
 }
  
}
