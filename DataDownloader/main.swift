//
//  main.swift
//  DataDownloader
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation
import SwiftSoup
import Combine

print("Hello, World!")

enum Endpoint {
    static let all = URL(string: "https://developer.apple.com/videos/all-videos/")!
}

enum DownloadError: Error {
    case parse, download, unknow
}

enum ParseError: Error {
    case noSpecialElement
}

func download() -> AnyPublisher<Document, DownloadError> {
    return URLSession.shared.dataTaskPublisher(for: Endpoint.all)
        .map(\.data)
        .mapError({ error -> DownloadError in
            .download
        })
        .tryMap { data -> Document in
            if let str = String(data: data, encoding: .utf8) {
                return try SwiftSoup.parse(str)
            } else {
                throw DownloadError.parse
            }
        }
        .mapError({
            ($0 as? DownloadError) ?? .unknow
        })
        .eraseToAnyPublisher()
}

struct Video {
    let id: UUID
    let relateLink: String
    let imgURL: URL
    let duration: String
    let name: String
    let tags: [String]
    let shortDescription: String
}

func parseAllVideo(_ doc: Document) throws -> [Video] {
    var videos = [Video]()
    let lis = try doc.select(".collection-focus-groups > li")

    for li in lis {
        let items = try li.select("ul.collection-items > li")
        for item in items {
            let relateLink = try item.select("a.video-image-link").attr("href")
            let imageURLStr = try item.select("img.video-image").attr("src")
            let imageURL = URL(string: imageURLStr)!
            let duration = try item.select("span.video-duration").text()
            let name = try item.select("h4.video-title").text()

            var tags = [String]()
            let tagSpans = try item.select("video-tags span")
            for span in tagSpans {
                let text = try span.text()
                let tagsOfSpan = text.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .map { String($0) }
                tags += tagsOfSpan
            }

            let shortDesc = try item.select("p.description").text()

            let video = Video(id: UUID(), relateLink: relateLink, imgURL: imageURL, duration: duration, name: name, tags: tags, shortDescription: shortDesc)
            videos.append(video)
        }
    }
    return videos
}

let group = DispatchGroup()
group.enter()

var subscriptions = Set<AnyCancellable>()
download()
    .sink(receiveCompletion: { complete in
        if case .failure(let error) = complete {
            print(error)
        }
    }) { document in
//        let video = parseAllVideo(document)
    }
    .store(in: &subscriptions)

group.wait()
