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
  var previewAsset: AVAsset?
  let spinner = UIActivityIndicatorView(style: .large)
  let waitLabel = UILabel()
  var micButton: UIButton!
  let bottomStack = UIStackView()
  var voiceoverVC: VoiceoverViewController!
  
  private var playbackState: AVPlayer.TimeControlStatus {
    return player.timeControlStatus
  }
  var isPlaying: Bool {
    return playbackState == .playing
  }
  
  init(composition: SpliceComposition) {
    self.composition = composition
    voiceoverVC = VoiceoverViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
    voiceoverVC.delegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    addPlayer()
    addBottonStack()
    addSpinner()
    addWaitLabel()
    addVoiceoverVC()
    if !composition.assets.isEmpty {
      exportInBackground()
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
  
  func addWaitLabel() {
    view.addSubview(waitLabel)
    waitLabel.centerXInParent()
    waitLabel.pinTop(toBottomOf: spinner, margin: 24)
    waitLabel.numberOfLines = 0
    waitLabel.textAlignment = .center
    waitLabel.font = UIFont.italicSystemFont(ofSize: 12)
    waitLabel.fillWidthOfParent(withDefaultMargin: true)
    
    waitLabel.text = "Please wait for the video to finish processing.\nThis could take a while for longer videos."
  }
  
  func addBottonStack() {
    
    view.addSubview(bottomStack)
    bottomStack.set(height: UIStackView.bottomHeight)
    bottomStack.fillWidthOfParent(withDefaultMargin: true)
    // animating anchor
    bottomStack.pinBottomToParent(margin: 24, insideSafeArea: true)
    bottomStack.distribution = .equalSpacing
    bottomStack.axis = .horizontal
    bottomStack.alignment = .center
    
    var backConfig = UIButton.Configuration.filled()
    backConfig.baseForegroundColor = .white
    backConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    backConfig.buttonSize = .large
    backConfig.image = UIImage(systemName: "chevron.left")
    backConfig.baseForegroundColor = .white
    let backButton = UIButton(configuration: backConfig, primaryAction: UIAction(){ _ in
      guard self.player != nil else { return }
      NotificationCenter.default.removeObserver(self)
      self.player.pause()
      self.delegate?.previewVCDidCancel(self)
    })
    bottomStack.addArrangedSubview(backButton)
    
    let saveButtonVC = SaveButtonViewController(composition: composition)
    addChild(saveButtonVC)
    saveButtonVC.didMove(toParent: self)
    saveButtonVC.view.set(width: 110)
    saveButtonVC.view.set(height: 47)
    bottomStack.addArrangedSubview(saveButtonVC.view)
    
    var micConfig = UIButton.Configuration.filled()
    micConfig.baseForegroundColor = .white
    micConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    micConfig.buttonSize = .large
    micConfig.image = UIImage(systemName: "mic.fill")
    micButton = UIButton(configuration: micConfig, primaryAction: UIAction(){ _ in
      self.presentVoiceoverVC()
    })
    bottomStack.addArrangedSubview(micButton)
  }
  
  func addVoiceoverVC() {
    view.addSubview(voiceoverVC.view)
    voiceoverVC.view.fillParent()
    addChild(voiceoverVC)
    voiceoverVC.didMove(toParent: self)
    voiceoverVC.view.isUserInteractionEnabled = false
  }
  
  func presentVoiceoverVC() {
    let playerView = self.playerView
    playerView.isUserInteractionEnabled = false
    player.pause()
    player.seek(to: .zero)
    UIView.animate(withDuration: voiceoverVC.transitionDuration) {
      self.bottomStack.transform = .identity.translatedBy(x: 0, y: 100)
      let scaleFactor = 0.5
      playerView.transform = .identity
        .scaledBy(x: scaleFactor, y: scaleFactor)
        .translatedBy(x: -playerView.frame.width / 2 + 8, y: -50)
    } completion: { _ in
      self.voiceoverVC.view.isUserInteractionEnabled = true
    }
    voiceoverVC.animateIn()
  }
  func presentVoiceoverVCOut() {
    voiceoverVC.view.isUserInteractionEnabled = false
    voiceoverVC.animateOut()
    let playerView = self.playerView
    UIView.animate(withDuration: voiceoverVC.transitionDuration) {
      self.bottomStack.transform = .identity
      playerView.isUserInteractionEnabled = true
      playerView.transform = .identity
    }

  }
  
  // for reference only, when making preview without instructions.
//  func makePreview() {
//    assert(false, "must export for now..")
//    bottomStack.obscure()
//    if let asset = composition.composeForPreviewAndExport() {
//      spinner.stopAnimating()
//      waitLabel.isHidden = true
//      playerView.isUserInteractionEnabled = true
//      previewAsset = asset
//      makePlayer(item: self.makePlayerItem(from: asset))
//    } else {
//      // FIXME
//      delegate?.previewVCDidFailExport(self, err: CompositorError.avFoundation)
//    }
//  }
  
  @objc func didSaveToAlbum() {
    print("didSaveToAlbum")
  }
  
  func addPlayer() {
    view.addSubview(playerView)
    playerView.backgroundColor = .black
    playerView.fillParent(withDefaultMargin: false, insideSafeArea: false)
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView))
    singleTapRecognizer.numberOfTapsRequired = 1
    playerView.addGestureRecognizer(singleTapRecognizer)
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
  
  func exportInBackground() {
    guard let asset = composition.composeForPreviewAndExport() else {
      return
    }
    playerView.isUserInteractionEnabled = false
    bottomStack.obscure()
    composition.export(asset) { error in
      guard error == nil else {
        print("error! ", error!)
        self.alertExportFail()
        return
      }
      self.previewAsset = asset
      self.makePlayer(item: self.makePlayerItem(from: asset))
      self.renderFreshAssets()
    }
  }
  
  func renderFreshAssets() {
    voiceoverVC.renderFreshAssets()
    bottomStack.clarify()
    playerView.isUserInteractionEnabled = true
    appearLoaded()
    player.play()
  }
  
  func alertExportFail() {
    let alert = UIAlertController(title: "Oops!", message: "The video could not be processed. Please try with another video. Sorry!", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
      self.dismiss(animated: true, completion: nil)
    }))
    present(alert, animated: true) {
      self.appearLoaded()
    }
  }
  
  func appearLoaded() {
    spinner.stopAnimating()
    waitLabel.isHidden = true
    playerView.isUserInteractionEnabled = true
    bottomStack.clarify()
  }
  
  @objc func didTapPlayerView() {
    togglePlayback()
  }
  
  func togglePlayback() {
    guard player != nil else {
      print("Tried to togglePlayback without a player!!!")
      return
    }
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

extension PreviewViewController: VoiceoverViewControllerDelegate {
  
  func voiceoverVCDidStartRecording() {
    player.play()
  }

  func voiceoverVCDidStopRecording() {
    player.pause()
  }

  func seekPlayer(to time: TimeInterval) {
    player.seek(to: time.cmTime)
  }
  
  func assetForThumbnail() -> AVAsset? {
    return previewAsset
  }
  
  func currentPlaybackTime() -> TimeInterval {
    return player.currentTime().seconds
  }
  
  func playerFrame() -> CGRect {
    return playerView.frame 
  }
  
  func voiceoverVCDidFinish() {
    presentVoiceoverVCOut()
    
  }
  
  func voiceoverVCDidCancel() {
    print("didCancel")
    presentVoiceoverVCOut()
  }
  
}
