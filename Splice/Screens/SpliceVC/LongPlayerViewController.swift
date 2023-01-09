//
//  LongPlayerViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import AVFoundation

protocol LongPlayerViewControllerDelegate: AnyObject {
  func longPlayerVCDidChangePlaybackState(_ state: LongPlayerState)
  func longPlayerVCDidFinishPlaying(_ playerVC: LongPlayerViewController)
}

enum LongPlayerState {
  case initial
  case playing
  case paused
  case scrubbingWhenPlaying
  case scrubbingWhenPaused
  case atEnd
}

class LongPlayerViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: LongPlayerViewControllerDelegate?
  private var player: AVPlayer!
  private var currentAsset: AVAsset?
  // Key-value observing context
  private var playerItemContext = 0
  
  var state: LongPlayerState  = .initial {
    didSet {
      updateApperance()
      delegate?.longPlayerVCDidChangePlaybackState(state)
    }
  }
  
  let playerView: PlayerView = PlayerView()
  let centerPanel = UIView()

  let leftFastPanel = UIView()
  let rightFastPanel = UIView()
  let fastSeconds: TimeInterval = 5
  
  var doubleTapLeftLabel: UILabel!
  var doubleTapRightLabel: UILabel!
  
  private var playbackState: AVPlayer.TimeControlStatus {
    return player.timeControlStatus
  }
  var isPlaying: Bool {
    if player == nil { return false }
    return playbackState == .playing
  }
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addPlayerView()
    addFastPanels()
    addDoubleTapTutorial()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !composition.assets.isEmpty {
      makePlayer(item: makePlayerItem(at: 0))
    } else {
      view.isUserInteractionEnabled = false
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAssetTransformDone),
                                             name: SpliceComposition.transformDoneNotification,
                                             object: nil)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    pause()
  }
  func addPlayerView() {
    view.addSubview(playerView)
    playerView.fillParent(withDefaultMargin: false, insideSafeArea: false)
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView))
    singleTapRecognizer.numberOfTapsRequired = 1
    playerView.addGestureRecognizer(singleTapRecognizer)
    let doubleTapRecognizer = ShortTapGestureRecognizer(target: self, action: #selector(doubleTappedPlayerView))
    doubleTapRecognizer.numberOfTapsRequired = 2
    playerView.addGestureRecognizer(doubleTapRecognizer)
    singleTapRecognizer.require(toFail: doubleTapRecognizer)
  }
  
  func makePlayer(item: AVPlayerItem) {
    guard let currentAsset = currentAsset else {
      assert(!composition.assets.isEmpty)
      return
    }

    player = AVPlayer(playerItem: item)
    playerView.player = player
    if currentAsset.isPortrait {
//      playerView.videoGravity = .resizeAspect
      playerView.videoGravity = .resizeAspectFill
    } else {
      playerView.videoGravity = .resizeAspect
    }
  }
  
  func makePlayerItem(at index: Int) -> AVPlayerItem {
    assert(!composition.assets.isEmpty)
    currentAsset = composition.assets[index]
    let item = AVPlayerItem(asset: currentAsset!)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerDidFinishPlaying),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: item)
    
    return item
  }
  
  func addFastPanels() {
    // center panel goes behind left and right panels
    playerView.addSubview(centerPanel)
    
    let panelScreenPortion = view.width * 0.29
    let panelHeight = view.height * 0.7
    let marginY = (view.height - panelHeight)/4
    
    leftFastPanel.frame = CGRect(x: -panelScreenPortion, y: marginY,
                                 width: panelScreenPortion * 2,
                                 height: panelHeight)
    leftFastPanel.backgroundColor = .white.withAlphaComponent(0.2)
    leftFastPanel.layer.cornerRadius = panelScreenPortion
    leftFastPanel.layer.cornerCurve = .continuous
    leftFastPanel.alpha = 0
    playerView.addSubview(leftFastPanel)
    
    let leftFastLabel = fastLabel()
    leftFastLabel.text = "◀◀ \(Int(fastSeconds)) sec"
    leftFastLabel.center = CGPoint(x: leftFastPanel.width * 0.75, y: leftFastPanel.height / 2)
    leftFastPanel.addSubview(leftFastLabel)
    
    rightFastPanel.frame = CGRect(x: view.width - panelScreenPortion, y: marginY, width: panelScreenPortion * 2, height: panelHeight)
    rightFastPanel.backgroundColor = .white.withAlphaComponent(0.2)
    rightFastPanel.layer.cornerRadius = panelScreenPortion
    rightFastPanel.layer.cornerCurve = .continuous
    rightFastPanel.alpha = 0
    playerView.addSubview(rightFastPanel)
    
    let rightFastLabel = fastLabel()
    rightFastLabel.text = "\(Int(fastSeconds)) sec ▶▶"
    rightFastLabel.textAlignment = .right
    rightFastLabel.center = CGPoint(x: rightFastPanel.width * 0.25, y: rightFastPanel.height / 2)
    rightFastPanel.addSubview(rightFastLabel)
    
    centerPanel.frame = CGRect(x: panelScreenPortion,
                               y: marginY,
                               width: view.width - panelScreenPortion * 2,
                               height: rightFastPanel.height)
    
    let centerSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCenterPanel))
    centerPanel.addGestureRecognizer(centerSingleTapRecognizer)
  }
  
  func addDoubleTapTutorial() {
    let panelScreenPortion = view.width * 0.29

    doubleTapLeftLabel = fastLabel()
    doubleTapLeftLabel.text = "◀◀"
    doubleTapLeftLabel.textAlignment = .center
    doubleTapLeftLabel.center = CGPoint(x: 50 - panelScreenPortion, y: centerPanel.height / 2)
    doubleTapLeftLabel.isHidden = true
    centerPanel.addSubview(doubleTapLeftLabel)
    
    doubleTapRightLabel = fastLabel()
    doubleTapRightLabel.text = "▶▶"
    doubleTapRightLabel.textAlignment = .center
    doubleTapRightLabel.center = CGPoint(x: centerPanel.width + panelScreenPortion - 50, y: centerPanel.height / 2)
    doubleTapRightLabel.isHidden = true
    centerPanel.addSubview(doubleTapRightLabel)

    maybeHideDoubleTapLabels()
  }
  
  func updateApperance() {
    switch state {
    case .initial:
      break
    case .playing:
      doubleTapLeftLabel.isHidden = true
      doubleTapRightLabel.isHidden = true
    case .paused, .atEnd:
      if !Tutorial.shared.doubleTapTutorialDone {
        doubleTapLeftLabel.isHidden = false
        doubleTapRightLabel.isHidden = false
      }
    case .scrubbingWhenPaused:
      break
    case .scrubbingWhenPlaying:
      break
    }
    
  }
  
  func maybeHideDoubleTapLabels() {
    if Tutorial.shared.doubleTapTutorialDone {
      doubleTapLeftLabel.isHidden = true
      doubleTapRightLabel.isHidden = true
    }
  }
  
  func fastLabel() -> UILabel {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    label.numberOfLines = 0
    label.textColor = .white
    label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    return label
  }
  
  
  @objc func didTapPlayerView() {
    togglePlayback()
  }
  
  func togglePlayback() {
    guard let player = player else { return }
    if player.timeControlStatus == .playing {
      player.pause()
      state = .paused
    } else if player.status == .readyToPlay {
      play()
      state = .playing
    } else {
      assert(false, "OOPS")
    }
  }
  
  func renderFreshAssets() {
    handleAssetTransformDone()
  }
  
  @objc func doubleTappedPlayerView(_ recognizer: UITapGestureRecognizer) {
    let touchPortion: CGFloat = 0.3
    if recognizer.state == .recognized {
      let x = recognizer.location(in: playerView).x
      if x < playerView.width * touchPortion {
        handleDoubleTapLeft()
      } else if x > playerView.width * (1 - touchPortion) {
        handleDoubleTapRight()
      }
    }
  }
  
  func handleDoubleTapLeft() {
    Tutorial.shared.doubleTapTutorialDone = true
    maybeHideDoubleTapLabels()
    leftFastPanel.alpha = 1
    UIView.animate(withDuration: 0.5) {
      self.leftFastPanel.alpha = 0
    }
    let current = currentPlaybackTime()
    // left boundary condition
    if current < fastSeconds {
      seek(at: 0, localTime: 0)
      return
    }
    seek(to: current - fastSeconds)
  }
  
  func handleDoubleTapRight() {
    Tutorial.shared.doubleTapTutorialDone = true
    maybeHideDoubleTapLabels()
    rightFastPanel.alpha = 1
    UIView.animate(withDuration: 0.5) {
      self.rightFastPanel.alpha = 0
    }
    let current = currentPlaybackTime()
    // right boundary condition
    if current + fastSeconds >= composition.totalDuration {
      seek(at: 0, localTime: 0)
      return
    }
    seek(to: current + fastSeconds)
  }
  
  func seek(to time: TimeInterval) {
    var remainder = time
    var lastRemainder = remainder
    var rundex = 0
    var lastIndex = rundex
    // TODO: fix index out of bounds
    while remainder > 0, rundex < composition.assets.count {
      let asset = composition.assets[rundex]
      lastRemainder = remainder
      remainder -= asset.duration.seconds
      lastIndex = rundex
      rundex += 1
    }
    seek(at: lastIndex,
         localTime: lastRemainder)
    
  }
  
  private func seek(at index: Int, localTime: TimeInterval) {
    let prevIndex = currentlyPlayingIndex()
    if index == prevIndex {
      // current item
      guard let item = player.currentItem else {
        return
      }
      let target = max(0, min(item.asset.duration.seconds, localTime))
      player.seek(to: target.cmTime,
                  toleranceBefore: (0.05).cmTime,
                  toleranceAfter: 0.cmTime)
      
    } else {
      // next or previous item.
      makePlayer(item: makePlayerItem(at: index))
      player.seek(to: localTime.cmTime,
                  toleranceBefore: (0.05).cmTime,
                  toleranceAfter: (0.05).cmTime)
    }
  }
  
  func playerAtEnd() -> Bool {
    guard let currentAsset = currentAsset else {
      return false
    }

    return  currentAsset == composition.assets.last &&
    currentPlaybackTime() == currentAsset.duration.seconds
  }
  
  func play() {
    if state == .atEnd {
      seek(to: 0)
    }
    player.play()
    state = .playing
  }
  
  func pause() {
    guard player != nil else { return }
    player.pause()
    if playerAtEnd() {
      state = .atEnd
    } else {
      state = .paused
    }
  }
  
  func currentPlaybackTime() -> TimeInterval {
    guard let currentAsset = currentAsset else {
      return 0
    }

    guard let currentItemIndex = composition.assets.firstIndex(of: currentAsset)
    else { return 0 }
    var runSum: TimeInterval = 0
    for i in 0..<currentItemIndex {
      runSum += composition.assets[i].duration.seconds
    }
    return runSum + player.currentTime().seconds
  }
  
  func currentlyPlayingIndex() -> Int {
    guard let currentAsset = currentAsset else {
      return 0
    }

    if let currentItemIndex = composition.assets.firstIndex(of: currentAsset) {
      return currentItemIndex
    }
    return 0
  }
  
  @objc func tappedPlayer() {  }
  
  @objc func playerDidFinishPlaying(note: NSNotification) {
    guard let currentAsset = currentAsset else {
      return
    }
    if let currentIndex = composition.assets.firstIndex(of: currentAsset),
       currentIndex + 1 < composition.assets.count {
      makePlayer(item: makePlayerItem(at: currentIndex + 1))
      play()
    } else {
      state = .atEnd
      delegate?.longPlayerVCDidFinishPlaying(self)
    }
  }
  
  @objc func didTapCenterPanel() {
    togglePlayback()
  }
  
  func appearScrubbing(_ wasPlaying: Bool) {
    player.pause()
    if wasPlaying {
      state = .scrubbingWhenPlaying
    } else {
      state = .scrubbingWhenPaused
    }
  }
  
  func handleStoppedScrubbing() {
    state = .paused
  }
  
  @objc func handleAssetTransformDone() {
    guard !composition.assets.isEmpty else { return }
    view.isUserInteractionEnabled = true
    makePlayer(item: makePlayerItem(at: 0))
    seek(to: 0)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

