//
//  Downloader.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/4.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation
import Combine

struct Subtitle {
    let groupId: String
    let name: String
    let language: String
    let url: URL
}

struct SubtitleLine {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let value: String
}

enum SubtitleError: Error {
    case parse, download
}

class Downloader {

    func downloadSubtitles(link: URL, completion: @escaping (Result<[Subtitle], SubtitleError>) -> Void) {
        DispatchQueue.global().async {
            do {
                let m3u8Str = try String(contentsOf: link)
                let subtitles = self.parseSubtitles(content: m3u8Str, baseLink: link.deletingLastPathComponent())
                completion(.success(subtitles))
            } catch {
                print("MYERROR: ", error.localizedDescription)
                completion(.failure(.parse))
            }
        }
    }

    func parseSubtitles(content: String, baseLink: URL) -> [Subtitle] {
        let lines = content.split(separator: .BackslashN)
            .filter { $0.hasPrefix("#EXT-X-MEDIA:TYPE=SUBTITLES") }
            .map { String($0) }
        var subtitles: [Subtitle] = []
        for line in lines {
            let groupID = try! line.findFirst(regex: "GROUP-ID=\"(.*?)\"")!
            let name = try! line.findFirst(regex: "NAME=\"(.*?)\"")!
            let language = try! line.findFirst(regex: "LANGUAGE=\"(.*?)\"")!
            let link = try! line.findFirst(regex: "URI=\"(.*?)\"")!
            let url = baseLink.appendingPathComponent(link)
            let subtitle = Subtitle(groupId: groupID, name: name, language: language, url: url)
            subtitles.append(subtitle)
        }
        return subtitles
    }

    func parseSubtitleSequences(content: String, baseLink: URL) -> [URL] {
        return try! content.findAll(regex: "^#EXTINF.*\\n(.*?)$")
            .map { baseLink.appendingPathComponent($0) }
    }

    func downloadSubtitleContent(subtitle: Subtitle, completion: @escaping (Result<(subtitle: Subtitle, content: String), SubtitleError>) -> Void) {
        DispatchQueue.global().async {
            do {
                var fullSubtitle = ""
                let sequenceContent = try String(contentsOf: subtitle.url)
                let sequences = self.parseSubtitleSequences(content: sequenceContent, baseLink: subtitle.url.deletingLastPathComponent())
                for fileURL in sequences {
                    let content = try String(contentsOf: fileURL)
                    fullSubtitle += content
                }
                completion(.success((subtitle, fullSubtitle)))
//                let fm = FileManager.default
//                var url = fm.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
//                url.appendPathComponent("subtitles")
//                try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
//                let path = "\(link.deletingLastPathComponent().lastPathComponent)-\(subtitle.groupId)-\(subtitle.language).webvtt"
//                url.appendPathComponent()
//                fm.createFile(atPath: url.path, contents: fullSubtitle.data(using: .utf8), attributes: nil)
//                print(url.absoluteString)
            } catch {
                print("Download subtitle error: \(error)")
                completion(.failure(.download))
            }
        }
    }

    func parseSubtitleContent(content: String) -> [SubtitleLine] {
        let reg = #"(\d{2}:\d{2}:\d{2}.\d{3}) --> (\d{2}:\d{2}:\d{2}.\d{3}).*\n(.*)$"#
        let groups = try! content.findGroup(regex: reg)

        return groups.map { group -> SubtitleLine in
            let startTime = parseTime(time: group[0])
            let endTime = parseTime(time: group[1])
            let value = group[2]
            return SubtitleLine(startTime: startTime, endTime: endTime, value: value)
        }
    }

    func parseTime(time: String) -> TimeInterval {
        let components = try! time.findGroup(regex: #"(\d{2}):(\d{2}):(\d{2}).(\d{3})"#).first!
        let hour = Double(components[0]) ?? 0
        let minutes = Double(components[1]) ?? 0
        let seconds = Double(components[2]) ?? 0
        let mileSeconds = Double(components[3]) ?? 0
        var time: TimeInterval = 0
        time += hour * 3600
        time += minutes * 60
        time += seconds
        time += mileSeconds / 1000
        return time
    }

}

extension String {

    func findFirst(regex: String) throws -> String? {
        let reg = try NSRegularExpression(pattern: regex, options: [.anchorsMatchLines])
        if let match = reg.matches(in: self, options: [], range: allRange).first {
            let range = match.range(at: match.numberOfRanges - 1)
            return String(self[Range(range, in: self)!])
        }
        return nil
    }

    func findAll(regex: String) throws -> [String] {
        let reg = try NSRegularExpression(pattern: regex, options: [.anchorsMatchLines])
        return reg.matches(in: self, options: [], range: allRange)
            .map { match in
                let range = match.range(at: match.numberOfRanges - 1)
                return String(self[Range(range, in: self)!])
            }
    }

    func findGroup(regex: String) throws -> [[String]] {
        let reg = try NSRegularExpression(pattern: regex, options: [.anchorsMatchLines])
        let matches = reg.matches(in: self, options: [], range: allRange)
        var result: [[String]] = []
        for match in matches {
            var group: [String] = []
            for i in 1..<match.numberOfRanges {
                let stringOfRange = String(self[Range(match.range(at: i), in: self)!])
                group.append(stringOfRange)
            }
            result.append(group)
        }
        return result
    }

    var allRange: NSRange {
        return NSRange(location: 0, length:self.count)
    }

}
