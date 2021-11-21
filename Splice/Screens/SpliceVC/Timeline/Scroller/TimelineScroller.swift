//
//  TimelineScroller.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit
import Combine

class TimelineScroller: UIViewController, TimelineControl {
  static let defaultHeight: CGFloat = 80
  var delegate: TimelineControlDelegate?
  unowned var composition: SpliceComposition
  var scrubbingState: ScrubbingState = .notScrubbing
  var thumbnailsVC: ThumbnailsViewController!
  var intervalsVC: IntervalsViewController!
  var waveScrollView = UIScrollView()
  var waveVC: AudioWaveViewController!
  var spliceState: SpliceState = .initial {
    didSet {
      
    }
  }
  var displayLink: CADisplayLink!

  let seekerBar = UIView()
  var subscriptions = Set<AnyCancellable>()

  init(composition: SpliceComposition) {
    self.composition = composition
    self.thumbnailsVC = ThumbnailsViewController(composition: composition)
    self.intervalsVC = IntervalsViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addThumbnailsVC()
    addAudioWave()
    addIntervalsVC()
    addSeekerBar()
    observeTimer()
    subscribeToDisplayLink()
  }
  
  func addThumbnailsVC() {
    thumbnailsVC.delegate = self
    addChild(thumbnailsVC)
    view.addSubview(thumbnailsVC.view)
    thumbnailsVC.didMove(toParent: self)
    thumbnailsVC.view.pinBottomToParent()
    thumbnailsVC.view.fillWidthOfParent()
    thumbnailsVC.view.set(height: ThumbnailsViewController.defaultHeight)
  }
  
  func addIntervalsVC() {
    intervalsVC.delegate = self
    // !!
    thumbnailsVC.scrollView.addSubview(intervalsVC.view)
    addChild(intervalsVC)
    intervalsVC.didMove(toParent: self)
  }
  
  func addAudioWave() {
    view.addSubview(waveScrollView)
    waveScrollView.pinBottom(toTopOf: thumbnailsVC.view, margin: 4)
    waveScrollView.fillWidthOfParent()
    waveScrollView.set(height: AudioWaveViewController.defaultHeight)
    waveVC = AudioWaveViewController(composition: composition)
    waveScrollView.addSubview(waveVC.view)
    waveScrollView.isUserInteractionEnabled = false

  }
  
  func addSeekerBar() {
    seekerBar.backgroundColor = .white
    seekerBar.alpha = 0.8
    view.addSubview(seekerBar)
    seekerBar.centerXInParent()
    seekerBar.centerYAnchor.constraint(equalTo: thumbnailsVC.view.centerYAnchor).isActive = true
    seekerBar.set(width: 3)
    seekerBar.set(height: 70)
    seekerBar.roundCorner(radius: 2, cornerCurve: .continuous)
    seekerBar.isUserInteractionEnabled = false
  }
  
  func observeTimer() {
    composition.timeSubject
      .receive(on: DispatchQueue.main)
      .sink { timeInterval in
        self.thumbnailsVC.scrollTime(to: timeInterval)
      }.store(in: &self.subscriptions)
  }
  
  func subscribeToDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayStep))
    displayLink.isPaused = false
    displayLink.add(to: .main, forMode: .common)
    spliceState = .neutral
  }
  
  @objc func displayStep(_ displaylink: CADisplayLink) {
    switch spliceState {
    case .including:
      let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
//      currentFps = actualFramesPerSecond.rounded()
//      intervalsVC.expand(from:  rate: advanceRate)
    default: break
    }
    if scrubbingState == .notScrubbing {
      delegate?.synchronizePlaybackTime()
    }
  }
  
  func appearIncluding() {
    view.isUserInteractionEnabled = false
    seekerBar.alpha = 0.4
  }
  
  func appearNeutral() {
    view.isUserInteractionEnabled = true
    seekerBar.alpha = 0.8
  }
  
  func renderFreshAssets() {
    thumbnailsVC.renderFreshAssets()
    intervalsVC.composition = composition
    intervalsVC.renderFreshAssets()
//    scrubber.maximumValue = Float(composition.totalDuration)
//    scrubber.setNeedsLayout()
//    scrubber.layoutIfNeeded()
//
//    segmentsVC.composition = composition
//    segmentsVC.renderFreshAssets()
//
//    waveVC.composition = composition
//    waveVC.renderFreshAssets()

  }
  
  func startExpandingSegment(startTime: TimeInterval) {
    spliceState = .including(startTime)
    if let delegate = delegate {
      intervalsVC.startExpandingInterval(startTime: delegate.currentTimeForDisplay())
    }
    intervalsVC.deselectIntervals()
  }
  
  func expandingSegment() -> UIView? {
    return UIView()
  }
  
  func firstSegment() -> UIView? {
    return UIView()
  }
  
  func stopExpandingSegment() {
    spliceState = .neutral
    intervalsVC.stopExpandingInterval()
    
  }
  
  func updateSegmentsForSplices() {
    intervalsVC.updateIntervalsForSplices()
  }
  
}

extension TimelineScroller: ThumbnailsViewControllerDelegate {
  func thumbnailsVCDidRefreshThumbnails(contentSize: CGSize) {
    intervalsVC.setFrame(CGRect(origin: .zero, size: contentSize))
    waveScrollView.contentInset = thumbnailsVC.scrollView.contentInset
    waveVC.addWaveform(width: contentSize.width)
  }
  
  func thumbnailsVCWillBeginDragging(_ thumbnailsVC: ThumbnailsViewController) {
    scrubbingState = .scrubbing
    delegate?.timelineVCWillBeginScrubbing()
    intervalsVC.deselectIntervals()
  }
  
  func thumbnailsVCDidEndDragging(_ thumbnailsVC: ThumbnailsViewController) {
    scrubbingState = .notScrubbing
    delegate?.timelineVCDidFinishScrubbing()
  }
  
  func thumbnailsVCDidScroll(_ thumbnailsVC: ThumbnailsViewController, to time: TimeInterval) {
    // send scrub event only if user initiated.
    if thumbnailsVC.scrollView.isDragging {
      delegate?.scrubberScrubbed(to: time)
    }
    waveScrollView.contentOffset = thumbnailsVC.scrollView.contentOffset
  }
  
}

extension TimelineScroller: IntervalsViewControllerDelegate {
  func intervalsVCDidSelectSegment(at index: Int) {
    let alertController = UIAlertController(title: "Remove Splice?", message: "Don't worry, you can just add it again. To remove splices faster, swipe up on the segment.", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
      self.deleteInterval(at: index)
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      
    }))
    present(alertController, animated: true, completion: nil)
  }
  
  func intervalsVCDidSwipeUpSegment(at index: Int) {
    deleteInterval(at: index)
  }
  
  func deleteInterval(at index: Int) {
    composition.removeSplice(at: index)
    intervalsVC.updateIntervalsForSplices()
    delegate?.timelineVCDidDeleteSegment()
  }
  
  
}
