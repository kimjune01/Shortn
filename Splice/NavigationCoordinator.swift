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
    let albumImportVC = AlbumImportViewController()
    navController = UINavigationController(rootViewController: albumImportVC)
    super.init()
    albumImportVC.delegate = self
    navController.delegate = self
  }
  
}

extension NavigationCoordinator: UINavigationControllerDelegate {
  
}

extension NavigationCoordinator: AlbumImportViewControllerDelegate {
  func albumImportViewController(_ importVC: AlbumImportViewController, didPick assets: [AVAsset]) {
    print("albumImportViewController didPickClips")
    let spliceViewController = SpliceViewController()
    spliceViewController.assets = assets
    spliceViewController.dataSource = self
    spliceViewController.delegate = self
    navController.pushViewController(spliceViewController, animated: true)
  }
}

extension NavigationCoordinator: SpliceViewControllerDataSource, SpliceViewControllerDelegate {
  func spliceViewControllerDidFinish(_ spliceVC: SpliceViewController) {
    // do the preview!
  }
  
  
  var assets: [AVAsset] {
    return composition.assets
  }
  
  var splices: [Splice] {
    get {
      return composition.splices
    }
    set {
      composition.splices = newValue
    }
  }
  
  
}
