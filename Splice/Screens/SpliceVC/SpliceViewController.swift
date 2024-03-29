//
//  SpliceViewController.swift
//  Splice
//
//  Created by June Kim on 10/24/21.
//

import UIKit
import Combine
import AVFoundation

enum SpliceMode {
  case playSplice
  case pauseSplice
}

enum SpliceState {
  case initial
  case including(TimeInterval) // start time
  case neutral
  case looping(Int) // looping splice index
}

protocol SpliceViewControllerDelegate: AnyObject {
  func spliceVCDidRequestAlbumPicker(_ spliceVC: SpliceViewController)
  func spliceVCDidRequestPreview(_ spliceVC: SpliceViewController)
  func presentAlbumImportVC()
}

// A full-screen VC that contains the progress bar, the player, and control buttons.
class SpliceViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: SpliceViewControllerDelegate?
  
  let spinner = UIActivityIndicatorView(style:.large)
  let loadingLabel = UILabel()
  let topBar = UIView()
  var playerVC: LongPlayerViewController!
  let bottomStack = UIStackView()
  var playButton: UIButton!
  var previewButton: UIButton!
  let spliceButton = UIButton(type: .system)
  let timelineVC: TimelineControl
  let timerLabel = UILabel()
  var bpmBadgeVC: BpmBadgeViewController!
  var popoverMenuVC: PopoverMenuViewController!

  var spliceMode: SpliceMode = .pauseSplice
  var spliceStartTime: TimeInterval = 0
  var spliceState: SpliceState = .neutral {
    didSet {
      updateAppearance()
    }
  }
  var subscriptions = Set<AnyCancellable>()
  var touchDownTimer: Timer?
  var touchDoneTimer: Timer?

  var assets: [AVAsset] {
    return composition.assets
  }
  var splices: [Splice] {
    return composition.splices
  }
  var totalDuration: TimeInterval {
    return composition.totalDuration
  }

  init(composition: SpliceComposition) {
    self.composition = composition
    timelineVC = TimelineScrollViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    addSpinner()
    addTopBar()
    addPlayerVC()
    addBottomStackView()
    addSpliceButton()
    addTimelineVC()
    makePopoverVC()
    observeTimeSubject()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if composition.assets.isEmpty {
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAssetTransformDone),
                                             name: SpliceComposition.transformDoneNotification,
                                             object: nil)
    }
    updateAppearance()
    if !composition.assets.isEmpty {
      stopSpinning()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if composition.assets.isEmpty {
      delegate?.presentAlbumImportVC()
    }
  }
  
  func addSpinner() {
    view.addSubview(spinner)
    spinner.hidesWhenStopped = true
    spinner.centerXInParent()
    spinner.centerYInParent(offset: -40)
    spinner.startAnimating()
    
    view.addSubview(loadingLabel)
    loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    loadingLabel.text = "Loading clips from album...\nPlease wait."
    loadingLabel.numberOfLines = 0
    loadingLabel.textAlignment = .center
    loadingLabel.centerXInParent()
    loadingLabel.pinTop(toBottomOf: spinner, margin: 32)
    loadingLabel.isHidden = false
  }
  
  func addTopBar() {
    let barHeight: CGFloat = 50
    view.addSubview(topBar)
    topBar.backgroundColor = .black
    topBar.pinTopToParent()
    topBar.fillWidthOfParent()
    topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: barHeight).isActive = true
    
    // stackView
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .equalSpacing
    topBar.addSubview(stackView)
    stackView.fillWidthOfParent()
    stackView.pinBottomToParent()
    stackView.set(height: barHeight)
    
    // album button
    var albumButtonConfig = topBarButtonConfig()
    albumButtonConfig.image = UIImage(systemName: "photo.on.rectangle")
    let albumButton = UIButton(configuration: albumButtonConfig, primaryAction: UIAction() { _ in
      self.delegate?.spliceVCDidRequestAlbumPicker(self)
    })
    stackView.addArrangedSubview(albumButton)
    
    // timer
    stackView.addArrangedSubview(timerLabel)
    timerLabel.set(height: 50)
    timerLabel.timeFormat()
    timerLabel.isUserInteractionEnabled = true
    timerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedTimerLabel)))
    
    // bpm
    bpmBadgeVC = BpmBadgeViewController(composition: composition)
    stackView.addArrangedSubview(bpmBadgeVC.view)
    addChild(bpmBadgeVC)
    bpmBadgeVC.didMove(toParent: self)
    
  }
  
  func topBarButtonConfig() -> UIButton.Configuration {
    var config = UIButton.Configuration.plain()
    config.baseForegroundColor = .white
    return config
  }
  
  func addPlayerVC() {
    playerVC = LongPlayerViewController(composition: composition)
    playerVC.delegate = self
    view.addSubview(playerVC.view)
    playerVC.view.pinTop(toBottomOf: topBar)
    playerVC.view.fillWidthOfParent()
    playerVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    addChild(playerVC)
    playerVC.didMove(toParent: self)
  }
  
  func addBottomStackView() {
    let stackHeight: CGFloat = 56
    
    view.addSubview(bottomStack)
    bottomStack.pinBottomToParent(margin: 18, insideSafeArea: true)
    bottomStack.fillWidthOfParent(withDefaultMargin: true)
    bottomStack.set(height: stackHeight)
    
    bottomStack.axis = .horizontal
    bottomStack.alignment = .center
    bottomStack.distribution = .equalSpacing
    
    // play button
    var playConfig = UIButton.Configuration.filled()
    playConfig.image = UIImage(systemName: "play.fill")
    playConfig.baseForegroundColor = .white
    playConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    playConfig.buttonSize = .large
    
    playButton = UIButton(configuration: playConfig, primaryAction: UIAction() { _ in
      self.playerVC.togglePlayback()
    })
//    playButton.setImageScale(to: 1.2)
    bottomStack.addArrangedSubview(playButton)
    
    // preview button
    var previewConfig = UIButton.Configuration.filled()
    previewConfig.image = UIImage(systemName: "eye")
    previewConfig.title = "Preview"
    previewConfig.baseForegroundColor = .white
    previewConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    previewConfig.buttonSize = .medium
    previewConfig.imagePlacement = .top
    previewConfig.buttonSize = .small

    previewButton = UIButton(configuration: previewConfig, primaryAction: UIAction() {_ in
      self.delegate?.spliceVCDidRequestPreview(self)
      self.spliceState = .neutral
      self.playerVC.pause()
      Tutorial.shared.previewButtonTapDone = true
    })
//    previewButton.setImageScale(to: 1.2)
    bottomStack.addArrangedSubview(previewButton)
  }
  
  func addSpliceButton() {
    var config = UIButton.Configuration.filled()
    config.image = UIImage(systemName: "scissors")
    config.baseForegroundColor = .white
    config.baseBackgroundColor = .systemBlue
    
    spliceButton.configuration = config
    bottomStack.addSubview(spliceButton)
    spliceButton.set(height:47)
    spliceButton.set(width:110)
    spliceButton.roundCorner(radius: 47 / 2, cornerCurve: .circular)
    spliceButton.centerXInParent()
    spliceButton.centerYInParent()
    
    spliceButton.addTarget(self, action: #selector(touchedDownSpliceButton), for: .touchDown)
    spliceButton.addTarget(self, action: #selector(touchDoneSpliceButton), for: .touchUpInside)
    spliceButton.addTarget(self, action: #selector(touchDoneSpliceButton), for: .touchDragExit)
    
  }
  
  func addTimelineVC() {
    timelineVC.delegate = self
    view.addSubview(timelineVC.view)
    timelineVC.view.set(height: TimelineScrollViewController.defaultHeight)
    timelineVC.view.fillWidthOfParent(withDefaultMargin: true)
    timelineVC.view.pinBottom(toTopOf: bottomStack, margin: 12)
    if let vc = timelineVC as? UIViewController {
      addChild(vc)
      vc.didMove(toParent: self)
    }
  }
  
  func makePopoverVC() {
    popoverMenuVC = PopoverMenuViewController(views: [.loopButton, .trashButton])
    popoverMenuVC.delegate = self
    popoverMenuVC.preferredContentSize = popoverMenuVC.preferredSize
    popoverMenuVC.modalPresentationStyle = .popover
    if let presentation = popoverMenuVC.presentationController {
      presentation.delegate = self
    }
  }
      
  func observeTimeSubject() {
    composition.timeSubject.receive(on: DispatchQueue.main).sink { timeInterval in
      switch self.spliceState {
      case .including:
        let lower = max(0, min(self.spliceStartTime, timeInterval))
        let upper = max(0, max(self.spliceStartTime, timeInterval))
        let cumulative = self.composition.cumulativeDuration(currentRange: lower...upper)
        self.timerLabel.updateTime(cumulative)
      case .looping(let spliceIndex):
        guard spliceIndex < self.composition.splices.count else { return }
        let splice = self.composition.splices[spliceIndex]
        let lower = splice.lowerBound
        let upper = splice.upperBound
        if timeInterval >= upper {
          // reached the end of looping segment. Seek to lower bound
          self.playerVC.seek(to: lower)
        }
        
        break
      default: break
      }
    }.store(in: &self.subscriptions)
  }
  
  func updateAppearance() {
    switch spliceState {
    case .initial:
      spinner.startAnimating()
      playerVC.view.isUserInteractionEnabled = false
      playButton.isEnabled = false
      previewButton.isEnabled = composition.splices.count > 0
    case .including:
      playerVC.view.isUserInteractionEnabled = false
      timelineVC.appearIncluding()
      UIView.animate(withDuration: 0.2) {
        self.spliceButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
      }
      playButton.isEnabled = false
      previewButton.isEnabled = false
    case .neutral:
      playerVC.view.isUserInteractionEnabled = true
      timelineVC.appearNeutral()
      UIView.animate(withDuration: 0.2) {
        self.spliceButton.transform = CGAffineTransform(scaleX: 1, y: 1)
      }
      spliceButton.isEnabled = composition.assets.count > 0
      playButton.isEnabled = composition.assets.count > 0 && timelineVC.scrubbingState == .notScrubbing
      previewButton.isEnabled = composition.splices.count > 0
    case .looping(let spliceIndex):
      playerVC.view.isUserInteractionEnabled = true
      timelineVC.appearLooping(at: spliceIndex)
    }
    self.timerLabel.updateTime(self.composition.splicesDuration)
    navigationItem.rightBarButtonItem?.isEnabled = composition.splices.count > 0
  }
  
  func renderFreshAssets() {
    playerVC.composition = composition
    playerVC.renderFreshAssets()
    timelineVC.composition = composition
    timelineVC.renderFreshAssets()
    spliceState = .neutral
  }
  
  @objc func touchedDownSpliceButton() {
    setSpliceMode()
    if !playerVC.isPlaying {
      playerVC.play()
    }
    var playbackTime = playerVC.currentPlaybackTime()
    if playerVC.playerAtEnd() {
      playbackTime = 0
    }
    spliceState = .including(playbackTime)
    timelineVC.startExpandingSegment(startTime: playbackTime)
    touchDoneTimer?.invalidate()
    showTouchDownTutorialsIfNeeded()
  }
  
  func setSpliceMode() {
    if !playerVC.isPlaying {
      spliceMode = .pauseSplice
    } else if playerVC.isPlaying {
      spliceMode = .playSplice
    }
    spliceStartTime = playerVC.currentPlaybackTime()
  }
  
  @objc func touchDoneSpliceButton() {
    if spliceMode == .pauseSplice {
      playerVC.pause()
    }
    finishSplicing()
    touchDownTimer?.invalidate()
    showTouchDoneTutorialsIfNeeded()
  }
  
  func showTouchDownTutorialsIfNeeded() {
    if !Tutorial.shared.tapAndHoldContinueDone {
      touchDownTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
        self.timelineVC.seekerBar.displayTooltip("Including")
        Tutorial.shared.tapAndHoldContinueDone = true
        self.showTouchDownTutorialsIfNeeded()
      })
    } else if !Tutorial.shared.tapAndHoldStopDone {
      touchDownTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false, block: { _ in
        self.timelineVC.seekerBar.displayTooltip("Touch up to stop")
        Tutorial.shared.tapAndHoldStopDone = true
        self.showTouchDownTutorialsIfNeeded()
      })
    }
  }
  
  func showTouchDoneTutorialsIfNeeded() {
    if !Tutorial.shared.scrubTimelineDone {
      touchDoneTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
        self.hidePopover()
        self.timelineVC.view.displayTooltip("Move the slider to skip")
        Tutorial.shared.scrubTimelineDone = true
        self.showTouchDoneTutorialsIfNeeded()
      })
    } else if !Tutorial.shared.selectSegmentDone {
      // FIXME: the tooltip gets clipped :(
      touchDoneTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { _ in
        if let segment = self.timelineVC.firstInterval(), segment.width > 35,
           self.popoverMenuVC.isPresentable {
          segment.displayTooltip("Tap to select")
          Tutorial.shared.selectSegmentDone = true
          self.showTouchDoneTutorialsIfNeeded()
        }
      })
    }
  }
  
  func showPlaybackAtEndTutorialIfNeeded() {
    if composition.splices.count >= 1, !Tutorial.shared.previewButtonTapDone {
      previewButton.displayTooltip("Preview")
      Tutorial.shared.previewButtonTapDone = true
    }
  }
  
  func finishSplicing() {
    switch spliceState {
    case .initial:
      return
    case .including(let beginTime):
      let endTime = playerVC.currentPlaybackTime()
      guard endTime - beginTime > 0.05 else {
        timelineVC.view.displayTooltip("Tap & Hold")
        spliceState = .neutral
        break
      }
      composition.append(beginTime...endTime)
      spliceState = .neutral
    case .neutral, .looping:
      updateAppearance()
      return
    }
    timelineVC.stopExpandingSegment()
    timelineVC.updateSegmentsForSplices()
  }
  
  @objc func tappedTimerLabel() {
    
  }
  
  @objc func handleAssetTransformDone() {
    guard !composition.assets.isEmpty else { return }
    view.isUserInteractionEnabled = true
    spinner.stopAnimating()
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  override var shouldAutorotate: Bool { return false }
  override var prefersStatusBarHidden: Bool { return true }
}

extension SpliceViewController: LongPlayerViewControllerDelegate {
  func longPlayerVCDidChangePlaybackState(_ state: LongPlayerState) {
    switch state {
    case .playing, .scrubbingWhenPlaying:
      playButton.configuration?.image = UIImage(systemName: "pause.fill")
    case .paused, .scrubbingWhenPaused:
      playButton.configuration?.image = UIImage(systemName: "play.fill")
    case .initial, .atEnd:
      playButton.configuration?.image = UIImage(systemName: "play.fill")
      timelineVC.appearNeutral()
    }
    if state == .atEnd {
      showPlaybackAtEndTutorialIfNeeded()
    }
    updateAppearance()
  }
  
  func longPlayerVCDidFinishPlaying(_ playerVC: LongPlayerViewController) {
    finishSplicing()
  }
  
  func showPopover() {
    guard popoverMenuVC.parent == nil else { return }
    if let popover = popoverMenuVC.popoverPresentationController {
      popover.delegate = self
      popover.sourceView = timelineVC.view
      popover.sourceRect = timelineVC.view.bounds
      popover.permittedArrowDirections = .down
    }
    guard popoverMenuVC.isPresentable else { return }
    present(popoverMenuVC, animated: true)
  }
  
  func hidePopover() {
    popoverMenuVC.dismiss(animated: true)
  }
  
  func startLooping(at index: Int) {
    playerVC.seek(to: composition.splices[index].lowerBound)
    playerVC.play()
  }
  
  func stopLoopingIfNeeded() {
    switch spliceState {
    case .looping:
      spliceState = .neutral
      playerVC.pause()
    default: break
    }
  }
}

extension SpliceViewController: TimelineControlDelegate {
  func scrubbingStateChanged(_ scrubbingState: ScrubbingState) {
    switch scrubbingState {
    case .scrubbing(let selectingIndex):
      if let spliceIndex = selectingIndex {
        if spliceIndex != timelineVC.currentlySelectedIndex {
          showPopover()
        }
      } else {
        hidePopover()
      }
    case .notScrubbing:
      // nop.
      break
    }
  }
  
  func currentTimeForDisplay() -> TimeInterval {
    // currentPlaybackTime is not exact when looping over
    if playerVC.playerAtEnd() {
      return 0
    }
    return playerVC.currentPlaybackTime()
  }

  func synchronizePlaybackTime() {
    composition.timeSubject.send(playerVC.currentPlaybackTime())
  }

  func scrubberScrubbed(to time: TimeInterval) {
    playerVC.seek(to: time)
  }
  
  func timelineVCWillBeginScrubbing() {
    playerVC.appearScrubbing(playerVC.isPlaying)
  }

  func timelineVCDidFinishScrubbing() {
    playerVC.handleStoppedScrubbing()
  }
  
  func timelineVCDidDeleteSegment() {
    updateAppearance()
  }
  func timelineVCDidTapSelectInterval(at index: Int) {
    showPopover()
  }
  
}

extension SpliceViewController: Spinnable {
  func spin() {
    spinner.startAnimating()
    loadingLabel.isHidden = false
    if playerVC != nil {
      playerVC.view.isHidden = true
    }
    timelineVC.view.obscure()
    spliceButton.obscure()
    bottomStack.obscure()
    topBar.obscure()
  }

  func stopSpinning() {
    spinner.stopAnimating()
    loadingLabel.isHidden = true
    if playerVC != nil {
      playerVC.view.isHidden = false
    }
    timelineVC.view.clarify()
    spliceButton.clarify()
    bottomStack.clarify()
    topBar.clarify()
  }
}

extension SpliceViewController: UIPopoverPresentationControllerDelegate, PopoverMenuViewControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
  }
  
  func popoverVCDidTapLoopButton(_ popoverVC: PopoverMenuViewController) {
    guard let selected = timelineVC.currentlySelectedIndex,
          selected < composition.splices.count else { return }
    popoverVC.highlightLoopButton()
    spliceState = .looping(selected)
    startLooping(at: selected)
  }
  
  func popoverVCDidTapTrashButton(_ popoverVC: PopoverMenuViewController) {
    guard let currentIndex = timelineVC.currentlySelectedIndex else { return }
    composition.removeSplice(at: currentIndex)
    timelineVC.updateSegmentsForSplices()
    updateAppearance()
    popoverVC.dismiss(animated: true)
    stopLoopingIfNeeded()
  }
  
  func popoverVCDidDisappear(_ popoverVC: PopoverMenuViewController) {
    stopLoopingIfNeeded()
  }
  
}
