//
//  Video.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

struct Group: Codable {
    let title: String
    let videos: [Video]
}

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
