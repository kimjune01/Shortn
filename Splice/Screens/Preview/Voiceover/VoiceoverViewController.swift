//
//  VoiceoverViewController.swift
//  Shortn
//
//  Created by June Kim on 11/26/21.
//

import UIKit
import AVFoundation

protocol VoiceoverViewControllerDelegate: AnyObject {
  func voiceoverVCDidCancel()
  func voiceoverVCDidFinish(success: Bool)
}

enum VoiceoverState: Int, CaseIterable, CustomDebugStringConvertible {
  case initial
  case recording
  case playback
  case paused
  case standby // at the tip
  case selecting // always select the last voice segment if selecting
  case complete
  
  var debugDescription: String {
    switch self {
    case .initial: return "initial"
    case .recording: return "recording"
    case .playback: return "playback"
    case .paused: return "paused"
    case .standby: return "standby"
    case .complete: return "complete"
    case .selecting: return "selecting"
    }
  }
}

class VoiceoverViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: VoiceoverViewControllerDelegate?
  var state: VoiceoverState = .initial {
    didSet {
      UIView.animate(withDuration: 0.2) {
        self.updateAppearance()
      }
    }
  }
  let playerView = PlayerView()
  private var player: AVPlayer!
  var voiceRecorder: VoiceRecorder
  let transitionDuration: TimeInterval = 0.3
  let bottomStack = UIStackView()
  let topBar = UIView()
  var micButton: UIButton!
  var undoButton: UIButton!
  var rewindButton: UIButton!
  var confirmButton: UIButton!
  var lookAheadThumbnail = UIImageView()
  let debugButton = UIButton()
  var segmentsVC: VoiceSegmentsViewController!
  var recordingStartTime: TimeInterval = 0
  var loopTimer: Timer?
  var lookAheadTimer: Timer!
  let currentLabel = UILabel()
  let futureLabel = UILabel()
  
  let trashPopoverVC = PopoverMenuViewController(views: [.trashButton])
  let tutorialPopoverVC = PopoverMenuViewController(views: [.tutorial("Tap & hold to record")])

  init(composition: SpliceComposition) {
    self.composition = composition
    self.segmentsVC = VoiceSegmentsViewController(composition: composition)
    self.voiceRecorder = VoiceRecorder(composition: composition)
    super.init(nibName: nil, bundle: nil)
    self.voiceRecorder.delegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    addPlayerView()
    addBottomStack()
    addTopBar()
    addLookAheadThumbnail()
    addCurrentLabel()
    addFutureLabel()
    addSegmentsVC()
    makeTrashPopoverVC()
    makeTutorialPopoverVC()

    renderFreshAssets()
    addDebugButton()
  }
  
//  UIView.animate(withDuration: voiceoverVC.transitionDuration) {
//    self.bottomStack.transform = .identity.translatedBy(x: 0, y: 100)
//    let scaleFactor = 0.5
//    playerView.transform = .identity
//      .scaledBy(x: scaleFactor, y: scaleFactor)
//      .translatedBy(x: -playerView.frame.width / 2 + 8, y: -50)
//  } completion: { _ in
//    self.voiceoverVC.view.isUserInteractionEnabled = true
//    playerView.isUserInteractionEnabled = true
//  }
//  voiceoverVC.animateIn()
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    lookAheadTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { timer in
      self.refreshLookaheadThumbnail()
    })
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    showTutorialPopoverVC()
    voiceRecorder.requestRecordingPermissionIfNeeded() { granted in
      if !granted {
        self.micButton.isEnabled = false
      }
    }
    segmentsVC.adjustExpandingRate()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    lookAheadTimer?.invalidate()
  }
  
  func addPlayerView() {
    view.addSubview(playerView)
    playerView.backgroundColor = .black
    playerView.layer.borderWidth = 3
    let scaleFactor: CGFloat = 0.5
//    playerView.transform = .identity
//      .scaledBy(x: scaleFactor, y: scaleFactor)
//      .translatedBy(x: -playerView.frame.width / 2 + 8, y: -50)
    
    playerView.translatesAutoresizingMaskIntoConstraints = false
    [  playerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: scaleFactor),
       playerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: scaleFactor),
       playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
       playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant:  -50)
    ].forEach{$0.isActive = true}
    playerView.backgroundColor = .purple
    
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
  
  func addTopBar() {
    view.addSubview(topBar)
    topBar.fillWidthOfParent(withDefaultMargin: true)
    topBar.pinTopToParent(margin: 0, insideSafeArea: true)
    topBar.set(height: 50)

    let titleLabel = UILabel()
    titleLabel.textColor = .white
    titleLabel.text = "Add Voiceover"
    titleLabel.textAlignment = .center
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.sizeToFit()
    topBar.addSubview(titleLabel)
    titleLabel.centerXInParent()
    titleLabel.centerYInParent()
  }
  
  func addBottomStack() {
    view.addSubview(bottomStack)
    bottomStack.set(height: UIStackView.bottomHeight)
    bottomStack.fillWidthOfParent(withDefaultMargin: true)
    
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
      self.delegate?.voiceoverVCDidCancel()
    })
    bottomStack.addArrangedSubview(backButton)
    
    var undoConfig = UIButton.Configuration.gray()
    undoConfig.baseForegroundColor = .white
    undoConfig.cornerStyle = .capsule
    undoConfig.buttonSize = .large
    undoConfig.image = UIImage(systemName: "delete.left")
    undoConfig.baseForegroundColor = .white
    undoButton = UIButton(configuration: undoConfig, primaryAction: UIAction(){ _ in
      self.tappedUndoButton()
    })
    bottomStack.addArrangedSubview(undoButton)
    undoButton.set(height:47)
    undoButton.set(width:65)

    micButton = UIButton()
    micButton.tintColor = .white
    micButton.backgroundColor = .systemBlue
    micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
    bottomStack.addArrangedSubview(micButton)
    micButton.addTarget(self, action: #selector(touchDownMicButton), for: .touchDown)
    micButton.addTarget(self, action: #selector(touchDoneMicButton), for: .touchUpInside)
    micButton.addTarget(self, action: #selector(touchDoneMicButton), for: .touchDragOutside)
    
    micButton.set(height:47)
    micButton.set(width:110)
    micButton.roundCorner(radius: 47 / 2, cornerCurve: .circular)
    
    var confirmConfig = UIButton.Configuration.filled()
    confirmConfig.baseForegroundColor = .white
    confirmConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    confirmConfig.buttonSize = .large
    confirmConfig.image = UIImage(systemName: "checkmark")
    confirmButton = UIButton(configuration: confirmConfig, primaryAction: UIAction(){ _ in
      self.addVoiceoverToPreviewAndFinish()
    })
    bottomStack.addArrangedSubview(confirmButton)
  }
  
  func addLookAheadThumbnail() {
    view.addSubview(lookAheadThumbnail)
    lookAheadThumbnail.backgroundColor = .black
    lookAheadThumbnail.contentMode = .scaleAspectFill
    lookAheadThumbnail.roundCorner(radius: 12, cornerCurve: .continuous)
    let scaleFactor: CGFloat = 0.8

    lookAheadThumbnail.translatesAutoresizingMaskIntoConstraints = false
    [
      lookAheadThumbnail.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      lookAheadThumbnail.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
      lookAheadThumbnail.widthAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: scaleFactor),
      lookAheadThumbnail.heightAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: scaleFactor)
    ].forEach{$0.isActive = true}
  }
  
  func addFutureLabel() {
    futureLabel.text = "2 seconds ahead"
    futureLabel.textAlignment = .center
    futureLabel.textColor = .white
    futureLabel.font = .systemFont(ofSize: 12, weight: .light)
    futureLabel.sizeToFit()
    view.addSubview(futureLabel)
    futureLabel.centerXAnchor.constraint(equalTo: lookAheadThumbnail.centerXAnchor).isActive = true
    futureLabel.pinTop(toBottomOf: lookAheadThumbnail, margin: 12)
  }
  
  func addCurrentLabel() {
    currentLabel.text = "Now"
    currentLabel.textAlignment = .center
    currentLabel.textColor = .white
    currentLabel.font = .systemFont(ofSize: 12, weight: .light)
    currentLabel.sizeToFit()
    playerView.addSubview(currentLabel)
    currentLabel.centerXInParent()
    currentLabel.pinTop(toBottomOf: playerView, margin: 12)
  }
  
  func makeTrashPopoverVC() {
    trashPopoverVC.delegate = self
    trashPopoverVC.preferredContentSize = trashPopoverVC.preferredSize
    trashPopoverVC.modalPresentationStyle = .popover
    if let presentation = trashPopoverVC.presentationController {
      presentation.delegate = self
    }
  }
  
  func makeTutorialPopoverVC() {
    tutorialPopoverVC.delegate = self
    tutorialPopoverVC.preferredContentSize = tutorialPopoverVC.preferredSize
    tutorialPopoverVC.modalPresentationStyle = .popover
    if let presentation = tutorialPopoverVC.presentationController {
      presentation.delegate = self
    }
  }
  
  func showTutorialPopoverVC() {
    guard tutorialPopoverVC.parent == nil else { return }
    if let popover = tutorialPopoverVC.popoverPresentationController {
      popover.delegate = self
      popover.sourceView = micButton
      popover.sourceRect = micButton.bounds
      popover.permittedArrowDirections = .down
    }
    guard tutorialPopoverVC.isPresentable else { return }
    present(tutorialPopoverVC, animated: true) {
      // auto dismiss after 2 seconds
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        if !self.tutorialPopoverVC.isPresentable {
          self.tutorialPopoverVC.dismiss(animated: true)
        }
      }
    }
  }
  
  func addDebugButton() {
//    view.addSubview(debugButton)
    debugButton.backgroundColor = .secondarySystemFill
    debugButton.frame = CGRect(x: 50, y: 50, width: 150, height: 50)
    debugButton.setTitle("State", for: .normal)
    debugButton.addTarget(self, action: #selector(tappedDebugButton), for: .touchUpInside)
  }
  
  func addSegmentsVC() {
    view.addSubview(segmentsVC.view)
    addChild(segmentsVC)
    segmentsVC.didMove(toParent: self)
    segmentsVC.view.fillWidthOfParent(withDefaultMargin: true)
    segmentsVC.view.pinBottom(toTopOf: bottomStack, margin: 24)
    segmentsVC.view.set(height: SegmentsViewController.segmentHeight)
  }
  
  func renderFreshAssets() {
    guard composition.assets.count > 0 else { return }
    segmentsVC.renderFreshAssets()
    state = .standby
    guard let asset = composition.preVoiceoverPreviewAsset else { return }
    makePlayer(item: makePlayerItem(from: asset))
    refreshLookaheadThumbnail()
  }

  func updateAppearance() {
    undoButton.configuration?.image = UIImage(systemName: "delete.left")
    confirmButton.configuration?.baseForegroundColor = .white
    confirmButton.configuration?.image = UIImage(systemName: "checkmark")
    switch state {
    case .initial:
      playerView.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      micButton.isEnabled = false
      undoButton.isEnabled = composition.voiceSegments.count > 0
      lookAheadThumbnail.alpha = 0.2
      futureLabel.alpha = 0.2
   case .recording:
      playerView.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = true
      undoButton.isEnabled = false
      lookAheadThumbnail.alpha = 1
      futureLabel.alpha = 1
    case .playback:
      micButton.isEnabled = false
      playerView.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      undoButton.isEnabled = false
      lookAheadThumbnail.alpha = 0.2
      futureLabel.alpha = 0.2
    case .paused:
      micButton.isEnabled = true
      playerView.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      undoButton.isEnabled = composition.voiceSegments.count > 0
      lookAheadThumbnail.alpha = 0.2
      futureLabel.alpha = 0.2
    case .standby:
      playerView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = true
      undoButton.isEnabled = composition.voiceSegments.count > 0
      lookAheadThumbnail.alpha = 1
      futureLabel.alpha = 1
    case .complete:
      playerView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = false
      undoButton.isEnabled = composition.voiceSegments.count > 0
      confirmButton.configuration?.baseForegroundColor = .systemGreen
      let checkConfig = UIImage.SymbolConfiguration(weight: .bold)
      confirmButton.configuration?.image = UIImage(systemName: "checkmark", withConfiguration: checkConfig)
      lookAheadThumbnail.alpha = 0.2
      futureLabel.alpha = 0.2
    case .selecting:
      playerView.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      micButton.isEnabled = true
      undoButton.isEnabled = true
      undoButton.configuration?.image = UIImage(systemName: "delete.left.fill")
      lookAheadThumbnail.alpha = 0.2
      futureLabel.alpha = 0.2
    }
    debugButton.setTitle(state.debugDescription, for: .normal)
  }
  
  func tappedUndoButton() {
    loopTimer?.invalidate()
    switch state {
    case .standby, .playback, .paused:
      loopLastSegment()
      state = .selecting
      showTrashPopover()
    case .selecting:
      state = .standby
      player.seek(to: composition.voiceSegmentsDuration.cmTime)
      player.pause()
    default:
      assert(false)
    }
  }
  
  func loopLastSegment() {
    guard let segment = composition.voiceSegments.last,
    let player = player else {
      return
    }
    // sync player with segment.
    let segmentStart = composition.voiceSegments.filter{$0 != segment}.reduce(0) { partialResult, asset in
      return partialResult + asset.duration.seconds
    }
    let segmentEnd = segmentStart + segment.duration.seconds
    player.seek(to: segmentStart.cmTime)
    player.play()
    // synchronized playback
    voiceRecorder.play(at: segmentStart)

    // loop back after duration
    let duration = segmentEnd - segmentStart
    loopTimer?.invalidate()
    loopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true, block: { timer in
      player.seek(to: segmentStart.cmTime)
      player.play()
      // synchronized playback
      self.voiceRecorder.play(at: segmentStart)
    })
    
  }
  
  func deleteLatestSegment() {
    guard !composition.voiceSegments.isEmpty else {
      return
    }
    composition.voiceSegments.removeLast()
  }
  
  func seekToTip() {
    let seekTo = min(composition.voiceSegmentsDuration, composition.totalDuration)
    player.seek(to: seekTo.cmTime)
  }
  
  func showTrashPopover() {
    guard trashPopoverVC.parent == nil,
    let lastSegment = segmentsVC.lastSegment() else { return }
    if let popover = trashPopoverVC.popoverPresentationController {
      popover.delegate = self
      popover.sourceView = lastSegment
      popover.sourceRect = lastSegment.bounds
      popover.permittedArrowDirections = .down
    }
    guard trashPopoverVC.isPresentable else { return }
    present(trashPopoverVC, animated: true)
  }
  
  func playerDidFinish() {
    switch state {
    case .recording:
      voiceRecorder.stopRecording()
      let durationDiff = composition.totalDuration - composition.voiceSegmentsDuration
      guard durationDiff < 0.1 else {
        print("OOOOPS playerDidFinish when recording, but segment duration doesnt match!!")
        break
      }
      state = .complete
      segmentsVC.stopExpanding()
    default:
      break
    }
  }
  
  func shouldLoopWhenPlayerFinished() -> Bool {
    switch state {
    case .recording:
      return false
    case .playback:
      return true
    default:
      return true
    }
  }
  
  func refreshLookaheadThumbnail() {
    guard let asset = player.currentItem?.asset, lookAheadThumbnail.alpha == 1 else {
      return
    }
    let targetTime = min(player.currentTime().seconds + 2, composition.totalDuration)
    let thumbnail = asset.makethumbnail(at: targetTime, size: lookAheadThumbnail.size)
    UIView.transition(with: lookAheadThumbnail, duration: 1.3, options: .transitionCrossDissolve) {
      self.lookAheadThumbnail.image = thumbnail
    } completion: { finished in
      //
    }

  }
  
  @objc func playerDidFinishPlaying(note: NSNotification) {
    guard let _ = note.object as? AVPlayerItem else {
      return
    }
    if shouldLoopWhenPlayerFinished() {
      player.seek(to: .zero)
      player.play()
    }
    playerDidFinish()
  }
  
  @objc func didTapPlayerView() {
    if player.timeControlStatus == .playing {
      player.pause()
      voiceRecorder.pause()
      state = .paused
    } else if player.status == .readyToPlay {
      player.play()
      // synchronize voiceover playback starting at current time..
      voiceRecorder.play(at: player.currentTime().seconds)
      state = .playback
    } else {
      assert(false, "OOPS")
    }
  }
  
  @objc func touchDownMicButton() {
    switch state {
    case .standby:
      seekToTip()
      player.play()
      state = .recording
      segmentsVC.startExpanding()
      voiceRecorder.startRecording()
      micButton.backgroundColor = .systemBlue.withAlphaComponent(0.9)
      micButton.transform = .identity.scaledBy(x: 0.98, y: 0.98)
    case .playback, .paused:
      player.pause()
      seekToTip()
    case .selecting:
      player.pause()
      seekToTip()
      state = .standby
    default:
      assert(false)
    }
    
  }
  
  @objc func touchDoneMicButton() {
    state = .standby
    segmentsVC.stopExpanding()
    voiceRecorder.stopRecording()
    micButton.backgroundColor = .systemBlue.withAlphaComponent(1)
    micButton.transform = .identity
    player.pause()
  }
  
  @objc func tappedDebugButton() {
    state = VoiceoverState(rawValue: (state.rawValue + 1) % VoiceoverState.allCases.count)!
    debugButton.setTitle(state.debugDescription, for: .normal)
  }
  
  func addVoiceoverToPreviewAndFinish() {
    guard composition.voiceSegments.count > 0 else {
      delegate?.voiceoverVCDidCancel()
      return
    }
    
    composition.compositeWithVoiceover() { success in
      self.delegate?.voiceoverVCDidFinish(success: success)
    }
    
  }
}

extension VoiceoverViewController: UIPopoverPresentationControllerDelegate, PopoverMenuViewControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
  }
  
  func popoverVCDidTapLoopButton(_ popoverVC: PopoverMenuViewController) {
    // nop.
  }
  
  func popoverVCDidTapTrashButton(_ popoverVC: PopoverMenuViewController) {
    if popoverVC == trashPopoverVC {
      assert(state == .selecting)
      deleteLatestSegment()
    }
    popoverVC.dismiss(animated: true)
  }
  
  func popoverVCDidDisappear(_ popoverVC: PopoverMenuViewController) {
    loopTimer?.invalidate()
    if popoverVC == trashPopoverVC {
      state = .standby
      renderFreshAssets()
      seekToTip()
      player.pause()
      voiceRecorder.pause()
    }
  }
  
  
}

extension VoiceoverViewController: VoiceRecorderDelegate {
  func voiceRecorderDidFinishRecording(to url: URL) {
    let voiceAsset = AVURLAsset(url: url)
    composition.voiceSegments.append(voiceAsset)
    segmentsVC.renderFreshAssets()
    state = .standby
  }
}
