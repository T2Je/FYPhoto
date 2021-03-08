//
//  TestVideoCache.swift
//  FYPhoto_Tests
//
//  Created by xiaoyang on 2021/3/8.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import FYPhoto

class TestVideoCache: XCTestCase {
    let videoCache = VideoCache.shared
    
    override func setUpWithError() throws {
            
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        guard let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4") else { return }
//        videoCache?.fetchFilePathWith(key: url, completion: { (result) in
//            switch result {
//            case .success(let url):
//                print(<#T##items: Any...##Any#>)
//            }
//        })
    }
    
    func testGetCachedKeyWithNormalURLSuccessfully() {
        // given
        let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")
        XCTAssertNotNil(url, "test url in-vallid")
        
        // when
        let key = videoCache?.getCacheKey(with: url!)
        
        // then
        XCTAssertNotNil(key, "url key shouldn't be nil")
        XCTAssertEqual(key!, "ForBiggerFun.mp4")
    }
    
    func testGetCacheKeyAbnormalSuccessfully() {
        let url = URL(string: "http://client.gsup.sichuanair.com/file.php?9bfc3b16aec233d025c18042e9a2b45a.mp4")
        XCTAssertNotNil(url, "test url in-vallid")
        let key = videoCache?.getCacheKey(with: url!)
        XCTAssertNotNil(key, "url key shouldn't be nil")
        XCTAssertEqual(key, "9bfc3b16aec233d025c18042e9a2b45a.mp4")
    }
    
    

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
