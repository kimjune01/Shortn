//
//  PlayerViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import AVFoundation

protocol PlayerViewControllerDelegate: AnyObject {
  func playerVC(_ playerVC: PlayerViewController, didBoundaryUpdate time: TimeInterval)
}

class PlayerViewController: UIViewController {
  weak var delegate: PlayerViewControllerDelegate?
  unowned var composition: SpliceComposition
  private var player: AVPlayer!
  private var currentAsset: AVAsset!
  // Key-value observing context
  private var playerItemContext = 0
  let requiredAssetKeys = ["playable", "hasProtectedContent"]
  
  let playerView: PlayerView = PlayerView()
  let leftFastPanel = UIView()
  let rightFastPanel = UIView()
  let centerPanel = UIView()
  let fastSeconds: TimeInterval = 15
  
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
    addPlayer()
    addFastPanels()
  }
  
  func addPlayer() {
    view.addSubview(playerView)
    playerView.frame = view.bounds
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
    let panelScreenPortion = view.width * 0.27
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
    leftFastLabel.text = "◀◀ 15 sec"
    leftFastLabel.center = CGPoint(x: leftFastPanel.width * 0.75, y: leftFastPanel.height / 2)
    leftFastPanel.addSubview(leftFastLabel)
    
    rightFastPanel.frame = CGRect(x: view.width - panelScreenPortion, y: marginY, width: panelScreenPortion * 2, height: panelHeight)
    rightFastPanel.backgroundColor = .white.withAlphaComponent(0.2)
    rightFastPanel.layer.cornerRadius = panelScreenPortion
    rightFastPanel.layer.cornerCurve = .continuous
    rightFastPanel.alpha = 0
    playerView.addSubview(rightFastPanel)
    
    let rightFastLabel = fastLabel()
    rightFastLabel.text = "15 sec ▶▶"
    rightFastLabel.textAlignment = .right
    rightFastLabel.center = CGPoint(x: rightFastPanel.width * 0.25, y: rightFastPanel.height / 2)
    rightFastPanel.addSubview(rightFastLabel)
    
    centerPanel.frame = CGRect(x: panelScreenPortion,
                               y: marginY,
                               width: playerView.width - 2 * panelScreenPortion,
                               height: rightFastPanel.height)
    playerView.addSubview(centerPanel)
    let centerSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCenterPanel))
    centerPanel.addGestureRecognizer(centerSingleTapRecognizer)
  }
  
  func fastLabel() -> UILabel {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
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
      player.play()
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
    seek(to: current - fastSeconds)
  }
  
  func seek(to time: TimeInterval) {
    var remainder = time
    var lastRemainder = remainder
    var rundex = 0
    var lastIndex = rundex
    while remainder > 0 {
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
  
  func play() {
    player.play()
  }
  
  func pause() {
    player.pause()
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
  
  @objc func tappedPlayer() {
    print("tappedPlayer")
  }
  
  @objc func playerDidFinishPlaying(note: NSNotification) {
    guard let _ = note.object as? AVPlayerItem else {
      print("BOO!!!")
      return
    }
    if let currentIndex = composition.assets.firstIndex(of: currentAsset),
       currentIndex + 1 < composition.assets.count {
      makePlayer(item: makePlayerItem(at: currentIndex + 1))
      player.play()
    } else {
      
    }
  }
  
  @objc func didTapCenterPanel() {
    togglePlayback()
  }
  
}

