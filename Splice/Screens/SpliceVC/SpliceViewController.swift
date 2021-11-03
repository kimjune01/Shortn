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
  let timerLabel = UILabel()
  let bpmBadgeVC = BpmBadgeViewController()

  var spliceMode: SpliceMode = .pauseSplice
  var spliceStartTime: TimeInterval = 0
  var spliceState: SpliceState = .neutral {
    didSet {
      updateAppearance()
    }
  }
  var wasPlaying: Bool = false
  var subscriptions = Set<AnyCancellable>()

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
    addTimerLabel()
    addBpmVC()
    observeTimeSubject()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
  
  func addPlayerVC() {
    playerVC = LongPlayerViewController(composition: composition)
    playerVC.delegate = self
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
  
  func addTimerLabel() {
    view.addSubview(timerLabel)
    timerLabel.set(height: 20)
    timerLabel.pinTop(toBottomOf: timelineVC.view, margin: 2)
    timerLabel.pinLeadingToParent(margin: 8)
    timerLabel.textAlignment = .center
    timerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
    timerLabel.text = "0:00"
    timerLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    timerLabel.textColor = .white
    timerLabel.backgroundColor = .black.withAlphaComponent(0.2)
    timerLabel.roundCorner(radius: 3, cornerCurve: .continuous)
    timerLabel.isUserInteractionEnabled = true
    timerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedTimerLabel)))
  }
  
  func addBpmVC() {
    view.addSubview(bpmBadgeVC.view)
    addChild(bpmBadgeVC)
    bpmBadgeVC.didMove(toParent: self)
    
    bpmBadgeVC.view.set(height: BpmBadgeViewController.height)
    bpmBadgeVC.view.set(width: BpmBadgeViewController.width)
    bpmBadgeVC.view.pinTop(toBottomOf: timelineVC.view, margin: 2)
    bpmBadgeVC.view.pinTrailingToParent(margin: 8)
  }
  
  func observeTimeSubject() {
    composition.timeSubject.receive(on: DispatchQueue.main).sink { timeInterval in
      switch self.spliceState {
      case .including:
        let lower = max(0, min(self.spliceStartTime, timeInterval))
        let upper = max(0, max(self.spliceStartTime, timeInterval))
        let cumulative = self.composition.cumulativeDuration(currentRange: lower...upper)
        self.updateTimerLabel(cumulative)
      default: break
      }
    }.store(in: &self.subscriptions)
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
    self.updateTimerLabel(self.composition.splicesDuration)
    navigationItem.rightBarButtonItem?.isEnabled = composition.splices.count > 0
  }
  
  func updateTimerLabel(_ seconds: TimeInterval) {
    let intSeconds = Int(seconds.rounded())
    let minutes = (intSeconds % 3600) / 60
    let seconds = intSeconds % 60
    timerLabel.text = String(format: "%01d:%02d", minutes, seconds)
  }
  
  @objc func touchedDownSliceButton() {
    setSpliceMode()
    if !playerVC.isPlaying {
      playerVC.play()
    }
    var playbackTime = playerVC.currentPlaybackTime()
    if playerVC.atEnd() {
      playbackTime = 0
    }
    spliceState = .including(playbackTime)
    timelineVC.startExpandingSegment()
  }
  
  func setSpliceMode() {
    if !playerVC.isPlaying {
      spliceMode = .pauseSplice
    } else if playerVC.isPlaying {
      spliceMode = .playSplice
    }
    spliceStartTime = playerVC.currentPlaybackTime()
  }
  
  @objc func touchDoneSliceButton() {
    if spliceMode == .pauseSplice {
      playerVC.pause()
    }
    finishSplicing()
  }
  
  func finishSplicing() {
    switch spliceState {
    case .including(let beginTime):
      let endTime = playerVC.currentPlaybackTime()
      if endTime - beginTime <= 0.05 {
        showTooltipOnSpliceButton()
        break
      }
      composition.append(beginTime...endTime)
      spliceState = .neutral
    case .neutral:
      updateAppearance()
      return
    }
    timelineVC.stopExpandingSegment()
    timelineVC.updateSegmentsForSplices()
  }
  
  func showTooltipOnSpliceButton() {
    spliceButton.displayTooltip("Tap & Hold") {
      //
    }
  }
  
  @objc func tappedTimerLabel() {
    
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  override var shouldAutorotate: Bool { return false }
  override var prefersStatusBarHidden: Bool { return true }
}

extension SpliceViewController: LongPlayerViewControllerDelegate {
  func longPlayerVCDidFinishPlaying(_ playerVC: LongPlayerViewController) {
    finishSplicing()
  }
}

extension SpliceViewController: TimelineViewControllerDelegate {
  func currentTimeForDisplay() -> TimeInterval {
    // currentPlaybackTime is not exact when looping over
    if playerVC.atEnd() {
      return 0
    }
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
    playerVC.appearScrubbing()
  }

  func timelineVCDidTouchDoneScrubber() {
    if wasPlaying {
      playerVC.play()
    }
    playerVC.appearNotScrubbing()
  }
  
  func timelineVCDidDeleteSegment() {
    updateAppearance()
  }
}
