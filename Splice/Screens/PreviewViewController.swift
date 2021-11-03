//
//  PreviewViewController.swift
//  Splice
//
//  Created by June Kim on 10/30/21.
//

import UIKit
import AVFoundation

protocol PreviewViewControllerDelegate: AnyObject {
  func previewVCDidApprove(_ previewVC: PreviewViewController)
}

class PreviewViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: PreviewViewControllerDelegate?
  
  private var player: AVPlayer!
  let playerView = PlayerView()
  let spinner = UIActivityIndicatorView(style: .large)
  
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
    view.backgroundColor = .black
    addSpinner()
    addPlayer()
    composition.exportForPreview {
      guard let asset = self.composition.previewAsset else {
        return
      }
      self.spinner.stopAnimating()
      self.makePlayer(item: self.makePlayerItem(from: asset))
      self.player.play()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if self.player != nil {
      self.player.play()
    }
  }
    
  func addSpinner() {
    view.addSubview(spinner)
    spinner.center = view.center
    spinner.startAnimating()
    spinner.hidesWhenStopped = true
  }
  func addPlayer() {
    view.addSubview(playerView)
    playerView.fillParent(withDefaultMargin: false, insideSafeArea: false)
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView))
    singleTapRecognizer.numberOfTapsRequired = 1
    playerView.addGestureRecognizer(singleTapRecognizer)
  }
  
  func makePlayer(item: AVPlayerItem) {
    player = AVPlayer(playerItem: item)
    playerView.player = player
    if item.asset.isPortrait {
      playerView.videoGravity = .resizeAspect
    }
  }
  
  func makePlayerItem(from asset: AVAsset) -> AVPlayerItem {
    let item = AVPlayerItem(asset: asset)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerDidFinishPlaying),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: item)
    return item
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
  
  @objc func playerDidFinishPlaying(note: NSNotification) {
    guard let _ = note.object as? AVPlayerItem else {
      return
    }
    player.seek(to: .zero)
    player.play()
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

}
