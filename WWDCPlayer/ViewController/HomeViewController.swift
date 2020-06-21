//
//  HomeViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine
import CoreData

class HomeViewController: UITableViewController {
    
    enum Identifier {
        static let videoCell = "VideoItemCell"
    }
    
    var indicator: UIActivityIndicatorView!
    
    @Published var isLoading = false
    @Published var videos: [Video] = []
    
    let service = WWDCService()
    var coreDataStack: CoreDataStack!
    var subscriptions = Set<AnyCancellable>()
    var groups: [Group] = []
    var selectedVideo: Video?
    var subscription = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        navigationController?.navigationBar.isTranslucent = false
        
        navigationController?.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifier.videoCell)
        
        $videos
            .filter { !$0.isEmpty }
            .map { [unowned self] videos -> [Group] in
                self.convert(videos)
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.isLoading = false
                self.groups = $0
                self.tableView.reloadData()
            }
            .store(in: &subscriptions)
        
        $isLoading
            .removeDuplicates()
            .sink(receiveCompletion: { completion in
                // handle error
            }) { [unowned self] isLoading in
                if isLoading {
                    self.indicator.isHidden = false
                    self.indicator.startAnimating()
                } else {
                    self.indicator.stopAnimating()
                }
            }
            .store(in: &subscriptions)
        
        fetchDataFromCoreData()
    }
    
    func convert(_ videos: [Video]) -> [Group] {
        var groups: [Group] = []
        for video in videos {
            let event = video.event ?? "No Event"
            if let index = groups.firstIndex(where: { $0.title == event }) {
                groups[index] = Group(title: event, videos: groups[index].videos + [video])
            } else {
                let group = Group(title: event, videos: [video])
                groups.append(group)
            }
        }
        groups.sort {
            if $0.title.contains("WWDC") && $1.title.contains("WWDC") {
                return $0.title > $1.title
            }
            
            return $0.title < $1.title 
        }
        return groups
    }
    
    func setupView() {
        indicator = UIActivityIndicatorView(style: .medium)
        view.addSubview(indicator) {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().multipliedBy(0.8)
        }
    }
    
    func fetchDataFromCoreData() {
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        do {
            videos = try coreDataStack.context.fetch(request)
            if videos.isEmpty { fetchDataFromWeb() }
        } catch {
            print("Load data from coreData error: \(error)")
        }
    }
    
    func fetchDataFromWeb() {
        isLoading = true
        service.allVideos()
            .sink(receiveCompletion: { completion in
                // handle error
            }) { [unowned self] videos in
                print("🎉 Fetch \(videos.count) videos from wwdc web site.")
                
                let videos = self.saveData(videos)
                self.videos = videos
            }
            .store(in: &subscriptions)
    }
    
    func saveData(_ videos: [Response.Video]) -> [Video] {
        var datas: [Video] = []
        
        for video in videos {
            let data = Video(context: coreDataStack.context)
            data.id = video.id
            data.title = video.title
            data.des = video.description
            data.duration = video.duration
            data.event = video.event
            data.focus = video.focus.joined(separator: ",")
            data.previewImageURL = video.previewImageURL
            data.urlStr = video.relaveURLStr
            datas.append(data)
        }
        
        coreDataStack.save()
        return datas
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "ShowDetail",
//
//        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.videoCell, for: indexPath)
        
        cell.textLabel?.text = groups[indexPath.item].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let group = groups[indexPath.item]
        let vc = AllVideoTableViewController()
        vc.group = group
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension HomeViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        navigationController.interactivePopGestureRecognizer?.isEnabled = viewController !== self
    }
    
}
