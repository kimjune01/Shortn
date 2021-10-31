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
  }
  
  @objc func didTapNextButtonOnSpliceVC() {
    let previewVC = PreviewViewController(composition: composition)
    previewVC.delegate = self
    navController.pushViewController(previewVC, animated: true)
  }
}

extension NavigationCoordinator: UINavigationControllerDelegate {
  
}

extension NavigationCoordinator: AlbumImportViewControllerDelegate {
  func albumImportViewControllerDidPick(_ importVC: AlbumImportViewController) {
    let spliceViewController = SpliceViewController(composition: composition)
    spliceViewController.delegate = self
    spliceViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButtonOnSpliceVC))

    navController.pushViewController(spliceViewController, animated: true)
  }
}

extension NavigationCoordinator: SpliceViewControllerDelegate {
  func spliceViewControllerDidFinish(_ spliceVC: SpliceViewController) {
    // do the preview!
  }
  
}

extension NavigationCoordinator: PreviewViewControllerDelegate {
  func previewVCDidApprove(_ previewVC: PreviewViewController) {
    
  }
  
  
}
