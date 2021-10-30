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
  var playerItems: [AVPlayerItem] = []
  private var queuePlayer: AVQueuePlayer?
  // Key-value observing context
  private var playerItemContext = 0
  let requiredAssetKeys = ["playable", "hasProtectedContent"]
  
  let playerView: PlayerView = PlayerView()
  let leftFastPanel = UIView()
  let rightFastPanel = UIView()
  let fastSeconds: TimeInterval = 15
  
  var playbackState: AVPlayer.TimeControlStatus {
    guard let player = queuePlayer else { return .paused }
    return player.timeControlStatus
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addPlayer()
    addFastPanels()
  }
  
  func addPlayer() {
    guard playerItems.count > 0 else {
      print("no player items ")
      return
    }
    for eachItem in playerItems {
      eachItem.addObserver(self,
                           forKeyPath:  #keyPath(AVPlayerItem.status),
                           options: [.old, .new],
                           context: &playerItemContext)
    }
    queuePlayer = AVQueuePlayer(items: playerItems)
    view.addSubview(playerView)
    playerView.frame = view.bounds
    playerView.player = queuePlayer
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView))
    singleTapRecognizer.numberOfTapsRequired = 1
    playerView.addGestureRecognizer(singleTapRecognizer)
    let doubleTapRecognizer = ShortTapGestureRecognizer(target: self, action: #selector(doubleTappedPlayerView))
    doubleTapRecognizer.numberOfTapsRequired = 2
    playerView.addGestureRecognizer(doubleTapRecognizer)
    singleTapRecognizer.require(toFail: doubleTapRecognizer)
  }
  
  func addFastPanels() {
    let panelScreenPortion = view.width * 0.3
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
    guard let player = queuePlayer else { return }
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
    guard playerItems.count > 0 else { return }
    leftFastPanel.alpha = 1
    UIView.animate(withDuration: 0.5) {
      self.leftFastPanel.alpha = 0
    }
    let current = currentPlaybackTime()
    // left boundary condition
    if current < fastSeconds {
      play(at: 0, localTime: 0)
      return
    }
    var remainder = current - fastSeconds
    var lastRemainder = remainder
    var rundex = 0
    var lastIndex = rundex
    while remainder > 0 {
      let item = playerItems[rundex]
      lastRemainder = remainder
      remainder -= item.duration.seconds
      lastIndex = rundex
      rundex += 1
    }
    play(at: lastIndex, localTime: lastRemainder)
  }
  
  func handleDoubleTapRight() {
    rightFastPanel.alpha = 1
    UIView.animate(withDuration: 0.5) {
      self.rightFastPanel.alpha = 0
    }
  }
  
  func play(at index: Int, localTime: TimeInterval) {
    guard let player = queuePlayer else { return }
    print("play at \(index), localTime: \(localTime)")
//    player.removeAllItems()
//    player.seek(to: CMTime(seconds: currentPlaybackTime() - 15, preferredTimescale: 1))
  }
//  - (void)playAtIndex:(NSInteger)index
//  {
//    [audioPlayer removeAllItems];
//    AVPlayerItem* obj = [playerItemList objectAtIndex:index];
//    [obj seekToTime:kCMTimeZero];
//    [audioPlayer insertItem:obj afterItem:nil];
//    [audioPlayer play];
//  }
  
  func play() {
    guard let player = queuePlayer else { return }
    player.play()
  }
  
  func pause() {
    guard let player = queuePlayer else { return }
    player.pause()
  }
  
  func currentPlaybackTime() -> TimeInterval {
    guard let player = queuePlayer,
          let currentItem = player.currentItem,
          let currentItemIndex = playerItems.firstIndex(of: currentItem)
    else { return 0 }
    var runSum: TimeInterval = 0
    for i in 0..<currentItemIndex {
      runSum += playerItems[i].duration.seconds
    }
    return runSum + player.currentTime().seconds
  }
  
  @objc func tappedPlayer() {
    print("tappedPlayer")
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    print("keyPath: ", keyPath)
  }
  
}

