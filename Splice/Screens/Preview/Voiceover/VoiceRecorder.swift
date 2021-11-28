//
//  VoiceRecorder.swift
//  Shortn
//
//  Created by June Kim on 11/28/21.
//

import AVFoundation

protocol VoiceRecorderDelegate: AnyObject {
  func voiceRecorderDidFinishRecording(to url: URL)
}

// a recorder that can also playback audio at any time.
class VoiceRecorder: NSObject {
  unowned var composition: SpliceComposition
  weak var delegate: VoiceRecorderDelegate?
  private var recordingSession: AVAudioSession!
  private var audioRecorder: AVAudioRecorder!
  private let voicesPlayer = QueuePlayer()
  var tempUrl: URL?

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init()
  }
  
  func makeTempUrl() -> URL {
    return FileManager
      .default
      .temporaryDirectory
      .appendingPathComponent("\(UUID().shortened())")
      .appendingPathExtension(".m4a")
  }

  // should not need starting time because the duration of the previous segments should sum up to start time.
  // may be out of sync, but that's ok for this level of precision.
  func startRecording() {
    print("VoiceRecorder startRecording")
    do {
      try recordingSession.setCategory(.playAndRecord, mode: .default)
      try recordingSession.setActive(true)
      tempUrl = makeTempUrl()
      audioRecorder = try AVAudioRecorder(url: tempUrl!, settings: defaultSettings())
      audioRecorder.delegate = self
      audioRecorder.record()
    } catch {
      print("startRecordingWithAnimation error: ", error.localizedDescription)
    }
  }
  
  func defaultSettings() -> [String: Any] {
    return [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: 44100.0 as Float,
      AVNumberOfChannelsKey: 1
    ]
  }
  // TODO: manage audio session
  
  func stopRecording() {
    guard audioRecorder != nil else { return }
    audioRecorder.stop()
  }
  
  // enqueues the remaining audio segments from time.
  func play(at time: TimeInterval) {
    guard composition.voiceSegments.count > 0 else { return }
    var remainingTime = time
    var targetIndex = 0
    var targetSegment = composition.voiceSegments[0]
    while remainingTime > 0 {
      targetSegment = composition.voiceSegments[targetIndex]
      if targetSegment.duration.seconds > remainingTime {
        break
      }
      remainingTime -= targetSegment.duration.seconds
      targetIndex += 1
    }
    let remainingSegments = composition.voiceSegments[targetIndex..<composition.voiceSegments.count]
    let urls = remainingSegments.map{$0.url}
    voicesPlayer.enqueue(urls)
    voicesPlayer.seek(to: remainingTime)
    voicesPlayer.play()
  }
  
  func pause() {
    voicesPlayer.pause()
  }
}

extension VoiceRecorder: AVAudioRecorderDelegate{
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    guard flag else { print("audioRecorderDidFinishRecording fail!"); return }
    guard let url = tempUrl, let delegate = delegate else { return }
    delegate.voiceRecorderDidFinishRecording(to: url)
  }
}
