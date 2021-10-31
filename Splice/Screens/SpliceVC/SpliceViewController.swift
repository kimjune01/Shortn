//
//  SpliceViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import Combine
import AVFoundation

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
  
  var playerVC: LongPlayerViewController!
  let spliceButton = UIButton(type: .system)
  let timelineVC: TimelineViewController

  var spliceMode: SpliceMode = .pauseSplice
  var spliceState: SpliceState = .neutral {
    didSet {
      updateAppearance()
    }
  }
  var wasPlaying: Bool = false
  
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
  
  func addPlayerVC() {
    playerVC = LongPlayerViewController(composition: composition)
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
    timelineVC.view.set(height: TimelineViewController.defaultHeight)
    timelineVC.view.fillWidthOfParent(withDefaultMargin: true)
    timelineVC.view.pinBottom(toTopOf: spliceButton, margin: 8)
    addChild(timelineVC)
    timelineVC.didMove(toParent: self)
  }
  
  func updateAppearance() {
    switch spliceState {
    case .including:
      playerVC.view.isUserInteractionEnabled = false
      timelineVC.appearIncluding()
    case .neutral:
      playerVC.view.isUserInteractionEnabled = true
      timelineVC.appearNeutral()
    }
    navigationItem.rightBarButtonItem?.isEnabled = composition.splices.count > 0
  }
  
  @objc func touchedDownSliceButton() {
    setSpliceMode()
    let playbackTime = playerVC.currentPlaybackTime()
    spliceState = .including(playbackTime)
    if !playerVC.isPlaying {
      playerVC.play()
    }
    timelineVC.startExpandingSegment()
  }
  
  func setSpliceMode() {
    if !playerVC.isPlaying {
      spliceMode = .pauseSplice
    } else if playerVC.isPlaying {
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

  func displayLinkStepped() {
    composition.timeSubject.send(playerVC.currentPlaybackTime())
  }

  func sliderValueDragged(to time: TimeInterval) {
    playerVC.seek(to: time)
  }
  
  func timelineVCDidTouchDownScrubber() {
    wasPlaying = playerVC.isPlaying
    playerVC.pause()
  }

  func timelineVCDidTouchDoneScrubber() {
    if wasPlaying {
      playerVC.play()
    }
  }
  
  func timelineVCDidDeleteSegment() {
    updateAppearance()
  }
}
