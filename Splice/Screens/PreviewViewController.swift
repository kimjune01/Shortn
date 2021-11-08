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
  func previewVCDidFailExport(_ previewVC: PreviewViewController)
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
  var saveButton: UIButton!
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
    composition.exportForPreview { [weak self] completed in
      guard let self = self else { return }
      guard completed else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          self.delegate?.previewVCDidFailExport(self)
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
    if self.player != nil {
      self.player.play()
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
    
    var saveConfig = UIButton.Configuration.plain()
    saveConfig.image = UIImage(named: "photos-app-icon")
    saveButton = UIButton(configuration: saveConfig, primaryAction: UIAction() { _ in
      self.saveToPhotosAlbum()
    })
    saveButton.set(width: 110)
    saveButton.set(height: 47)
    saveButton.setImageScale(to: 0.8)
    bottomStack.addArrangedSubview(saveButton)
    
    var shareConfig = UIButton.Configuration.plain()
    shareConfig.image = UIImage(systemName: "square.and.arrow.up")
    shareConfig.baseForegroundColor = .white
    shareButton = UIButton(configuration: shareConfig, primaryAction: UIAction(){ _ in
      self.showShareActivity()
    })
    bottomStack.addArrangedSubview(shareButton)
  }
  
  func saveToPhotosAlbum() {
    guard let asset = currentAsset as? AVURLAsset else { return }
    saveVideoToAlbum(asset.url) { [weak self] err in
      guard let self = self else { return }
      guard err == nil else {
        self.saveButton.isEnabled = false
        self.showSaveFailAlert()
        return
      }
      self.showAlbumNavigationAlert()
    }
  }
  
  func showSaveFailAlert() {
    let alertController = UIAlertController(title: "Oops!", message: "Could not save to album", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: ":(", style: .cancel))
    present(alertController, animated: true, completion: nil)
  }
  
  func showAlbumNavigationAlert() {
    let alertController = UIAlertController(title: "Saved to Photos Album", message: "Go to album now?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Take me", style: .default, handler: { action in
      UIApplication.shared.open(URL(string:"photos-redirect://")!)
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
      self.delegate?.previewVCDidCancel(self)
    }))
    present(alertController, animated: true, completion: nil)
  }
  
  func saveVideoToAlbum(_ outputURL: URL, _ completion: @escaping (Error?) -> ()) {
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .video, fileURL: outputURL, options: nil)
    }) { (result, error) in
      DispatchQueue.main.async {
        if let error = error {
          print(error.localizedDescription)
        }
        completion(error)
      }
    }
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
