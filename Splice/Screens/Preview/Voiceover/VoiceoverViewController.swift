//
//  VoiceoverViewController.swift
//  Shortn
//
//  Created by June Kim on 11/26/21.
//

import UIKit
import AVFoundation

protocol VoiceoverViewControllerDelegate: AnyObject {
  func playerFrame() -> CGRect
  func voiceoverVCDidStartRecording()
  func voiceoverVCDidStopRecording()
  func voiceoverVCDidCancel()
  func voiceoverVCDidFinish()
  func seekPlayer(to time: TimeInterval)
  func currentPlaybackTime() -> TimeInterval
  func assetForThumbnail() -> AVAsset?
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
      updateAppearance()
    }
  }
  let transitionDuration: TimeInterval = 0.3
  let bottomStack = UIStackView()
  var micButton: UIButton!
  var undoButton: UIButton!
  var rewindButton: UIButton!
  var confirmButton: UIButton!
  var stateBorder = TouchlessView()
  var lookAheadThumbnail = UIImageView()
  var playerFrame: CGRect {
    if let delegate = delegate {
      return delegate.playerFrame()
    }
    return .zero
  }
  let playerControlStack = UIStackView()
  let debugButton = UIButton()
  var segmentsVC: VoiceSegmentsViewController!
  var recordingStartTime: TimeInterval = 0
  var loopingRange: ClosedRange<TimeInterval>?
  var displayLink: CADisplayLink!
  var lookAheadTimer: Timer!
  let currentLabel = UILabel()
  let futureLabel = UILabel()
  
  let trashPopoverVC = PopoverMenuViewController(views: [.trashButton])
  let tutorialPopoverVC = PopoverMenuViewController(views: [.tutorial("Tap & hold to record")])

  init(composition: SpliceComposition) {
    self.composition = composition
    self.segmentsVC = VoiceSegmentsViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addBottomStack()
    addStateBorder()
    addLookAheadThumbnail()
    addCurrentLabel()
    addFutureLabel()
    addPlayerControlStack()
    addSegmentsVC()
    makeTrashPopoverVC()
    makeTutorialPopoverVC()

    addDebugButton()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    subscribeToDisplayLink()
    lookAheadTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { timer in
      self.refreshLookaheadThumbnail()
    })
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    unsubscribeFromDisplayLink()
    lookAheadTimer?.invalidate()
  }
  
  func subscribeToDisplayLink() {
    displayLink?.invalidate()
    displayLink = CADisplayLink(target: self, selector: #selector(displayStep))
    displayLink.isPaused = false
    displayLink.add(to: .main, forMode: .common)
  }
  
  @objc func displayStep() {
    guard let loop = loopingRange, let delegate = delegate else { return }
    let playTime = delegate.currentPlaybackTime()
    if loop.contains(playTime) { return }
    delegate.seekPlayer(to: loop.lowerBound)
  }
  
  func unsubscribeFromDisplayLink() {
    displayLink?.invalidate()
  }
  
  func addBottomStack() {
    view.addSubview(bottomStack)
    bottomStack.set(height: UIStackView.bottomHeight)
    bottomStack.fillWidthOfParent(withDefaultMargin: true)
    
    bottomStack.pinBottomToParent(margin: 24, insideSafeArea: true)
    // for animations
    bottomStack.transform = .identity.translatedBy(x: 0, y: 100)
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
      self.delegate?.voiceoverVCDidFinish()
    })
    bottomStack.addArrangedSubview(confirmButton)
  }
  
  func addStateBorder() {
    view.addSubview(stateBorder)
    stateBorder.alpha = 0
    stateBorder.layer.borderWidth = 2
  }
  
  func addLookAheadThumbnail() {
    view.addSubview(lookAheadThumbnail)
    lookAheadThumbnail.backgroundColor = .black
    lookAheadThumbnail.alpha = 0
    lookAheadThumbnail.frame = CGRect(x: view.width, y: view.height / 2, width: .zero, height: .zero)
    lookAheadThumbnail.roundCorner(radius: 12, cornerCurve: .continuous)
  }
  
  func addFutureLabel() {
    futureLabel.text = "2 seconds ahead"
    futureLabel.textAlignment = .center
    futureLabel.textColor = .white
    futureLabel.font = .systemFont(ofSize: 12, weight: .light)
    futureLabel.sizeToFit()
    view.addSubview(futureLabel)
    futureLabel.alpha = 0
  }
  
  func addCurrentLabel() {
    currentLabel.text = "Now"
    currentLabel.textAlignment = .center
    currentLabel.textColor = .white
    currentLabel.font = .systemFont(ofSize: 12, weight: .light)
    currentLabel.sizeToFit()
    view.addSubview(currentLabel)
    currentLabel.alpha = 0
  }
  
  func addPlayerControlStack() {
    view.addSubview(playerControlStack)
    playerControlStack.alpha = 0
    playerControlStack.axis = .horizontal
    playerControlStack.alignment = .center
    playerControlStack.distribution = .equalSpacing
   
//    var rewindConfig = UIButton.Configuration.plain()
//    rewindConfig.baseForegroundColor = .white
//    rewindConfig.buttonSize = .medium
//    rewindConfig.image = UIImage(systemName: "arrow.uturn.backward")
//    rewindButton = UIButton(configuration: rewindConfig, primaryAction: UIAction(){ _ in
//      self.rewind()
//    })
//    playerControlStack.addArrangedSubview(rewindButton)
    
//    var forwardConfig = UIButton.Configuration.plain()
//    forwardConfig.baseForegroundColor = .white
//    forwardConfig.buttonSize = .medium
//    forwardConfig.image = UIImage(systemName: "forward.end.fill")
//    let forwardButton = UIButton(configuration: forwardConfig, primaryAction: UIAction(){ _ in
//      self.forward()
//    })
//    playerControlStack.addArrangedSubview(forwardButton)
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        if !self.tutorialPopoverVC.isPresentable {
          self.tutorialPopoverVC.dismiss(animated: true)
        }
      }
    }
  }
  
  func addDebugButton() {
    view.addSubview(debugButton)
    debugButton.backgroundColor = .secondarySystemFill
    debugButton.frame = CGRect(x: 50, y: 50, width: 150, height: 50)
    debugButton.setTitle("State", for: .normal)
    debugButton.addTarget(self, action: #selector(tappedDebugButton), for: .touchUpInside)
  }
  
  func addSegmentsVC() {
    view.addSubview(segmentsVC.view)
    addChild(segmentsVC)
    segmentsVC.didMove(toParent: self)
  }
  
  func animateIn() {
    stateBorder.frame = playerFrame
    playerControlStack.frame = CGRect(x: playerFrame.minX,
                                      y: playerFrame.maxY,
                                      width: playerFrame.width, height: 40)
    playerControlStack.alpha = 0
    segmentsVC.view.frame = CGRect(x: view.width,
                                   y: playerControlStack.maxY + 24,
                                   width: view.width - UIView.defaultEdgeMargin * 2,
                                   height: SegmentsViewController.segmentHeight)
    currentLabel.center = CGPoint(x: playerFrame.midX, y: playerFrame.maxY + 12)

    UIView.animate(withDuration: transitionDuration + 0.01) {
      self.bottomStack.transform = .identity
      self.lookAheadThumbnail.alpha = 1
      let scaleFactor: CGFloat = 0.8
      let playerFrame = self.playerFrame
      self.lookAheadThumbnail.frame = CGRect(x: playerFrame.maxX + playerFrame.width * (1 - scaleFactor) / 2,
                                             y: playerFrame.minY + playerFrame.height * (1 - scaleFactor) / 2,
                                             width: playerFrame.width * scaleFactor,
                                             height: playerFrame.height * scaleFactor)
      self.segmentsVC.view.frame = CGRect(x: UIView.defaultEdgeMargin,
                                          y: self.segmentsVC.view.minY,
                                          width: self.segmentsVC.view.width,
                                          height: SegmentsViewController.segmentHeight)
      
    } completion: { _ in
      self.futureLabel.center = CGPoint(x: self.lookAheadThumbnail.midX,
                                        y: self.lookAheadThumbnail.maxY + 12)
      self.showTutorialPopoverVC()
      UIView.animate(withDuration: 0.2) {
        self.stateBorder.alpha = 1
        self.playerControlStack.alpha = 1
        self.futureLabel.alpha = 1
        self.currentLabel.alpha = 1
      }
    }
  }
  
  func animateOut() {
    stateBorder.alpha = 0
    playerControlStack.alpha = 0
    futureLabel.alpha = 0
    currentLabel.alpha = 0
    UIView.animate(withDuration: transitionDuration) {
      self.bottomStack.transform = .identity.translatedBy(x: 0, y: 100)
      self.stateBorder.alpha = 0
      self.lookAheadThumbnail.alpha = 0
      self.lookAheadThumbnail.frame = CGRect(x: self.view.width,
                                             y: self.view.height / 2,
                                             width: .zero, height: .zero)
      self.segmentsVC.view.frame = CGRect(x: self.view.width,
                                          y: self.segmentsVC.view.minY,
                                          width: self.segmentsVC.view.width,
                                          height: SegmentsViewController.segmentHeight)
    }
  }

  func renderFreshAssets() {
    guard composition.assets.count > 0 else { return }
    segmentsVC.renderFreshAssets()
    state = .standby
  }

  func updateAppearance() {
    undoButton.configuration?.image = UIImage(systemName: "delete.left")
    confirmButton.configuration?.baseForegroundColor = .white
    confirmButton.configuration?.image = UIImage(systemName: "checkmark")
    switch state {
    case .initial:
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      micButton.isEnabled = false
      undoButton.isEnabled = composition.voiceSegments.count > 0
    case .recording:
      stateBorder.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = true
      undoButton.isEnabled = false
    case .playback:
      micButton.isEnabled = false
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      undoButton.isEnabled = false
    case .paused:
      micButton.isEnabled = false
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      undoButton.isEnabled = true
    case .standby:
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = true
      undoButton.isEnabled = composition.voiceSegments.count > 0
    case .complete:
      stateBorder.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = false
      undoButton.isEnabled = true
      confirmButton.configuration?.baseForegroundColor = .systemGreen
      let checkConfig = UIImage.SymbolConfiguration(weight: .bold)
      confirmButton.configuration?.image = UIImage(systemName: "checkmark", withConfiguration: checkConfig)
    case .selecting:
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      micButton.isEnabled = true
      undoButton.isEnabled = true
      undoButton.configuration?.image = UIImage(systemName: "delete.left.fill")
    }
    debugButton.setTitle(state.debugDescription, for: .normal)
  }
  
  func tappedUndoButton() {
    if state == .standby {
      loopLatestSegment()
      state = .selecting
    } else if state == .selecting {
      loopingRange = nil
      state = .standby
      delegate?.seekPlayer(to: composition.voiceSegmentsDuration)
    }
  }
  
  func loopLatestSegment() {
    guard let segment = composition.voiceSegments.last else {
      return
    }
    // sync player with segment.
    let segmentStart = composition.voiceSegments.filter{$0 != segment}.reduce(0) { partialResult, asset in
      return partialResult + asset.duration.seconds
    }
    let segmentEnd = segmentStart + segment.duration.seconds
    loopingRange = segmentStart...segmentEnd
    delegate?.seekPlayer(to: segmentStart)
  }
  
  func deleteLatestSegment() {
    guard !composition.voiceSegments.isEmpty else {
      return
    }
    composition.voiceSegments.removeLast()
  }
  
  func seekToTip() {
    delegate?.seekPlayer(to: min(composition.voiceSegmentsDuration, composition.totalDuration))
  }
  
  func showTrashPopover() {
    guard trashPopoverVC.parent == nil,
    let lastSegment = segmentsVC.lastSegment() else { return }
    if let popover = trashPopoverVC.popoverPresentationController {
      popover.delegate = self
      popover.sourceView = lastSegment
      popover.sourceRect = segmentsVC.view.bounds
      popover.permittedArrowDirections = .down
    }
    guard trashPopoverVC.isPresentable else { return }
    present(trashPopoverVC, animated: true)
  }
  
  func startRecording() {
    // should not need starting time because the duration of the previous segments should sum up to start time.
    // may be out of sync, but that's ok for this level of precision.
//    if let delegate = delegate {
//      recordingStartTime = delegate.currentPlaybackTime()
//    }
    
  }
  
  func stopRecording() {
    
  }
  
  func playerDidFinish() {
    switch state {
    case .recording:
      stopRecording()
      let durationDiff = composition.totalDuration - composition.voiceSegmentsDuration
      guard durationDiff < 0.1 else {
        print("OOOOPS playerDidFinish when recording, but segment duration doesnt match!!")
        break
      }
      state = .complete
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
    guard let delegate = delegate,
    let asset = delegate.assetForThumbnail() else {
      return
    }
    let targetTime = min(delegate.currentPlaybackTime() + 2, composition.totalDuration)
    let thumbnail = asset.makethumbnail(at: targetTime, size: lookAheadThumbnail.size)
    UIView.transition(with: lookAheadThumbnail, duration: 1.5, options: .transitionCrossDissolve) {
      self.lookAheadThumbnail.image = thumbnail
    } completion: { finished in
      //
    }

  }

  @objc func touchDownMicButton() {
    state = .recording
    segmentsVC.startExpanding()
    startRecording()
    delegate?.voiceoverVCDidStartRecording()
    micButton.backgroundColor = .systemBlue.withAlphaComponent(0.9)
    micButton.transform = .identity.scaledBy(x: 0.98, y: 0.98)
  }
  
  @objc func touchDoneMicButton() {
    state = .standby
    segmentsVC.stopExpanding()
    stopRecording()
    delegate?.voiceoverVCDidStopRecording()
    micButton.backgroundColor = .systemBlue.withAlphaComponent(1)
    micButton.transform = .identity
  }
  
  @objc func tappedDebugButton() {
    state = VoiceoverState(rawValue: (state.rawValue + 1) % VoiceoverState.allCases.count)!
    debugButton.setTitle(state.debugDescription, for: .normal)
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
      state = .standby
    }
  }
  
  func popoverVCDidDisappear(_ popoverVC: PopoverMenuViewController) {
    if popoverVC == trashPopoverVC {
      assert(state == .selecting)
      state = .standby
      seekToTip()
    }
  }
  
  
}
