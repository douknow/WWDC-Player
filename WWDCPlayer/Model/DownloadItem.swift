//
//  DownloadIetm.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation

class DownloadItem: NSObject {
    
    enum DownloadStatus: Int {
        case downloading = 0
        case finished = 1
    }
    
    enum VideoType: Int {
        case hd = 0, sd
    }
    
    enum Status {
        case unstart
        case downloading, paused, downloadSubtitles, finished
    }

    static func parse(from videos: [Video], coreDataStack: CoreDataStack) -> [DownloadItem] {
        return videos.compactMap { video in
            guard let downloadData = video.downloadData,
                let url = downloadData.url,
                let m3u8 = downloadData.m3u8 else { return nil }
            return DownloadItem(video: video, resolution: downloadData.resolution, url: url, m3u8: m3u8, coreDataStack: coreDataStack)
        }
    }
    
    @Published var downloadProgress: Double = 0
    @Published var status: Status = .unstart
    
    let video: Video
    let downloadData: DownloadData
    let downloadURL: URL
    var m3u8: URL
    let coreDataStack: CoreDataStack
    let fileManager = FileManager.default
    
    var dataTask: URLSessionDownloadTask!
    var resumeData: Data?
    var resumeLocation: URL!
    var fileLocation: URL!
    
    lazy var urlSession: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        return session
    }()
    
    init(video: Video, resolution: VideoType, url: URL, m3u8: URL, coreDataStack: CoreDataStack) {
        self.video = video
        self.downloadURL = url
        self.coreDataStack = coreDataStack
        self.m3u8 = m3u8

        if let downloadData = video.downloadData {
            self.downloadData = downloadData
            status = .paused
            downloadProgress = downloadData.progress
        } else {
            let downloadData = DownloadData(context: coreDataStack.context)
            downloadData.id = UUID()
            downloadData.progress = 0
            downloadData.downloadStatus = .downloading
            downloadData.url = url
            downloadData.m3u8 = m3u8
            downloadData.resolution = resolution
            video.downloadData = downloadData
            coreDataStack.save()
            self.downloadData = downloadData
        }
        
        super.init()

        resumeLocation = createResumeURL(video.id!)
        fileLocation = Self.createFileLocation(video.id!)

        tryResotreResumeData()
    }
    
    func createResumeURL(_ id: String) -> URL {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Could not find the cache directory")
        }
        
        let cacheURL = url.appendingPathComponent("video_resume_data")
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: [:])
        
        return cacheURL
            .appendingPathComponent(id)
    }
    
    static func createFileLocation(_ id: String) -> URL {
        return Folder.video(for: id)
            .appendingPathComponent(id)
            .appendingPathExtension("mp4")
    }
    
    func deleteCacheIfNeed() {
        guard fileManager.fileExists(atPath: resumeLocation.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: resumeLocation)
        } catch {
            print("Could not delete cache file: \(error)")
        }
    }
    
    func deleteFileIfNeed() {
        try? fileManager.removeItem(at: fileLocation)
    }
    
    func tryResotreResumeData() {
        try? resumeData = Data(contentsOf: resumeLocation)
    }
    
    func createCacheFile(_ data: Data) {
        let url = resumeLocation!
        fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
    }
    
    func moveToVideoLocation(from location: URL) {
        do {
            try fileManager.moveItem(at: location, to: fileLocation)
        } catch {
            print("Could not move file to video download directory: \(error)")
        }
    }
    
    func remove() {
        deleteCacheIfNeed()
        deleteFileIfNeed()

        coreDataStack.context.delete(downloadData)
        coreDataStack.save()
    }
    
    /// Pause download
    func pause() {
        status = .paused
        dataTask.cancel { data in
            self.resumeData = data
            
            if let data = data {
                self.createCacheFile(data)
            }
            
            self.downloadData.progress = self.downloadProgress
            self.coreDataStack.save()
        }
    }
    
    /// Resume download
    func resume() {
        status = .downloading
        if let resumeData = resumeData {
            dataTask = urlSession.downloadTask(withResumeData: resumeData)
            dataTask.resume()
        } else {
            dataTask = urlSession.downloadTask(with: downloadURL)
            dataTask.resume()
            status = .downloading
        }
    }
}

extension DownloadItem: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("🥶 Complete download with an error: \(error.localizedDescription) title: \(video.title!)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        print("Download \(video.title!) percent: \(percent)")
        downloadProgress = percent
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finish download: \(video.title!)")
        status = .finished
        moveToVideoLocation(from: location)
        deleteCacheIfNeed()

        status = .downloadSubtitles
        downloadSubtitles { [weak self] in
            self?.completeDownloadData()
            self?.status = .finished
        }
    }

    func completeDownloadData() {
        downloadData.progress = 1
        downloadData.downloadStatus = .downloaded
        coreDataStack.save()
    }

    func downloadSubtitles(completion: () -> Void) {
        let downloader = Downloader()
        let subtitleUrl = Folder.subtitle(for: video)
        downloader.downloadSubtitles(link: m3u8) { result in
            switch result {
            case .success(let subtitles):
                subtitles.forEach { subtitle in
                    downloader.downloadSubtitleContent(subtitle: subtitle) { result in
                        switch result {
                        case .success(let args):
                            let (subtitle, content) = args
                            let url = subtitleUrl
                                .appendingPathComponent("\(subtitle.groupId)-\(subtitle.language)-\(subtitle.name)")
                                .appendingPathExtension("txt")
                            try? content.write(to: url, atomically: true, encoding: .utf8)
                        case .failure(let error):
                            print("download subtitle content error: \(error.localizedDescription) of \(subtitle.url.absoluteString)")
                        }
                    }
                }
            case .failure(let error):
                print("download error: \(error.localizedDescription)")
            }
        }
        completion()
    }
    
}
