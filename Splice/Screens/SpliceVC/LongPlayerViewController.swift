//
//  LongPlayerViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import AVFoundation

protocol LongPlayerViewControllerDelegate: AnyObject {
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
  private var currentAsset: AVAsset!
  // Key-value observing context
  private var playerItemContext = 0
  
  var state: LongPlayerState  = .initial {
    didSet {
      updateApperance()
    }
  }
  
  let playerView: PlayerView = PlayerView()
  let centerPanel = UIView()
  let pausedOverlay = UIImageView()

  let leftFastPanel = UIView()
  let rightFastPanel = UIView()
  let fastSeconds: TimeInterval = 5
  
  var doubleTapLeftLabel: UILabel!
  var doubleTapRightLabel: UILabel!
  let doubleTapTutorialDoneKey = "kim.june.LongPlayerVC.doubleTapKey"
  
  private var playbackState: AVPlayer.TimeControlStatus {
    return player.timeControlStatus
  }
  var isPlaying: Bool {
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
    addPausedOverlay()
    addDoubleTapTutorial()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    pause()
  }
  func addPlayerView() {
    view.addSubview(playerView)
    playerView.fillParent(withDefaultMargin: false, insideSafeArea: false)
    makePlayer(item: makePlayerItem(at: 0))
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView))
    singleTapRecognizer.numberOfTapsRequired = 1
    playerView.addGestureRecognizer(singleTapRecognizer)
    let doubleTapRecognizer = ShortTapGestureRecognizer(target: self, action: #selector(doubleTappedPlayerView))
    doubleTapRecognizer.numberOfTapsRequired = 2
    playerView.addGestureRecognizer(doubleTapRecognizer)
    singleTapRecognizer.require(toFail: doubleTapRecognizer)
  }
  
  func makePlayer(item: AVPlayerItem) {
    player = AVPlayer(playerItem: item)
    playerView.player = player
    if currentAsset.isPortrait {
      playerView.videoGravity = .resizeAspectFill
    } else {
      playerView.videoGravity = .resizeAspect
    }
  }
  
  func makePlayerItem(at index: Int) -> AVPlayerItem {
    currentAsset = composition.assets[index]
    let item = AVPlayerItem(asset: currentAsset)
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
    let marginY = (view.height - panelHeight)/2
    
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
  
  func addPausedOverlay() {
    let overlayConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight, scale: .large)
    pausedOverlay.image = UIImage(systemName: "play.circle", withConfiguration: overlayConfig)
    pausedOverlay.tintColor = .white
    centerPanel.addSubview(pausedOverlay)
    pausedOverlay.centerXInParent()
    pausedOverlay.centerYInParent()
    pausedOverlay.setSquare(constant: 150)
    pausedOverlay.contentMode = .scaleAspectFit
    pausedOverlay.alpha = 0.8
  }
  
  func addDoubleTapTutorial() {
    let panelScreenPortion = view.width * 0.29

    doubleTapLeftLabel = fastLabel()
    doubleTapLeftLabel.text = "◀◀\nDouble tap"
    doubleTapLeftLabel.textAlignment = .center
    doubleTapLeftLabel.center = CGPoint(x: 50 - panelScreenPortion, y: centerPanel.height / 2)
    centerPanel.addSubview(doubleTapLeftLabel)
    
    doubleTapRightLabel = fastLabel()
    doubleTapRightLabel.text = "▶▶\nDouble tap"
    doubleTapRightLabel.textAlignment = .center
    doubleTapRightLabel.center = CGPoint(x: centerPanel.width + panelScreenPortion - 50, y: centerPanel.height / 2)
    centerPanel.addSubview(doubleTapRightLabel)

    maybeHideDoubleTapLabels()
  }
  
  func updateApperance() {
    switch state {
    case .initial:
      break
    case .playing:
      pausedOverlay.isHidden = true
      doubleTapLeftLabel.isHidden = true
      doubleTapRightLabel.isHidden = true
    case .paused, .atEnd:
      pausedOverlay.isHidden = false
      pausedOverlay.alpha = 0.8
      if !UserDefaults.standard.bool(forKey: doubleTapTutorialDoneKey) {
        doubleTapLeftLabel.isHidden = false
        doubleTapRightLabel.isHidden = false
      }
    case .scrubbingWhenPaused:
      pausedOverlay.alpha = 0.2
    case .scrubbingWhenPlaying:
      pausedOverlay.alpha = 1
    }
    
  }
  
  func maybeHideDoubleTapLabels() {
    if UserDefaults.standard.bool(forKey: doubleTapTutorialDoneKey) {
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
    if player.timeControlStatus == .playing {
      player.pause()
    } else if player.status == .readyToPlay {
      play()
    } else {
      assert(false, "OOPS")
    }
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
    UserDefaults.standard.set(true, forKey: doubleTapTutorialDoneKey)
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
    UserDefaults.standard.set(true, forKey: doubleTapTutorialDoneKey)
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
      player.seek(to: localTime.cmTime,
                  toleranceBefore: (0.05).cmTime,
                  toleranceAfter: (0.05).cmTime)
      
    } else {
      // next or previous item.
      makePlayer(item: makePlayerItem(at: index))
      player.seek(to: localTime.cmTime,
                  toleranceBefore: (0.05).cmTime,
                  toleranceAfter: (0.05).cmTime)
    }
  }
  
  func playerAtEnd() -> Bool {
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
    guard let currentItemIndex = composition.assets.firstIndex(of: currentAsset)
    else { return 0 }
    var runSum: TimeInterval = 0
    for i in 0..<currentItemIndex {
      runSum += composition.assets[i].duration.seconds
    }
    return runSum + player.currentTime().seconds
  }
  
  func currentlyPlayingIndex() -> Int {
    if let currentItemIndex = composition.assets.firstIndex(of: currentAsset) {
      return currentItemIndex
    }
    return 0
  }
  
  @objc func tappedPlayer() {  }
  
  @objc func playerDidFinishPlaying(note: NSNotification) {
    guard let _ = note.object as? AVPlayerItem else {
      print("BOO!!!")
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
    pause()
    if wasPlaying {
      state = .scrubbingWhenPlaying
    } else {
      state = .scrubbingWhenPaused
    }
  }
  
  func handleStoppedScrubbing(_ wasPlaying: Bool) {
    if wasPlaying {
      play()
      state = .playing
    } else {
      state = .paused
    }
  }
  
}

