//
//  VideoCache.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/10/14.
//

import Foundation
//import Alamofire
import SDWebImage
//import Cache

protocol CacheProtocol {
    func cachePath(forKey key: String) -> String?
    
    func setData(_ data: Data?, forKey key: String)
    
    func data(forKey key: String) -> Data?
    
    func removeData(forKey key: String)
    
    func removeAllData()
}

/// Cache remote videos, expired in 3 days
public class VideoCache {
    // Cache framework
//    private static let storageDiskConfig = DiskConfig(name: "VideoReourceCache", expiry: .seconds(3600*24*3))
//    private static let storageMemoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
//    private static let storage = try? Storage.init(diskConfig: VideoCache.storageDiskConfig, memoryConfig: VideoCache.storageMemoryConfig, transformer: TransformerFactory.forData())
    
    // SDWebImage framework
    static var sdDiskConfig: SDImageCacheConfig  {
        let config = SDImageCacheConfig()
        config.diskCacheExpireType = .accessDate
        config.maxDiskSize = 1024 * 1024 * 512 // 500M
        return config
    }
    
    static var videoCacheTmpDirectory: URL? {
        return try? FileManager.tempDirectory(with: "FYPhotoVideoCache")
    }
    
    static var diskCache: SDDiskCache? {
        if let temp = videoCacheTmpDirectory {
            #if DEBUG
            print("Video cached path: \(temp.path)")
            #endif
            return SDDiskCache(cachePath: temp.path, config: sdDiskConfig)
        } else {
            return nil
        }
    }
    
    private static let movieTypes: [String] = ["mp4", "m4v", "mov"]
    
    public static let shared: VideoCache? = VideoCache()
    
    private var cache: CacheProtocol?
    
    // request
    private var activeTaskMap: [URL: URLSessionDataTask] = [:]
    private let underlyingQueue = DispatchQueue(label: "com.fyphoto.underlyingQueue")
    private let requestQueue = DispatchQueue(label: "com.fyphoto.requestQueue")
    
    private init?(cache: CacheProtocol? = VideoCache.diskCache) {
        self.cache = cache
    }
    
    public func clearAll() {
        cache?.removeAllData()
    }
    
    public func removeData(forKey key: URL) {
        let cKey = getCacheKey(with: key)
        cache?.removeData(forKey: cKey)
        
    }
    
    public func save(data: Data, key: URL) {
        let cKey = getCacheKey(with: key)
        cache?.setData(data, forKey: cKey)
    }
    
    public func fetchDataWith(key: URL, completion: @escaping ((Swift.Result<Data, Error>) -> Void)) {
        let cKey = getCacheKey(with: key)
        if let data = cache?.data(forKey: cKey) {
            completion(.success(data))
        } else {
            request(key) { (result: Result<Data, Error>) in
                switch result {
                case .success(let data):
                    self.save(data: data, key: key)
                    completion(.success(data))
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    fileprivate func request(_ url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        if let task = activeTaskMap[url] {
            task.cancel()
            activeTaskMap[url] = nil
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                self.removeTask(url)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            if let _url = httpResponse.url {
                self.removeTask(_url)
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let data = data {
                    DispatchQueue.main.async {
                        completion(.success(data))
                    }
                }
            } else {
                let domain = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                let error = NSError(domain: domain, code: httpResponse.statusCode, userInfo: nil)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        activeTaskMap[url] = task
    }
    
    public func fetchFilePathWith(key: URL, completion: @escaping ((Swift.Result<URL, Error>) -> Void)) {
        guard !key.isFileURL else {
            completion(.success(key))
            return
        }
        guard let cache = cache else { return }
        
        // Use the code below to get the real video suffix.
        // "http://client.gsup.sichuanair.com/file.php?9bfc3b16aec233d025c18042e9a2b45a.mp4", this url will get `php` as it's path extension
        let keyString = getCacheKey(with: key)
                        
        if cache.data(forKey: keyString) != nil,
           let filePath = cache.cachePath(forKey: keyString) {
            let url = URL(fileURLWithPath: filePath)
            completion(.success(url))
        } else {
            request(key) { (result: Result<Data, Error>) in
                switch result {
                case .success(let data):
                    self.save(data: data, key: key)
                    if let path = cache.cachePath(forKey: keyString),
                       FileManager.default.fileExists(atPath: path) {
                        let url = URL(fileURLWithPath: path)
                        DispatchQueue.main.async {
                            completion(.success(url))
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func cancelAllTask(completingOnQueue queue: DispatchQueue = .main, completion: (() -> Void)? = nil) {
        underlyingQueue.async {
            self.activeTaskMap.values.forEach { $0.cancel() }
            queue.async {
                completion?()
            }
        }
    }
    
    func getCacheKey(with url: URL) -> String {
        let pathExtension = url.pathExtension
        if VideoCache.movieTypes.contains(pathExtension) {
            return url.lastPathComponent
        } else {
            let fileURL = URL(fileURLWithPath: url.absoluteString)
            let filePathExtension = fileURL.pathExtension
            if VideoCache.movieTypes.contains(filePathExtension) {
                return url.query ?? url.absoluteString
            } else {
                return url.absoluteString
            }
        }
    }
    
    func handleServerError(_ response: URLResponse) {
        print("fetch video failed with system error response: \(response)")
    }
    
    func removeTask(_ url: URL) {
        activeTaskMap[url] = nil
    }
}


extension SDDiskCache: CacheProtocol {
}

//extension Storage: CacheProtocol where T == Data {
//    func setData(_ data: Data?, forKey key: String) {
//        guard let data = data else { return }
//        do {
//            try setObject(data, forKey: key)
//        } catch {
//            print("store data error: \(error)")
//        }
//    }
//
//    func data(forKey key: String) -> Data? {
//        do {
//            return try object(forKey: key)
//        } catch {
//            print("get data error: \(error)")
//            return nil
//        }
//    }
//
//    func removeAllData() {
//        do {
//            try removeAll()
//        } catch {
//            print("get data error: \(error)")
//        }
//    }
//
//    func cachePath(forKey key: String) -> String? {
//        do {
//            let en = try entry(forKey: key)
//            return en.filePath
//        } catch {
//            #if DEBUG
//            print("❌ error: \(error)")
//            #endif
//            return nil
//        }
//    }
//}
