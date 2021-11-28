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
  weak var delegate: VoiceRecorderDelegate?
  private var recordingSession: AVAudioSession!
  private var audioRecorder: AVAudioRecorder!
  private let segmentsPlayer = QueuePlayer()
  var tempUrl: URL?

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
}

extension VoiceRecorder: AVAudioRecorderDelegate{
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    guard flag else { print("audioRecorderDidFinishRecording fail!"); return }
    guard let url = tempUrl, let delegate = delegate else { return }
    delegate.voiceRecorderDidFinishRecording(to: url)
  }
}
