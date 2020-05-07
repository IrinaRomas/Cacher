//
//  FileManager + Extension.swift
//  pickpointlib
//
//  Created by Irina Romas on 21.04.2020.
//  Copyright © 2020 Irina Romas. All rights reserved.
//

import Foundation

extension FileManager {
    
    func getDirectoryPath(typeDirecory: FileManager.SearchPathDirectory, nameDirectory: String) -> URL
    {
        // path is main document directory path
        let fileManager = FileManager.default
        let documentDirectoryPath = try! FileManager.default.url(for: typeDirecory, in: .userDomainMask, appropriateFor: nil, create: true)
        var pathWithFolderName = documentDirectoryPath.appendingPathComponent(nameDirectory)
        if !fileManager.fileExists(atPath: pathWithFolderName.path)
        {
            do {
                try fileManager.createDirectory(at: pathWithFolderName, withIntermediateDirectories: true, attributes: nil)
                pathWithFolderName = documentDirectoryPath.appendingPathComponent(nameDirectory)
            } catch let error {
                fatalError("Unable to create directory cache: \(error)")
            }
        }
        
        return pathWithFolderName
    }
    
    func getFileFromCacheDirectory(_ nameDirectory: String, with nameFile: String, isLog: Bool = false) -> URL? {
        let fileManager = FileManager.default
        
        let filePath = (getDirectoryPath(typeDirecory: .cachesDirectory, nameDirectory: nameDirectory) as NSURL).appendingPathComponent(nameFile)
        
        let urlString: String = filePath!.path
        
        if !fileManager.fileExists(atPath: urlString)
        {
            if isLog {
                print("PPL_No file Found: ", urlString)
            }
            
            let created = fileManager.createFile(atPath: urlString, contents: nil, attributes: nil)
            if created {
                if isLog {
                    print("PPL_File created: ", urlString)
                }
            } else {
                if isLog {
                    print("PPL_Couldn't create file \(urlString) for some reason")
                }
                return nil
            }
        }
        return filePath
    }
    
    func decodeJSON<T: Decodable>(type: T.Type, with jsonFilePath: URL, path: String? = nil, isLog: Bool = false) -> T? {
        
        var jsonData = Data()
        do {
            jsonData = try Data(contentsOf: jsonFilePath)
        } catch {
            if isLog {
                print(error)
            }
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(T.self, from: jsonData, path: path)
            return decoded
        } catch {
            if isLog {
                print(error)
            }
            return nil
        }
    }
    
    func saveJSONFile<T: Encodable>(_ data: T, jsonFilePath: URL, isLog: Bool = false) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            try encodedData.write(to: jsonFilePath)
        }
        catch {
            if isLog {
                print("PPL_Failed to write JSON data: \(error.localizedDescription) ", error)
            }
        }
    }
    
    func urls(for directory: FileManager.SearchPathDirectory, nameDirectory: String, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let directoryURL = getDirectoryPath(typeDirecory: directory, nameDirectory: nameDirectory)
        let fileURLs = try? contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
    
    func removeAllFilesInFolder(for directory: FileManager.SearchPathDirectory, nameDirectory: String, isLog: Bool = false) {
        let fileManager = FileManager.default
        let directoryURL = getDirectoryPath(typeDirecory: directory, nameDirectory: nameDirectory)
        do {
            let filePaths = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
            for filePath in filePaths {
                try fileManager.removeItem(at: filePath)
            }
        } catch {
            if isLog {
                print("PPL_Could not clear folder: \(error)")
            }
        }
    }
    
    func deleteFile(filePath: URL, isLog: Bool = false) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: filePath)
            
        } catch {
            if isLog {
                print("Could not delete file: \(error)")
            }
        }
    }
}
