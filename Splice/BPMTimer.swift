// https://newbedev.com/swift-solid-metronome-system
import Foundation

protocol BPMTimerDelegate: AnyObject {
  func bpmTimerTicked()
}

class BPMTimer {
  
  // MARK: - Properties
  
  weak var delegate: BPMTimerDelegate? // The class's delegate, to handle the results of ticks
  var bpm: Double { // The speed of the metronome ticks in BPM (Beats Per Minute)
    didSet {
      changeBPM() // Respond to any changes in BPM, so that the timer intervals change accordingly
    }
  }
  var tickDuration: Double { // The amount of time that will elapse between ticks
    return 60/bpm
  }
  var timeToNextTick: Double { // The amount of time until the next tick takes place
    if paused {
      return tickDuration
    } else {
      return abs(elapsedTime - tickDuration)
    }
  }
  var percentageToNextTick: Double { // Percentage progress from the previous tick to the next
    if paused {
      return 0
    } else {
      return min(100, (timeToNextTick / tickDuration) * 100) // Return a percentage, and never more than 100%
    }
  }
  
  // MARK: - Private Properties
  
  private var timer: DispatchSourceTimer!
  private lazy var timerQueue = DispatchQueue.global(qos: .utility) // The Grand Central Dispatch queue to be used for running the timer. Leverages a global queue with the Quality of Service 'Utility', which is for long-running tasks, typically with user-visible progress. See here for more info: https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2
  private var paused: Bool
  private var lastTickTimestamp: CFAbsoluteTime
  private var tickCheckInterval: Double {
    return tickDuration / 50 // Run checks many times within each tick duration, to ensure accuracy
  }
  private var timerTolerance: DispatchTimeInterval {
    return DispatchTimeInterval.milliseconds(Int(tickCheckInterval / 10 * 1000)) // For a repeating timer, Apple recommends a tolerance of at least 10% of the interval. It must be multiplied by 1,000, so it can be expressed in milliseconds, as required by DispatchTimeInterval.
  }
  private var elapsedTime: Double {
    return CFAbsoluteTimeGetCurrent() - lastTickTimestamp // Determine how long has passed since the last tick
  }
  
  // MARK: - Initialization
  
  init(bpm: Double) {
    
    self.bpm = bpm
    self.paused = true
    self.lastTickTimestamp = CFAbsoluteTimeGetCurrent()
    self.timer = createNewTimer()
  }
  
  // MARK: - Methods
  
  func start() {
    
    if paused {
      paused = false
      lastTickTimestamp = CFAbsoluteTimeGetCurrent()
      timer.resume() // A crash will occur if calling resume on an already resumed timer. The paused property is used to guard against this. See here for more info: https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9
    } else {
      // Already running, so do nothing
    }
  }
  
  func stop() {
    
    if !paused {
      paused = true
      timer.suspend()
    } else {
      // Already paused, so do nothing
    }
  }
  
  // MARK: - Private Methods
  
  // Implements timer functionality using the DispatchSourceTimer in Grand Central Dispatch. See here for more info: http://danielemargutti.com/2018/02/22/the-secret-world-of-nstimer/
  private func createNewTimer() -> DispatchSourceTimer {
    
    let timer = DispatchSource.makeTimerSource(queue: timerQueue) // Create the timer on the correct queue
    let deadline: DispatchTime = DispatchTime.now() + tickCheckInterval // Establish the next time to trigger
    timer.schedule(deadline: deadline, repeating: tickCheckInterval, leeway: timerTolerance) // Set it on a repeating schedule, with the established tolerance
    timer.setEventHandler { [weak self] in // Set the code to be executed when the timer fires, using a weak reference to 'self' to avoid retain cycles (memory leaks). See here for more info: https://learnappmaking.com/escaping-closures-swift/
      self?.tickCheck()
    }
    timer.activate() // Dispatch Sources are returned initially in the inactive state, to begin processing, use the activate() method
    
    // Determine whether to pause the timer
    if paused {
      timer.suspend()
    }
    
    return timer
  }
  
  private func cancelTimer() {
    
    timer.setEventHandler(handler: nil)
    timer.cancel()
    if paused {
      timer.resume() // If the timer is suspended, calling cancel without resuming triggers a crash. See here for more info: https://forums.developer.apple.com/thread/15902
    }
  }
  
  private func replaceTimer() {
    
    cancelTimer()
    timer = createNewTimer()
  }
  
  private func changeBPM() {
    
    replaceTimer() // Create a new timer, which will be configured for the new BPM
  }
  
  @objc private func tickCheck() {
    
    if (elapsedTime > tickDuration) || (timeToNextTick < 0.003) { // If past or extremely close to correct duration, tick
      tick()
    }
  }
  
  private func tick() {
    
    lastTickTimestamp = CFAbsoluteTimeGetCurrent()
    DispatchQueue.main.sync { // Calls the delegate from the application's main thread, because it keeps the separate threading within this class, and otherwise, it can cause errors (e.g. 'Main Thread Checker: UI API called on a background thread', if the delegate tries to update the UI). See here for more info: https://stackoverflow.com/questions/45081731/uiapplication-delegate-must-be-called-from-main-thread-only
      delegate?.bpmTimerTicked() // Have the delegate respond accordingly
    }
  }
  
  // MARK: - Deinitialization
  
  deinit {
    
    cancelTimer() // Ensure that the timer's cancelled if this object is deallocated
  }
}
