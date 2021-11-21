//
//  Thumbnail.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit

class Thumbnail: NSObject {
  let uuid = UUID()
  let image: UIImage
  let widthPortion: CGFloat // from 0 to 1, indicating the width
  
  init(_ img: UIImage, widthPortion: CGFloat) {
    self.image = img
    self.widthPortion = widthPortion
  }
}
