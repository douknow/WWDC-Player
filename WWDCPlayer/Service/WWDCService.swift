//
//  WWDC.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation
import Combine
import SwiftSoup

class WWDCService {
    
    enum Error: Swift.Error {
        case error
    }
    
    enum Endpoint {
        static let basic = URL(string: "https://developer.apple.com")!
    }
    
    let allVideoURL = URL(string: "https://developer.apple.com/videos/all-videos/")!
    
    func allVideos() -> AnyPublisher<[Response.Video], Error> {
        URLSession.shared.dataTaskPublisher(for: allVideoURL)
            .map(\.data)
            .tryMap { data -> [Response.Video] in
                guard let html = String(data: data, encoding: .utf8) else {
                    throw Error.error
                } 
                
                let doc = try SwiftSoup.parse(html)
                let groups = try doc.select("#main > section.all-content.padding-bottom > ul > li")
                var videosData: [Response.Video] = []
                for group in groups {
                    let videos = try group.select("> ul > li")
                    for video in videos {
                        let imageAndDuration = try video.select("section.grid > section.row > section").first!
                        let imageURLStr = try imageAndDuration.select("a > img").attr("src")
                        let imageURL = URL(string: imageURLStr)!
                        let duration = try imageAndDuration.select("a > span").text()
                        
                        let infoSection = try video.select("section.grid > section.row > section").last!
                        let url = try infoSection.select("a").attr("href")
                        let title = try infoSection.select("a > h4").text()
                        let id = String(url.split(separator: "/").last ?? "")
                        let event = try infoSection.select("ul > li:first-child > span").text()
                        let focus = try infoSection.select("ul > li.video-tag.focus > span").text()
                            .split(separator: ",")
                            .map { String($0).trimmingCharacters(in: .whitespaces) }
                        let description = try infoSection.select("p.description").text()
                        let data = Response.Video(id: id, 
                                          relaveURLStr: url, 
                                          previewImageURL: imageURL, 
                                          title: title, 
                                          focus: focus, 
                                          description: description, 
                                          event: event,
                                          duration: duration)
                        videosData.append(data)
                    }
                }
                return videosData
            }
            .mapError({ _ in
                Error.error
            })
            .eraseToAnyPublisher()
    }
    
    func videoDetail(by video: Video) -> AnyPublisher<VideoDetail, Error> {
        let url = Endpoint.basic.appendingPathComponent(video.urlStr ?? "")
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap({ data -> VideoDetail in
                guard let html = String(data: data, encoding: .utf8) else {
                    throw Error.error
                }
                
                let doc = try SwiftSoup.parse(html)
                let m3u8URLStr = try doc.select("video").attr("src")
                guard let m3u8URL = URL(string: m3u8URLStr) else {
                    throw Error.error
                }
                
                let infomation = try doc.select("ul.supplements > li.supplement.details")
                let title = try infomation.select("h1").first()!.text()
                let description = try infomation.select("p").first()!.text()
                let otherInfo = try infomation.select(" > ul.links.small")
                let hdDownloadURL = try otherInfo.select(" > li.download > ul > li > a").first()!.attr("href")
                let sdDownloadURL = try otherInfo.select(" > li.download > ul > li > a").last()!.attr("href")

                let hFours = try infomation.select("h4")
                var relatedVideo: [ShortVideoGroup] = []
                for h in hFours {
                    let links = try h.nextElementSibling()!.select("li > a")
                    let name = try h.text()
                    var shortVideos: [ShortVideo] = []
                    for link in links {
                        let href = try link.attr("href")
                        let name = try link.text()
                        let shortVideo = ShortVideo(name: name, relatedLink: href)
                        shortVideos.append(shortVideo)
                    }
                    let videoGroup = ShortVideoGroup(name: name, videos: shortVideos)
                    relatedVideo.append(videoGroup)
                }
                
                let videoDetail = VideoDetail(id: video.id!,title: title, description: description, m3u8URL: m3u8URL, hd: URL(string: hdDownloadURL)!, sd: URL(string: sdDownloadURL)!, relatedVideos: relatedVideo)
                return videoDetail
            })
            .mapError { _ in 
                Error.error
            }
            .eraseToAnyPublisher()
    }
    
}
