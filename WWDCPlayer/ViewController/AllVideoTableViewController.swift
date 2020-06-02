//
//  AllVideoTableViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class AllVideoTableViewController: UITableViewController {

    var group: Group!

    let videoCellIdentifier = "video-cell-identifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = group.title
        
        let nib = UINib(nibName: "VideoItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: videoCellIdentifier)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return group.videos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: videoCellIdentifier, for: indexPath) as? VideoItemTableViewCell else {
            fatalError()
        }

        let video = group.videos[indexPath.item]
        cell.config(video)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = group.videos[indexPath.item]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "VideoDetailContainer") as! VideoDetailContainerViewController
        vc.video = video
        navigationController?.parent?.showDetailViewController(vc, sender: nil)
    }

}
