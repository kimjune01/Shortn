//
//  PreviewViewController.swift
//  Splice
//
//  Created by June Kim on 10/30/21.
//

import UIKit
import AVFoundation
import PhotosUI

protocol PreviewViewControllerDelegate: AnyObject {
  func previewVCDidFailExport(_ previewVC: PreviewViewController, err: Error?)
  func previewVCDidCancel(_ previewVC: PreviewViewController)
  func previewVCDidApprove(_ previewVC: PreviewViewController)
}

class PreviewViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: PreviewViewControllerDelegate?
  
  private var player: AVPlayer!
  let playerView = PlayerView()
  var currentAsset: AVAsset?
  let spinner = UIActivityIndicatorView(style: .large)
  var shareButton: UIButton!
  let bottomStack = UIStackView()
  
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
    view.backgroundColor = .systemGray
    addPlayer()
    addBottonStack()
    addSpinner()
    composition.exportForPreview { [weak self] err in
      guard let self = self else { return }
      guard err == nil else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          self.delegate?.previewVCDidFailExport(self, err: err)
        }
        return
      }
      guard let asset = self.composition.previewAsset else {
        return
      }
      self.spinner.stopAnimating()
      self.playerView.isUserInteractionEnabled = true
      self.currentAsset = asset
      self.makePlayer(item: self.makePlayerItem(from: asset))
      self.player.play()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if player != nil {
      player.play()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if player != nil {
      player.pause()
    }
  }
    
  func addSpinner() {
    view.addSubview(spinner)
    spinner.centerXInParent()
    spinner.centerYInParent()
    spinner.startAnimating()
    spinner.hidesWhenStopped = true
  }
  
  func addBottonStack() {
    let stackHeight: CGFloat = 50
    
    playerView.addSubview(bottomStack)
    bottomStack.set(height: stackHeight)
    bottomStack.fillWidthOfParent(withDefaultMargin: true)
    bottomStack.pinBottomToParent(margin: 12, insideSafeArea: true)
    bottomStack.distribution = .equalSpacing
    bottomStack.axis = .horizontal
    bottomStack.alignment = .center
    
    var backConfig = UIButton.Configuration.plain()
    backConfig.image = UIImage(systemName: "arrowshape.turn.up.backward")
    backConfig.baseForegroundColor = .white
    let backButton = UIButton(configuration: backConfig, primaryAction: UIAction(){ _ in
      NotificationCenter.default.removeObserver(self)
      self.player.pause()
      self.delegate?.previewVCDidCancel(self)
    })
    bottomStack.addArrangedSubview(backButton)
    
    let saveButtonVC = SaveButtonViewController(composition: composition)
    view.addSubview(saveButtonVC.view)
    addChild(saveButtonVC)
    saveButtonVC.didMove(toParent: self)
    saveButtonVC.view.set(width: 110)
    saveButtonVC.view.set(height: 47)
    bottomStack.addArrangedSubview(saveButtonVC.view)
    
    var shareConfig = UIButton.Configuration.plain()
    shareConfig.image = UIImage(systemName: "square.and.arrow.up")
    shareConfig.baseForegroundColor = .white
    shareButton = UIButton(configuration: shareConfig, primaryAction: UIAction(){ _ in
      if saveButtonVC.shouldSaveUninterrupted {
        saveButtonVC.incrementUsageCounterIfNeeded()
        self.showShareActivity()
      } else {
        saveButtonVC.offerPurchase()
      }
    })
    bottomStack.addArrangedSubview(shareButton)
  }
  
  @objc func didSaveToAlbum() {
    print("didSaveToAlbum")
  }
  
  func showShareActivity() {
    guard let assetToShare = composition.previewAsset else { return }
    let activityVC = UIActivityViewController(activityItems: [assetToShare.url], applicationActivities: nil)
    activityVC.title = "Save to album"
    activityVC.excludedActivityTypes = []
    // for ipads
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = bottomStack
      popover.sourceRect = shareButton.frame
      popover.permittedArrowDirections = .down
    }
    
    self.present(activityVC, animated: true, completion: nil)
  }
  
  func addPlayer() {
    view.addSubview(playerView)
    playerView.fillParent(withDefaultMargin: false, insideSafeArea: false)
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView))
    singleTapRecognizer.numberOfTapsRequired = 1
    playerView.addGestureRecognizer(singleTapRecognizer)
    playerView.isUserInteractionEnabled = false
  }
  
  func makePlayer(item: AVPlayerItem) {
    player = AVPlayer(playerItem: item)
    playerView.player = player
    if item.asset.isPortrait {
      playerView.videoGravity = .resizeAspectFill
//      playerView.videoGravity = .resizeAspect
    } else {
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
  
  override var prefersStatusBarHidden: Bool { return true }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
