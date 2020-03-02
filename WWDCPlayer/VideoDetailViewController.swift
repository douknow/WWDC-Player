//
//  VideoDetailViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class VideoDetailViewController: UITableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet weak var videoURL: UILabel!
    
    @Published var isLoading = false
    
    var video: Video!
    let service = WWDCService()
    var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        title = video.title
        
        $isLoading
            .sink { [unowned self] isLoading in
                if isLoading {
                    self.indicator.isHidden = false
                    self.indicator.startAnimating()
                } else {
                    self.indicator.stopAnimating()
                }
            }
            .store(in: &subscriptions)
        
        self.loadData()
    }
    
    func setupView() {
        view.addSubview(indicator) {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().multipliedBy(0.8)
        }
    }
    
    func loadData() {
        isLoading = true
        
        service.videoDetail(by: video)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                // handle error
            }) { [unowned self] videoDetail in
                self.isLoading = false
                self.titleLabel.text = videoDetail.title
                self.descriptionLabel.text = videoDetail.description
                self.videoURL.text = videoDetail.m3u8URL.absoluteString
                self.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isLoading ? 0 : 2
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            print(videoURL.text ?? "NIL")
        default: 
            break
        }
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
