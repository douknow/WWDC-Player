//
//  AllVideoTableViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class AllVideoTableViewController: UITableViewController {

    // MARK: - Views

    var searchController: UISearchController!

    var group: Group!
    var filteredVideos: [Video] = []

    let videoCellIdentifier = "video-cell-identifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = group.title
        filteredVideos = group.videos

        setupViews()
        
        let nib = UINib(nibName: "VideoItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: videoCellIdentifier)
    }

    func setupViews() {
        searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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
        return filteredVideos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: videoCellIdentifier, for: indexPath) as? VideoItemTableViewCell else {
            fatalError()
        }

        let video = filteredVideos[indexPath.item]
        cell.config(video)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = filteredVideos[indexPath.item]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "VideoDetailContainer") as! VideoDetailContainerViewController
        vc.video = video
        navigationController?.parent?.showDetailViewController(vc, sender: nil)
    }

}

extension AllVideoTableViewController: UISearchControllerDelegate {

}

extension AllVideoTableViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let allVideos = group.videos
        let videos: [Video]

        if let keyWords = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces), !keyWords.isEmpty {
            videos = allVideos.filter { ($0.title?.lowercased() ?? "").contains(keyWords) }
        } else {
            videos = allVideos
        }

        filteredVideos = videos
        tableView.reloadData()
    }


}

extension AllVideoTableViewController: UISearchBarDelegate {

}
