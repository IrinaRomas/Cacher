import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

struct Entry: Codable {
    let key: String
    let value: Data
    let expirationDate: Date
    let createdDate: Date
    
    init(key: String, value: Data, expirationDate: Date, createdDate: Date) {
        self.key = key
        self.value = value
        self.expirationDate = expirationDate
        self.createdDate = createdDate
    }
}

class CacheLib {
    
    private var urlString = ""
    private var value = Data()
    private var expirationDate: Date
    private var nameDirectory = "PPL_Cache"
    private var key = ""
    private var isLog = false
    private var path: String?
    
    init(entryLifetime: TimeInterval, isLog: Bool, path: String? = nil) {
        let expirationDate = Calendar.current.date(byAdding: .second, value: Int(entryLifetime), to: Date())
        self.expirationDate = expirationDate ?? Date()
        self.isLog = isLog
        self.path = path
    }
    
    func cachedResponse(for request: URLRequest) -> Data? {
        removeCachedResponses(by: Date())
        urlString = request.url?.absoluteString ?? ""
        key = getKey()
        
        guard let file = findFileInCache() else { return nil }
        
        let data = FileManager.default.decodeJSON(type: Entry.self, with: file, path: path, isLog: isLog)
        return data?.value
    }
    
    func storeCachedResponse(data: Data) {
        value = data
        let entry = createEntry()
        guard let filePath = FileManager.default.getFileFromCacheDirectory(nameDirectory, with: getNameFile(), isLog: isLog) else { return }
        FileManager.default.saveJSONFile(entry, jsonFilePath: filePath, isLog: isLog)
    }
    
    func removeAllCachedResponses() {
        FileManager.default.removeAllFilesInFolder(for: .cachesDirectory, nameDirectory: nameDirectory)
    }
}

//MARK: - Private func
extension CacheLib {
    private func findFileInCache() -> URL? {
        
        guard let files = FileManager.default.urls(for: .cachesDirectory, nameDirectory: nameDirectory) else { return nil }
        for file in files {
            var keyFromNameFile = file.lastPathComponent
            if let index = keyFromNameFile.index(of: "__") {
                let substring = keyFromNameFile[..<index]
                keyFromNameFile = String(substring)
                
                if keyFromNameFile == key {
                    return file.absoluteURL
                }
            }
        }
        return nil
    }
    
    private func createEntry() -> Entry {
        return Entry(key: key, value: value, expirationDate: expirationDate, createdDate: Date())
    }
    
    private func getFileInCache() -> URL?{
        return FileManager.default.getFileFromCacheDirectory(nameDirectory, with: getNameFile(), isLog: isLog)
    }
    
    private func getNameFile() -> String {
        return "\(key)__\(expirationDate.toString(dateFormat: "yyyyMMddHHmmss"))"
    }
    
    private func getKey() -> String {
        let md5Data = MD5(string: urlString)
        let md5Hex =  md5Data.map { String(format: "%02hhx", $0) }.joined()
        return md5Hex
    }
    
    private func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
    
    private func removeCachedResponses(by date: Date) {
        guard let files = FileManager.default.urls(for: .cachesDirectory, nameDirectory: nameDirectory) else { return }
        
        for file in files {
            var dateFromNameFile = file.lastPathComponent
            let index = dateFromNameFile.index(dateFromNameFile.endIndex, offsetBy: -14)
            let substring = dateFromNameFile[index...]
            dateFromNameFile = String(substring)
            
            if let expDate = dateFromNameFile.toDate(dateFormat: "yyyyMMddHHmmss"), expDate <= date {
                FileManager.default.deleteFile(filePath: file, isLog: isLog)
            }
        }
    }
}


