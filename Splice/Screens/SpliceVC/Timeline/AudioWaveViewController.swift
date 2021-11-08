//
//  AudioWaveViewController.swift
//  Shorten
//
//  Created by June Kim on 11/2/21.
//

import Foundation
import UIKit
import AVFoundation

class AudioWaveViewController: UIViewController {
  unowned var composition: SpliceComposition
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addWaveform()
  }
  
  func renderFreshAssets() {
    for subview in view.subviews {
      subview.removeFromSuperview()
    }
    addWaveform()
  }
  
  func addWaveform() {
    let targetTotalWidth = UIScreen.main.bounds.width - UIView.defaultEdgeMargin * 2
    var runX: CGFloat = 0
    for eachAsset in composition.assets {
      let thisWidth = targetTotalWidth * eachAsset.duration.seconds / composition.totalDuration
      let waveformImageView = UIImageView(frame: CGRect(
        x: runX, y: 0,
        width: thisWidth,
        height: 50))
      runX += thisWidth
      
      let waveformImageDrawer = WaveformImageDrawer()
      let waveConfig = Waveform.Configuration(
        size: waveformImageView.size,
        backgroundColor: .clear,
        style: .striped(.init(color: .systemOrange.withAlphaComponent(0.4), width: 3, spacing: 2, lineCap: .round)),
        dampening: nil,
        position: .bottom,
        scale: 1,
        verticalScalingFactor: 1,
        shouldAntialias: false)
      waveformImageDrawer.waveformImage(fromAudioAt: (eachAsset as! AVURLAsset).url,
                                        with: waveConfig) { waveformImage in
        DispatchQueue.main.async {
          waveformImageView.image = waveformImage
        }
      }
      view.addSubview(waveformImageView)
    }
  }
}
