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
    
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    @Published var isLoading = false
    @Published var videos: [Video] = []
    
    let service = WWDCService()
    var coreDataStack: CoreDataStack!
    var subscriptions = Set<AnyCancellable>()
    var groups: [Group] = []
    var selectedVideo: Video?
    var subscription = Set<AnyCancellable>()
    var downloadItems: [DownloadItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        let nib = UINib(nibName: "VideoItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Identifier.videoCell)
        
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
        restoreDownloadList()
    }
    
    func restoreDownloadList() {
        let request: NSFetchRequest<DownloadData> = DownloadData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        do {
            let downloadDatas = try coreDataStack.context.fetch(request)
            downloadItems = downloadDatas.map {
                DownloadItem(video: $0.video!, url: $0.url!, coreDataStack: self.coreDataStack, downloadData: $0)
            }
        } catch {
            print("Could fetch download data from core data: \(error)")
        }
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
        if segue.identifier == "ShowDetail", 
            let vc = segue.destination as? VideoDetailViewController,
            let video = selectedVideo {
            vc.video = video
            vc.downloadItems = downloadItems
            vc.coreDataStack = coreDataStack
            vc.downloadVideo    
                .sink { [unowned self] in
                    self.downloadItems.append($0)
                }
                .store(in: &vc.subscriptions)
        } else if segue.identifier == "ShowDownload",
            let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? DownloadViewController {
            vc.downloadItems = downloadItems
            
            vc.removeDownloadItem
                .sink { [unowned self] item in
                    self.downloadItems.removeAll { $0 === item }
                }
                .store(in: &vc.subscriptions)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return groups.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].videos.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.videoCell, for: indexPath) as? VideoItemTableViewCell else {
            fatalError()
        }
        
        let group = groups[indexPath.section]
        let video = group.videos[indexPath.row]
        cell.config(video)
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let video = groups[indexPath.section].videos[indexPath.row]
        selectedVideo = video
        performSegue(withIdentifier: "ShowDetail", sender: nil)
    }
    
}
