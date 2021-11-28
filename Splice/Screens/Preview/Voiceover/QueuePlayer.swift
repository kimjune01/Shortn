//
//  QueuePlayer.swift
//  Sequence
//
//  Created by June Kim on 10/2/21.
//

import AVKit

protocol QueuePlayerDelegate: AnyObject {
  func queuePlayerPlayingNext(_ url: URL)
  func queuePlayerFinishedPlaying()
}

class QueuePlayer: NSObject {
  weak var delegate: QueuePlayerDelegate?
  var queue = Queue<URL>()
  private var audioPlayer: AVAudioPlayer?
  var volume: Float = 1.0
  
  func enqueue(_ items: [URL]) {
    for item in items {
      queue.enqueue(item)
    }
  }
  
  func play() {
    if queue.isEmpty { return }
    guard let url = queue.dequeue() else {
      return
    }
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
      audioPlayer = try AVAudioPlayer(contentsOf: url)
      audioPlayer!.volume = volume
    } catch {
      // this thing doesnt play remote assets
      print("QueuePlayer error: ", error)
      return
    }
    guard let player = audioPlayer else {
      return
    }
    player.delegate = self
    player.play()
  }
  
  func stop() {
    audioPlayer?.stop()
    queue.empty()
  }
  
  func pause() {
    audioPlayer?.pause()
  }
  
  func seek(to time: TimeInterval) {
    audioPlayer?.play(atTime: time)
  }
  
  func resume() {
    audioPlayer?.play()
  }
}

extension QueuePlayer: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if let next = queue.peek() {
      delegate?.queuePlayerPlayingNext(next)
    } else {
      delegate?.queuePlayerFinishedPlaying()
    }
    play()
  }
}
