//
//  SpliceViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import Combine
import AVFoundation

protocol SpliceViewControllerDataSource: AnyObject {
  var assets: [AVAsset] { get }
  var splices: [Splice] { get set }
}

protocol SpliceViewControllerDelegate: AnyObject {
  func spliceViewControllerDidFinish(_ spliceVC: SpliceViewController)
}

enum PlaybackState {
  case initial
  case playing
  case paused
  
}
// A full-screen VC that contains the progress bar, the player, and control buttons.
class SpliceViewController: UIViewController {
  weak var dataSource: SpliceViewControllerDataSource?
  weak var delegate: SpliceViewControllerDelegate?
  
  let playerVC = PlayerViewController()
  let scrubberVC = ScrubberViewController()
  var intervals = Intervals()

  let playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.initial)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGray
    playerVC.assets = dataSource?.assets ?? []
  }
  
  
}
