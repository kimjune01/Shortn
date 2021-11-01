//
//  NavigationCoordinator.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import AVFoundation

class NavigationCoordinator: NSObject {
  let navController: UINavigationController
  let composition = SpliceComposition()
  override init() {
    let albumImportVC = AlbumImportViewController(composition: composition)
    navController = UINavigationController(rootViewController: albumImportVC)
    super.init()
    albumImportVC.delegate = self
    navController.delegate = self
    navController.interactivePopGestureRecognizer?.isEnabled = false
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
  
  @objc func previewVCTappedShare() {
    guard let assetToShare = composition.previewAsset else { return }
    let activityViewController = UIActivityViewController(activityItems: [assetToShare.url], applicationActivities: nil)
    // so that iPads won't crash
    activityViewController.popoverPresentationController?.sourceView = navController.topViewController!.view
    navController.present(activityViewController, animated: true, completion: nil)
    
  }
  
}

extension NavigationCoordinator: UINavigationControllerDelegate {
  
}

extension NavigationCoordinator: AlbumImportViewControllerDelegate {
  func albumImportViewControllerDidPick(_ importVC: AlbumImportViewController) {
    composition.splices = []
    let spliceViewController = SpliceViewController(composition: composition)
    spliceViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Next",
      style: .plain,
      target: self,
      action: #selector(didTapNextButtonOnSpliceVC))
    spliceViewController.navigationItem.rightBarButtonItem?.isEnabled = false
    navController.pushViewController(spliceViewController, animated: true)
  }
}

extension NavigationCoordinator: PreviewViewControllerDelegate {
  func previewVCDidApprove(_ previewVC: PreviewViewController) {
    
  }
  
  
}
