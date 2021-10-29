//
//  UIImage+.swift
//   Sequence
//
//  Created by June Kim on 9/12/21.
//

import UIKit

// https://www.advancedswift.com/resize-uiimage-no-stretching-swift/
extension UIImage {
  func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
    // Determine the scale factor that preserves aspect ratio
    let widthRatio = targetSize.width / size.width
    let heightRatio = targetSize.height / size.height
    
    let scaleFactor = min(widthRatio, heightRatio)
    
    // Compute the new image size that preserves aspect ratio
    let scaledImageSize = CGSize(
      width: size.width * scaleFactor,
      height: size.height * scaleFactor
    )
    
    // Draw and return the resized UIImage
    let renderer = UIGraphicsImageRenderer(
      size: scaledImageSize
    )
    
    let scaledImage = renderer.image { _ in
      self.draw(in: CGRect(
        origin: .zero,
        size: scaledImageSize
      ))
    }
    
    return scaledImage
  }
}
