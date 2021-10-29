//
//  PlayerView.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import UIKit
import AVFoundation

/// A view that displays the visual contents of a player object.
class PlayerView: UIView {
  
  // Override the property to make AVPlayerLayer the view's backing layer.
  override static var layerClass: AnyClass { AVPlayerLayer.self }
  
  // The associated player object.
  var player: AVPlayer? {
    get { playerLayer.player }
    set { playerLayer.player = newValue }
  }
  
  private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
  
}
