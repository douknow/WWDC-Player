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
    
    let allVideoURL = URL(string: "https://developer.apple.com/videos/all-videos/")!
    
    func allVideos() -> AnyPublisher<[Group], Error> {
        URLSession.shared.dataTaskPublisher(for: allVideoURL)
            .map(\.data)
            .tryMap { data -> [Group] in
                guard let html = String(data: data, encoding: .utf8) else {
                    throw Error.error
                } 
                
                var groupData: [Group] = []
                let doc = try SwiftSoup.parse(html)
                let groups = try doc.select("#main > section.all-content.padding-bottom > ul > li")
                for group in groups {
                    var videosData: [Video] = []                    
                    let title = try group.select("section > section > section > section > span > span").text()
                    
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
                        let data = Video(id: id, 
                                          relaveURLStr: url, 
                                          previewImageURL: imageURL, 
                                          title: title, 
                                          focus: focus, 
                                          description: description, 
                                          event: event,
                                          duration: duration)
                        videosData.append(data)
                    }
                    
                    let data = Group(title: title, videos: videosData)
                    groupData.append(data)
                }
                return groupData
            }
            .mapError({ _ in
                Error.error
            })
            .eraseToAnyPublisher()
    }
    
}
