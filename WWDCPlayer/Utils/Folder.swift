//
//  Folder.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/16.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation

class Folder {

    static let fm = FileManager.default

    static let rootURL: URL = {
        guard let rootURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Get root url failture")
        }
        let url = rootURL.appendingPathComponent("videos")
        try? fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }()

    /// Get subtitle folder by video and auto create
    /// - Parameter video: video
    /// - Returns: the folder for save all subtitles of this video
    static func subtitle(for video: Video) -> URL {
        return subtitle(for: video.id!)
    }

    /// Get subtitle folder by id(video's id) and aotu create
    /// - Parameter id: video's id
    /// - Returns: subtitle folder url
    static func subtitle(for id: String) -> URL {
        let url = rootURL
            .appendingPathComponent(id)
            .appendingPathComponent("subtitle")
        try? fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    static func subtitles(video: Video, for resolution: DownloadItem.VideoType) -> [Subtitle] {
        let startStr: String
        switch resolution {
        case .hd:
            startStr = "sub"
        case .sd:
            startStr = "subs"
        }
        let subtitleUrl = subtitle(for: video)
        let urls = (try? fm.contentsOfDirectory(at: subtitleUrl, includingPropertiesForKeys: nil, options: [])) ?? []
        return urls.map { url -> (components: [String], url: URL) in
                let fileName = url.deletingPathExtension().lastPathComponent
                let components = fileName.split(separator: "-").map { String($0) }
                return (components: components, url: url)
            }
            .filter { $0.components.count == 3 }
            .filter { $0.components[0] == startStr }
            .map { args in
                let (components, url) = args
                let gruopId = components[0]
                let language = components[1]
                let name = components[2]
                return Subtitle(groupId: gruopId, name: name, language: language, url: url)
            }
    }

    /// Get video saved folder and auto create
    /// - Parameter video: video
    /// - Returns: folder url
    static func video(for video: Video) -> URL {
        return Self.video(for: video.id!)
    }

    /// Get video saved folder and auto create
    /// - Parameter id: video's id
    /// - Returns: folder url
    static func video(for id: String) -> URL {
        let url = rootURL.appendingPathComponent(id)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    /// Get video file url
    /// - Parameter video: video
    /// - Returns: file url
    static func videoFile(for video: Video) -> URL {
        return videoFile(for: video.id!)
    }

    /// Get video file url
    /// - Parameter id: video's id
    /// - Returns: file url
    static func videoFile(for id: String) -> URL {
        return video(for: id)
            .appendingPathComponent(id)
            .appendingPathExtension("mp4")
    }

}
