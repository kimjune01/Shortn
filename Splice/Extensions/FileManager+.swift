//
//  FileManager+.swift
//   Sequence
//
//  Created by June Kim on 9/8/21.
//

import Foundation

extension FileManager {
  func moveItemToDocumentsDirectory(from sourceUrl: URL, sessionID: SequenceIdentifier, uuid: UUID, pathExtension: String) {
    let manager = FileManager.default
    guard manager.fileExists(atPath: sourceUrl.path) else {
      print("file does not exist at source")
      return
    }
    do {
      try manager.moveItem(at: sourceUrl,
                           to: documentsDirectory(sessionID: sessionID, uuid: uuid, pathExtension: pathExtension))
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func documentsDirectory(prefix: String, pathComponent: String) throws -> URL  {
    let manager = FileManager.default
    do {
      // Get documents directory
      guard var documentsDirectory = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        assert(false, "you got bigger problems")
        fatalError()
      }
      func makeFolder() throws {
        if !manager.fileExists(atPath: documentsDirectory.path) {
          try manager.createDirectory(atPath: documentsDirectory.path,
                                      withIntermediateDirectories: true,
                                      attributes: nil)
        }
      }
      documentsDirectory = documentsDirectory.appendingPathComponent(prefix)
      try makeFolder()
      return documentsDirectory.appendingPathComponent(pathComponent)
    }
  }
  
  func documentsDirectory(sessionID: SequenceIdentifier, uuid: UUID, pathExtension: String) throws -> URL  {
    let manager = FileManager.default
    do {
      // Get documents directory
      guard let documentsDirectory = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        assert(false, "you got bigger problems")
        fatalError()
      }
      let sessionDirectory = documentsDirectory
        .appendingPathComponent("\(sessionID.folderName)")
      
      // Make new folder if needed
      if !manager.fileExists(atPath: sessionDirectory.path) {
        try manager.createDirectory(atPath: sessionDirectory.path,
                                    withIntermediateDirectories: true,
                                    attributes: nil)
      }
      
      // Named with uuid
      let fileDirectory = sessionDirectory
        .appendingPathComponent("\(uuid.uuidString.components(separatedBy: "-").last!)")
        .appendingPathExtension(pathExtension)
      
      // Return the file name
      return fileDirectory
    }
  }
  
  func cleanUpOldTempFiles() {
    let temporaryUrl =  temporaryDirectory
    
    do {
      // Get the directory contents urls (including subfolders urls)
      let temporaryContents = try contentsOfDirectory(at: temporaryUrl, includingPropertiesForKeys: nil)
      print("\(temporaryContents.count) files in temp directory")
      for contentUrl in temporaryContents {
        guard fileExists(atPath: contentUrl.path) else { continue }
        let attr = try attributesOfItem(atPath: contentUrl.path)
        let creationDate = attr[.creationDate] as? Date
        // set stale clock to 2 hours
        if let created = creationDate, abs(created.timeIntervalSinceNow) > 2 * 3600  {
          // stale. delete!
          print("deleting file at \(contentUrl.lastPathComponent)")
          try removeItem(at: contentUrl)
        }
      }
      
    } catch {
      print(error)
    }
  }
  
}
