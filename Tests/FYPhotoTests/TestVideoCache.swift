//
//  TestVideoCache.swift
//  FYPhoto_Tests
//
//  Created by xiaoyang on 2021/3/8.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import FYPhoto
import AVFoundation
import FYVideoCompressor

/// Could failed due to the network request timeout
class TestVideoCache: XCTestCase {
    let videoCache = VideoCache.shared

    /// Test video, this video memory size is 10.1 MB
//    static let testVideoURL = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4")!
//    static let testVideoURL = URL(string: "http://techslides.com/demos/sample-videos/small.mp4")!
    static let testVideoURL = URL(string: "http://clips.vorwaerts-gmbh.de/VfE_html5.mp4")!
    static var cachedURL: URL?
    static var compressedURL: URL?

    override func setUpWithError() throws {
        guard TestVideoCache.cachedURL == nil else {
            return
        }

        let expectation = XCTestExpectation(description: "video cache downloading remote video")
        var error: Error?
        videoCache?.fetchFilePathWith(key: TestVideoCache.testVideoURL, completion: { (result) in
            expectation.fulfill()
            switch result {
            case .success(let url):
                TestVideoCache.cachedURL = url
            case .failure(let _error):
                error = _error
            }
        })

        wait(for: [expectation], timeout: 100)
        if let error = error {
            throw error
        }
        XCTAssertNotNil(TestVideoCache.cachedURL)
//         Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
//        XCTAssertNotNil(TestVideoCache.cachedURL)
//        videoCache?.removeData(forKey: TestVideoCache.cachedURL!)
//        VideoCompressor.removeCompressedTempFile(at: TestVideoCache.cachedURL!)
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    override class func tearDown() {
        VideoCache.shared?.removeData(forKey: testVideoURL)
        if let url = compressedURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    //file:///Users/xiaoyang/Library/Developer/CoreSimulator/Devices/69AE1ED5-FBF6-4D1D-A45B-E0D8823BECBE/data/Containers/Data/Application/356F9368-99CC-4F20-BF2F-8DB66B94F9BB/(A%20Document%20Being%20Saved%20By%20FYPhoto_Example%2011)/FYPhotoVideoCache/ba04dc82fe0a0fdfc51e2bbb7da29068.mp4
    func testViewURLMemorySize() throws {
        XCTAssertNotNil(TestVideoCache.cachedURL)

        let size = TestVideoCache.cachedURL!.sizePerMB()
        print("size: \(size)")
        XCTAssertEqual(size, Double(5), accuracy: 1.0)
    }

    func testCompressVideo() {
        XCTAssertNotNil(TestVideoCache.cachedURL)
        print("cachedURL:\(TestVideoCache.cachedURL!)")
        let size = TestVideoCache.cachedURL!.sizePerMB()
        print("original size: \(size)")
        let expectation = XCTestExpectation(description: "compress video")

        FYVideoCompressor().compressVideo(TestVideoCache.cachedURL!, quality: .mediumQuality) { (result) in
            expectation.fulfill()
            switch result {
            case .success(let url):
                TestVideoCache.compressedURL = url
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 100)

        XCTAssertNotNil(TestVideoCache.compressedURL)
        let compressedSize = TestVideoCache.compressedURL!.sizePerMB()
        XCTAssertLessThan(compressedSize, size)
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

    func testPassVideoValidator() {
        XCTAssertNotNil(TestVideoCache.cachedURL)

        let result = FYVideoValidator().validVideoSize(TestVideoCache.cachedURL!, limit: 40)
        XCTAssert(result, "video url size bigger than 40")
    }

    func testNotPassVideoValidator() {
        XCTAssertNotNil(TestVideoCache.cachedURL)

        let result = FYVideoValidator().validVideoSize(TestVideoCache.cachedURL!, limit: 5)
        XCTAssert(!result, "video url size less than 5")
    }

    func testMP4FileExtension() {
        let fileType = AVFileType.mp4
        XCTAssertEqual(fileType.fileExtension, "mp4")
    }

    func testM4aFileExtension() {
        let fileType = AVFileType.m4a
        XCTAssertEqual(fileType.fileExtension, "m4a")
    }

    func testMovFileExtension() {
        let fileType = AVFileType.mov
        XCTAssertEqual(fileType.fileExtension, "mov")
    }
}
