//
//  TimelineScroller.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit
import Combine

class TimelineScrollViewController: UIViewController, TimelineControl {
  static let defaultHeight: CGFloat = 80
  var delegate: TimelineControlDelegate?
  unowned var composition: SpliceComposition
  var scrubbingState: ScrubbingState = .notScrubbing {
    didSet {
      if scrubbingState != oldValue {
        delegate?.scrubbingStateChanged(scrubbingState)
      }
    }
  }
  var thumbnailsVC: ThumbnailsViewController!
  var intervalsVC: IntervalsViewController!
  var currentlySelectedIndex: Int? {
    return intervalsVC.currentlySelectedIndex
  }
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
    thumbnailsVC.view.pinBottomToParent()
    thumbnailsVC.view.fillWidthOfParent()
    thumbnailsVC.view.set(height: ThumbnailsViewController.defaultHeight)
    thumbnailsVC.didMove(toParent: self)
  }
  
  func addIntervalsVC() {
    intervalsVC.delegate = self
    // !!
    addChild(intervalsVC)
    thumbnailsVC.scrollView.addSubview(intervalsVC.view)
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
    waveScrollView.showsHorizontalScrollIndicator = false
    waveVC.addWaveform(width: thumbnailsVC.contentWidth)
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
        if self.scrubbingState == .notScrubbing {
          self.thumbnailsVC.scrollTime(to: timeInterval)
        }
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
    case .including: break
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
  
  func appearLooping(at index: Int) {
    // TODO
  }
  
  func renderFreshAssets() {
    thumbnailsVC.renderFreshAssets()
    intervalsVC.composition = composition
    intervalsVC.renderFreshAssets()
    waveVC.composition = composition
    waveVC.addWaveform(width: thumbnailsVC.contentWidth)
  }
  
  func startExpandingSegment(startTime: TimeInterval) {
    spliceState = .including(startTime)
    thumbnailsVC.scrollView.stopDecelerating()
    if let delegate = delegate {
      intervalsVC.startExpandingInterval(startTime: delegate.currentTimeForDisplay())
    }
    intervalsVC.deselectIntervals()
  }
  
  func expandingInterval() -> UIView? {
    return intervalsVC.expandingInterval
  }
  
  func firstInterval() -> UIView? {
    return intervalsVC.intervals.first
  }
  
  func stopExpandingSegment() {
    spliceState = .neutral
    intervalsVC.stopExpandingInterval()
    
  }
  
  func updateSegmentsForSplices() {
    intervalsVC.updateIntervalsForSplices()
  }
  
  func scrubbingIntervalIndex() -> Int? {
    let timePosition = thumbnailsVC.currentTimePosition(thumbnailsVC.scrollView)
    return composition.splices.firstIndex { splice in
      return splice.lowerBound < timePosition && splice.upperBound > timePosition
    }
  }
  
  func showDeleteAlert(for index: Int) {
    let alertController = UIAlertController(title: "Remove Splice?", message: "Don't worry, you can just add it again. To remove splices faster, swipe up on the segment.", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
      self.deleteInterval(at: index)
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      
    }))
    present(alertController, animated: true, completion: nil)
  }
}

extension TimelineScrollViewController: ThumbnailsViewControllerDelegate {
  func thumbnailsVCDidRefreshAThumbnail() {
    intervalsVC.setFrame(CGRect(origin: .zero, size: thumbnailsVC.imageViewsContainer.size))
  }
  
  func thumbnailsVCWillRefreshThumbnails(contentSize: CGSize) {
    waveScrollView.contentInset = thumbnailsVC.scrollView.contentInset
//    waveVC.addWaveform(width: thumbnailsVC.contentWidth)
    intervalsVC.setFrame(CGRect(origin: .zero, size: contentSize))
  }
  
  func thumbnailsVCWillBeginDragging(_ thumbnailsVC: ThumbnailsViewController) {
    scrubbingState = .scrubbing(scrubbingIntervalIndex())
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
      scrubbingState = .scrubbing(scrubbingIntervalIndex())
      intervalsVC.setSelected(intervalIndex: scrubbingIntervalIndex())
    }
    waveScrollView.contentOffset = thumbnailsVC.scrollView.contentOffset
  }
  
}

extension TimelineScrollViewController: IntervalsViewControllerDelegate {
  func timelineSize() -> CGSize {
    return CGSize(width: thumbnailsVC.contentWidth, height: ThumbnailsViewController.defaultHeight)
  }
  
  func intervalsVCDidSelectInterval(at index: Int) {
    // midpoint
    let targetTime = (composition.splices[index].upperBound - composition.splices[index].lowerBound) / 2 + composition.splices[index].lowerBound
    thumbnailsVC.scrollTime(to: targetTime, animated: true)
    // simulate instant scrolling to the target time
    delegate?.scrubberScrubbed(to: targetTime)

    // TODO: find out if needed
    //    scrubbingState = .scrubbing(index)
    delegate?.timelineVCDidTapSelectInterval(at: index)
  }
  
  func intervalsVCDidSwipeUpInterval(at index: Int) {
    deleteInterval(at: index)
  }
  
  func deleteInterval(at index: Int) {
    composition.removeSplice(at: index)
    intervalsVC.updateIntervalsForSplices()
    delegate?.timelineVCDidDeleteSegment()
  }
  
  
}
