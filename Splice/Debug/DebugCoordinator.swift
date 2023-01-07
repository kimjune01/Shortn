
import UIKit
import AVFoundation
import PhotosUI

class DebugCoordinator: NSObject {
  let navController: AppNavController
  var topVC: UIViewController? {
    return navController.topViewController
  }
  var composition: SpliceComposition!
  
  override init() {
    composition = SpliceComposition()
    let spliceVC = SpliceViewController(composition: composition)
    navController = AppNavController(rootViewController: spliceVC)
    super.init()
    spliceVC.delegate = self
    
    navController.delegate = self
    navController.interactivePopGestureRecognizer?.isEnabled = false
    navController.isNavigationBarHidden = true
    
    DispatchQueue.main.asyncAfter(deadline:.now() + 0.3) {
      self.navController.dismiss(animated: true)
      DispatchQueue.main.asyncAfter(deadline:.now() + 0.5) {
        self.showAlbumPicker()
      }
    }
  }
  
  func showPreviewVC() {
    let previewVC = PreviewViewController(composition: composition)
    previewVC.delegate = self
    let presenter = topVC as? Spinnable
    presenter?.spin()
    navController.pushViewController(previewVC, animated: true)
    presenter?.stopSpinning()
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

extension DebugCoordinator: UINavigationControllerDelegate {
  
}

extension DebugCoordinator: AlbumImportViewControllerDelegate {
  
  func albumImportVCDidRequestAlbumPicker(_ importVC: AlbumImportViewController) {
    // assume that importVC is presented modally
    importVC.dismiss(animated: true) {
      self.showAlbumPicker()
    }
  }
}

extension DebugCoordinator: PreviewViewControllerDelegate {
  func previewVCDidCancel(_ previewVC: PreviewViewController) {
    navController.popViewController(animated: true)
    //    previewVC.dismiss(animated: true, completion: nil)
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

extension DebugCoordinator: SpliceViewControllerDelegate {
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

extension DebugCoordinator: PHPickerViewControllerDelegate {
  
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
    handleFullFeatureFlow(identifiers)
  }
  
  func handleFullFeatureFlow(_ identifiers: [String]) {
    resetSplicesIfNeeded(identifiers)
    composition.assetIdentifiers = identifiers
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    let presenter = topVC as? Spinnable
    presenter?.spin()
    guard PHPhotoLibrary.authorizationStatus() == .authorized else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.handleFullFeatureFlow(identifiers)
      }
      return
    }
    composition.saveAssetsToTempDirectory(from: fetchResult) { success in
      guard PHPhotoLibrary.authorizationStatus() == .authorized else {
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
      composition.splices.append(0...Double(composition.totalDuration))
      spliceVC.composition = composition
      spliceVC.renderFreshAssets()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.showPreviewVC()
      }
      
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
