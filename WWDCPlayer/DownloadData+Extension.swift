//
//  DownloadData+Extension.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/14.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation


extension DownloadData {

    enum DownloadStatus: Int {
        case downloading = 0, downloaded
    }

    var downloadStatus: DownloadStatus {
        set {
            status = Int16(newValue.rawValue)
        }

        get {
            return DownloadStatus(rawValue: Int(status)) ?? .downloading
        }
    }

    var resolution: DownloadItem.VideoType {
        set {
            resolutionNumber = Int16(newValue.rawValue)
        }

        get {
            return DownloadItem.VideoType(rawValue: Int(resolutionNumber)) ?? .sd
        }
    }

}
