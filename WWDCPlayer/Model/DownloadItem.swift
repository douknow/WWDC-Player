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
    
    enum VideoType {
        case hd, sd
    }
    
    enum Status {
        case unstart
        case downloading, paused, finished
    }
    
    @Published var downloadProgress: Double = 0
    @Published var status: Status = .unstart
    
    let video: Video
    let downloadURL: URL
    let coreDataStack: CoreDataStack
    var downloadData: DownloadData!
    let fileManager = FileManager.default
    
    var dataTask: URLSessionDownloadTask!
    var resumeData: Data?
    var resumeLocation: URL!
    var fileLocation: URL!
    
    lazy var urlSession: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        return session
    }()
    
    init(video: Video, url: URL, coreDataStack: CoreDataStack, downloadData: DownloadData? = nil) {
        self.video = video
        self.downloadURL = url
        self.coreDataStack = coreDataStack
        
        super.init()
        
        if let downloadData = downloadData {
            self.downloadData = downloadData
        } else {
            self.downloadData = createDownloadData()
        }
        
        resumeLocation = createResumeURL(self.downloadData.id!)
        fileLocation = createFileLocation(self.downloadData.id!)
        
        downloadProgress = self.downloadData.progress
        if let downloadStatus = DownloadStatus(rawValue: Int(self.downloadData.status)) {
            if downloadStatus == .downloading {
                status = .paused
            } else {
                status = .finished
            }
        }
        
        tryResotreResumeData()
    }
    
    func createDownloadData() -> DownloadData {
        let downloadData = DownloadData(context: coreDataStack.context)
        let id = UUID()
        downloadData.id = id 
        downloadData.video = video
        downloadData.url = downloadURL
        downloadData.progress = 0
        downloadData.status = 0
        coreDataStack.save()
        return downloadData
    }
    
    func createResumeURL(_ id: UUID) -> URL {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Could not find the cache directory")
        }
        
        let cacheURL = url.appendingPathComponent("video_resume_data")
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: [:])
        
        return cacheURL
            .appendingPathComponent(id.uuidString)
    }
    
    func createFileLocation(_ id: UUID) -> URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not find the download directory")
        }
        
        let videoURL = url.appendingPathComponent("videos")
        try? FileManager.default.createDirectory(at: videoURL, withIntermediateDirectories: true, attributes: [:])
        let destination = videoURL.appendingPathComponent(id.uuidString)
        return destination
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
            print("🥶 Complete download with an error: \(error) title: \(video.title)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        downloadProgress = percent
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finish download: \(video.title)")
        status = .finished
        moveToVideoLocation(from: location)
        deleteCacheIfNeed()
        
        downloadData.progress = 1
        downloadData.status = 1
        coreDataStack.save()
    }
    
}
