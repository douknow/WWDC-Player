//
//  SubtitleTableViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/5.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

protocol SubtitleTableViewControllerDelegate: class {
    func subtitleTableViewController(_ subtitleTableViewController: SubtitleTableViewController, didSelectedAt indexPath: IndexPath)
    func subtitleTableViewController(_ subtitleTableViewController: SubtitleTableViewController, isLoadingFor indexPath: IndexPath) -> Bool
}

class SubtitleTableViewController: UITableViewController {

    var data: [String] = []
    var selected: IndexPath?

    weak var delegate:SubtitleTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)

        tableView.register(CenterTextCell.self, forCellReuseIdentifier: CenterTextCell.identifier)

        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CenterTextCell.identifier, for: indexPath) as! CenterTextCell
        let text = data[indexPath.row]
        cell.config(text: text, isLoading: delegate?.subtitleTableViewController(self, isLoadingFor: indexPath) ?? false)
        let color: UIColor = indexPath == selected ? .systemBlue : .systemBackground
        cell.label.textColor = color
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selected = indexPath
        tableView.reloadData()
        delegate?.subtitleTableViewController(self, didSelectedAt: indexPath)
    }

}


class CenterTextCell: UITableViewCell {

    static let identifier = "center-text-cell"

    var label: UILabel!
    var indicator: UIActivityIndicatorView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        label = UILabel()
        label.textAlignment = .center
        contentView.addSubview(label) {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(10)
        }

        indicator = UIActivityIndicatorView(style: .medium)
        contentView.addSubview(indicator) {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(self.label)
        }
    }

    func config(text: String, isLoading: Bool) {
        label.text = text
        if isLoading {
            indicator.isHidden = false
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
            indicator.isHidden = true
        }
    }

}
