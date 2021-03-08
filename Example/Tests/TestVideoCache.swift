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

    //file:///Users/xiaoyang/Library/Developer/CoreSimulator/Devices/69AE1ED5-FBF6-4D1D-A45B-E0D8823BECBE/data/Containers/Data/Application/356F9368-99CC-4F20-BF2F-8DB66B94F9BB/(A%20Document%20Being%20Saved%20By%20FYPhoto_Example%2011)/FYPhotoVideoCache/ba04dc82fe0a0fdfc51e2bbb7da29068.mp4
    func testViewURLMemorySize() throws {
        let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")
        XCTAssertNotNil(url, "test url in-vallid")
        let expectation = XCTestExpectation(description: "video cache downloading remote video")
        var cachedURL: URL?
        videoCache?.fetchFilePathWith(key: url!, completion: { (result) in
            expectation.fulfill()
            switch result {
            case .success(let url):
                cachedURL = url
            case .failure(let error):
                print(error)
            }
        })
        
        wait(for: [expectation], timeout: 10)
        
        XCTAssertNotNil(cachedURL)
        
        let size = cachedURL!.sizePerMB()
        print("size: \(size)")
        XCTAssertEqual(size, Double(12.9), accuracy: 1.0)
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

}
