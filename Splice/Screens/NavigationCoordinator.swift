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
  }
  
  @objc func didTapNextButtonOnSpliceVC() {
    let previewVC = PreviewViewController(composition: composition)
    previewVC.delegate = self
    previewVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "square.and.arrow.up"),
      style: .done,
      target: self,
      action: #selector(previewVCTappedShare))
    
    navController.pushViewController(previewVC, animated: true)
  }
  
  @objc func previewVCTappedShare(_ barButton: UIBarButtonItem) {
    guard let assetToShare = composition.previewAsset else { return }
    let activityVC = UIActivityViewController(activityItems: [assetToShare.url], applicationActivities: nil)
    activityVC.title = "Save to album"
    activityVC.excludedActivityTypes = []
    // for ipads
    if let popover = activityVC.popoverPresentationController {
      popover.barButtonItem = barButton
      popover.permittedArrowDirections = .up
    }

    navController.present(activityVC, animated: true, completion: nil)
    
  }
  
  func showAlbumPicker() {
    var pickerConfig = PHPickerConfiguration(photoLibrary: .shared())
    pickerConfig.filter =  PHPickerFilter.any(of: [.livePhotos, .videos])
    pickerConfig.selection = .ordered
    pickerConfig.selectionLimit = 0
    pickerConfig.preselectedAssetIdentifiers = composition.assetIdentifiers
    
    let picker = PHPickerViewController(configuration: pickerConfig)
    picker.delegate = self
    self.navController.topViewController?.view.isUserInteractionEnabled = false
    navController.present(picker, animated: true) {
      self.navController.topViewController?.view.isUserInteractionEnabled = true
    }
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
  func previewVCDidApprove(_ previewVC: PreviewViewController) {
    
  }
  
  
}

extension NavigationCoordinator: SpliceViewControllerDelegate {
  func spliceVCDidRequestAlbumPicker(_ spliceVC: SpliceViewController) {
    showAlbumPicker()
  }
}

extension NavigationCoordinator: PHPickerViewControllerDelegate {
  
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    let identifiers = results.compactMap(\.assetIdentifier)
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    composition.assetIdentifiers = identifiers
    picker.dismiss(animated: true)
    navController.topViewController?.view.isUserInteractionEnabled = false
    composition.requestAVAssets(from: fetchResult) {
      self.navController.topViewController?.view.isUserInteractionEnabled = true
      self.pickerDidPick()
    }
  }
  
  func pickerDidPick() {
    guard composition.assets.count > 0 else { return }
    if let spliceVC = navController.topViewController as? SpliceViewController {
      spliceVC.composition = composition
      spliceVC.renderFreshAssets()
    } else {
      composition.splices = []
      let spliceViewController = SpliceViewController(composition: composition)
      navController.pushViewController(spliceViewController, animated: true)
    }
  }
  
}
