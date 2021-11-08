// https://stackoverflow.com/questions/10720569/is-there-a-way-to-calculate-the-cgaffinetransform-needed-to-transform-a-view-fro

import Foundation
import CoreGraphics

extension CGAffineTransform {
  static func fit(from source: CGRect, to destination: CGRect) -> CGAffineTransform{
    let A = source
    let B = destination
    var transform = CGAffineTransform.identity.translatedBy(x: -A.origin.x, y: -A.origin.y)
    transform = transform.scaledBy(x: 1/A.size.width, y: 1/A.size.height)
    transform = transform.scaledBy(x: B.size.width, y: B.size.height)
    transform = transform.translatedBy(x: B.origin.x, y: B.origin.y)
    return transform
  }
}
