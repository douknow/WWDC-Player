//
//  DownloadViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class DownloadViewController: UITableViewController {
    
    var downloadItems: [DownloadItem] = []
    var shareStore = ContainerService.shared.shareStore
    
    var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "DownloadItemCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: DownloadItemCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        downloadItems = shareStore.allDownloadItems
        tableView.reloadData()
    }
    
    @IBAction func close(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DownloadItemCell.identifier, for: indexPath) as? DownloadItemCell else {
            fatalError("Wrong cell type")
        }
        
        let item = downloadItems[indexPath.row]
        cell.config(item: item)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = downloadItems[indexPath.row]
        print(item.fileLocation.path)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = downloadItems.remove(at: indexPath.row)
            shareStore.remove(downloadItem: item)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            item.remove()
        }
    }

}
