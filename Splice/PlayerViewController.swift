//
//  PlayerViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import AVFoundation

protocol PlayerViewControllerDelegate: AnyObject {

}

class PlayerViewController: UIViewController {
  weak var delegate: PlayerViewControllerDelegate?
  var playerItems: [AVPlayerItem] = []
  private var queuePlayer: AVQueuePlayer?
  // Key-value observing context
  private var playerItemContext = 0
  let requiredAssetKeys = ["playable", "hasProtectedContent"]
  
  let playerView: PlayerView = PlayerView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addPlayer()
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
    playerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView)))
    
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
  
  @objc func tappedPlayer() {
    print("tappedPlayer")
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    print("keyPath: ", keyPath)
  }
  
}

