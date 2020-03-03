//
//  Video.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

struct Group {
    let title: String
    let videos: [Video]
}

struct VideoDetail {
    let id: String
    let title: String
    let description: String
    let m3u8URL: URL
    let hd: URL
    let sd: URL
}

enum Response {

    struct Video: Codable {
        let id: String
        let relaveURLStr: String
        let previewImageURL: URL
        let title: String
        let focus: [String]
        let description: String
        let event: String
        let duration: String
    }
    
}
