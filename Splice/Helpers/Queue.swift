//
//  Queue.swift
//   Sequence
//
//  Created by June Kim on 9/19/21.
//

import Foundation

struct Queue<T> {
  private var elements: [T] = []
  
  mutating func enqueue(_ value: T) {
    elements.append(value)
  }
  
  mutating func dequeue() -> T? {
    guard !elements.isEmpty else {
      return nil
    }
    return elements.removeFirst()
  }
  
  var head: T? {
    return elements.first
  }
  
  var tail: T? {
    return elements.last
  }
  
  var isEmpty: Bool {
    return elements.isEmpty
  }
  
  mutating func empty() {
    while !isEmpty {
      _ = dequeue()
    }
  }
  
  func peek() -> T? {
    return elements.first
  }
}
