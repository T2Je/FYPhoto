//
//  VideoCache.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/10/14.
//

import Foundation
import Cache
import Alamofire


/// Cache remote videos, expired in 7 days
class VideoCache: NSObject {
    private static let diskConfig = DiskConfig(name: "VideoReourceCache", expiry: .seconds(3600*24*7))
    private static let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    private static let storage = try? Storage.init(diskConfig: VideoCache.diskConfig, memoryConfig: VideoCache.memoryConfig, transformer: TransformerFactory.forData())

    static func clearAll() {
        try? storage?.removeAll()
    }

    static func save(data: Data, key: URL) {
        try? storage?.setObject(data, forKey: key.absoluteString)
    }

    static func fetch(key: URL, success: @escaping (_ data: Data) -> Void, failed: @escaping (_ error: Error) -> Void) {
        if let temp = try? storage?.object(forKey: key.absoluteString) {
            success(temp)
        } else {
            AF.request(key).responseData { (data: AFDataResponse<Data>) in
                switch data.result {
                case .success(let value):
                    success(value)
                    self.save(data: value, key: key)
                case .failure(let error):
                    failed(error)
                }
            }
        }
    }

    static func fetchURL(key: URL, success: @escaping (_ filePath: URL)->Void, failed: @escaping (_ error: Error)->Void) {
        if let temp = try? VideoCache.storage?.transformData().entry(forKey: key.absoluteString),
            let filePath = temp.filePath {
            let url = URL(fileURLWithPath: filePath)
            success(url)
        } else {
            AF.request(key).responseData { (data: DataResponse<Data, AFError>) in
                switch data.result {
                case .success(let value):
                    VideoCache.save(data: value, key: key)
                    let temp = try? VideoCache.storage?.transformData().entry(forKey: key.absoluteString)
                    if let filePath = temp?.filePath {
                        let url = URL(fileURLWithPath: filePath)
                        success(url)
                    }
                case .failure(let error):
                    failed(error)
                }
            }
        }
    }
}
