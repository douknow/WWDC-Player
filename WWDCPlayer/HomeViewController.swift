//
//  HomeViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class HomeViewController: UITableViewController {
    
    enum Identifier {
        static let videoCell = "VideoItemCell"
    }
    
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    @Published var isLoading = false
    
    let service = WWDCService()
    var subscriptions = Set<AnyCancellable>()
    var groups: [Group] = []
    var selectedVideo: Video?
    var subscription = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        let nib = UINib(nibName: "VideoItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Identifier.videoCell)
        
        $isLoading
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

        fetchData()
    }
    
    func setupView() {
        view.addSubview(indicator) {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().multipliedBy(0.8)
        }
    }
    
    func fetchData() {
        isLoading = true
        service.allVideos()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                // handle error
            }) { [unowned self] groups in
                print("group's count: \(groups.count)")
                
                self.groups = groups
                self.tableView.reloadData()
                self.isLoading = false
            }
            .store(in: &subscriptions)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return groups.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail", 
            let vc = segue.destination as? VideoDetailViewController,
            let video = selectedVideo {
            vc.video = video
        }
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

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
