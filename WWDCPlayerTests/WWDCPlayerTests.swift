//
//  WWDCPlayerTests.swift
//  WWDCPlayerTests
//
//  Created by Xianzhao Han on 2020/6/4.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import XCTest
@testable import WWDCPlayer

class WWDCPlayerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindInString() throws {
        let str = """
            #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,LANGUAGE="eng",URI="subtitles/eng/prog_index.m3u8"
            """
        let res = try! str.findFirst(regex: "GROUP-ID=\"(.*?)\"")!
        XCTAssertEqual(res, "subs")
    }

    func testParseSubtitle() throws {
        let url = Bundle(for: WWDCPlayerTests.self).url(forResource: "demo", withExtension: "m3u8")!
        let content = try! String(contentsOf: url)
        let downloader = Downloader()
        let subtitles = downloader.parseSubtitles(content: content, baseLink: URL(string: "")!)
        for subtitle in subtitles {
            print(subtitle)
        }
    }

    func testParseSubtitleSequences() throws {
        let url = Bundle(for: WWDCPlayerTests.self).url(forResource: "prog_index", withExtension: "m3u8")!
        let content = try! String(contentsOf: url)
        let downloader = Downloader()
        let urls = downloader.parseSubtitleSequences(content: content, baseLink: URL(string: "https://baidu.com")!)
        print(urls.map { $0.absoluteString })
    }

    func testDownloadSubtitle() throws {
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2019/238w8avpcuaf5ox/238/hls_vod_mvp.m3u8")!
        let downloader = Downloader()
        downloader.downloadSubtitle(link: url)
        let exp = expectation(description: "...")
        wait(for: [exp], timeout: 100)
    }

    func testParseSubtitleContent() throws {
        let url = Bundle(for: WWDCPlayerTests.self).url(forResource: "fileSequence0", withExtension: "webvtt")!
        let content = try! String(contentsOf: url)
        let downloader = Downloader()
        downloader.parseSubtitleContent(content: content)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
