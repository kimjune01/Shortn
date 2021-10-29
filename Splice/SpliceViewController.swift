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

enum SpliceMode {
  case playSplice
  case pauseSplice
  
}
// A full-screen VC that contains the progress bar, the player, and control buttons.
class SpliceViewController: UIViewController {
  weak var dataSource: SpliceViewControllerDataSource?
  weak var delegate: SpliceViewControllerDelegate?
  
  let playerVC = PlayerViewController()
  let scrubberVC = ScrubberViewController()
  var intervals = Intervals()

  let playbackStateSubject = CurrentValueSubject<SpliceMode, Never>(.pauseSplice)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGray
    addPlayerVC()
    addSpliceButton()
  }
  
  func addPlayerVC() {
    if let assets = dataSource?.assets {
      playerVC.playerItems = assets.map{AVPlayerItem(asset: $0)}
    }
    view.addSubview(playerVC.view)
    addChild(playerVC)
    playerVC.didMove(toParent: self)
    
  }
  
  func addSpliceButton() {
    let spliceButton = UIButton(type: .system)
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: "scissors.circle.fill")
    spliceButton.configuration = config
    view.addSubview(spliceButton)
    spliceButton.pinBottomToParent(margin: 25, insideSafeArea: true)
    spliceButton.centerXInParent()
    spliceButton.setSquare(constant: 47)
    spliceButton.roundCorner(radius: 47 / 2, cornerCurve: .circular)
    spliceButton.setImageScale(to: 2)
    spliceButton.tintColor = .systemBlue
    spliceButton.backgroundColor = .white
    
    spliceButton.addTarget(self, action: #selector(touchedDownSliceButton), for: .touchDown)
    spliceButton.addTarget(self, action: #selector(touchDoneSliceButton), for: .touchUpInside)
    spliceButton.addTarget(self, action: #selector(touchDoneSliceButton), for: .touchDragExit)
  }
  
  @objc func touchedDownSliceButton() {
  }
  
  @objc func touchDoneSliceButton() {
  }
  
}
