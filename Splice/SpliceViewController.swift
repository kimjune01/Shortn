//
//  SpliceViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import Combine
import AVFoundation

protocol SpliceViewControllerDelegate: AnyObject {
  func spliceViewControllerDidFinish(_ spliceVC: SpliceViewController)
}

enum SpliceMode {
  case playSplice
  case pauseSplice
}

enum SpliceState {
  case including(TimeInterval)
  case neutral
}

// A full-screen VC that contains the progress bar, the player, and control buttons.
class SpliceViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: SpliceViewControllerDelegate?
  
  let playerVC = PlayerViewController()
  let spliceButton = UIButton(type: .system)
  let timelineVC: TimelineViewController

  var spliceMode: SpliceMode = .pauseSplice
  var spliceState: SpliceState = .neutral {
    didSet {
      updateAppearance()
    }
  }
  
  var assets: [AVAsset] {
    return composition.assets
  }
  var splices: [Splice] {
    return composition.splices
  }
  var totalDuration: TimeInterval {
    return composition.totalDuration
  }
  
  init(composition: SpliceComposition) {
    self.composition = composition
    timelineVC = TimelineViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGray
    addPlayerVC()
    addSpliceButton()
    addTimelineVC()
  }
  
  func addPlayerVC() {
    playerVC.delegate = self
    playerVC.playerItems = assets.map({ asset in
      return AVPlayerItem(asset: asset)
    })
    view.addSubview(playerVC.view)
    addChild(playerVC)
    playerVC.didMove(toParent: self)
    
  }
  
  func addSpliceButton() {
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
  
  func addTimelineVC() {
    timelineVC.delegate = self
    view.addSubview(timelineVC.view)
    timelineVC.view.set(height: 50)
    timelineVC.view.fillWidthOfParent(withDefaultMargin: true)
    timelineVC.view.centerXInParent()
    timelineVC.view.pinBottom(toTopOf: spliceButton, margin: 8)
    addChild(timelineVC)
    timelineVC.didMove(toParent: self)
  }
  
  func updateAppearance() {
    switch spliceState {
    case .including:
      playerVC.view.isUserInteractionEnabled = false
    case .neutral:
      playerVC.view.isUserInteractionEnabled = true
    }
  }
  
  @objc func touchedDownSliceButton() {
    setSpliceMode()
    let playbackTime = playerVC.currentPlaybackTime()
    spliceState = .including(playbackTime)
    if playerVC.playbackState != .playing {
      playerVC.play()
    }
    timelineVC.startExpandingSegment()
  }
  
  func setSpliceMode() {
    if playerVC.playbackState == .paused {
      spliceMode = .pauseSplice
    } else if playerVC.playbackState == .playing {
      spliceMode = .playSplice
    }
  }
  
  @objc func touchDoneSliceButton() {
    if spliceMode == .pauseSplice {
      playerVC.pause()
    } else if spliceMode == .playSplice {
      playerVC.play()
    }
    switch spliceState {
    case .including(let beginTime):
      let endTime = playerVC.currentPlaybackTime()
      if beginTime >= endTime {
        return
      }
      composition.append(beginTime...endTime)
      spliceState = .neutral
    case .neutral:
      assert(false)
    }
    timelineVC.stopExpandingSegment()
    timelineVC.updateSegmentsForSplices()
  }
  
}

extension SpliceViewController: TimelineViewControllerDelegate {
  func currentTimeForDisplay() -> TimeInterval {
    return playerVC.currentPlaybackTime()
  }
  
}

extension SpliceViewController: PlayerViewControllerDelegate {
  func playerVC(_ playerVC: PlayerViewController, didBoundaryUpdate time: TimeInterval) {
    
  }
}
