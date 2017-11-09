//
// Created by Lucas Maris on 3/23/17.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class MyViewController: UITableViewController {

    var items: [String] = []

    var polygons: [String: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "My TableView"

        tableView.register(MyCell.self, forCellReuseIdentifier: "cellId")
        //tableView.registerClass(Header.self, forHeaderFooterViewReuseIdentifier: "headerId")
        //tableView.sectionHeaderHeight = 50

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Insert", style: .plain, target: self, action: #selector(MyViewController.insert))

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batch Insert", style: .plain, target: self, action: #selector(MyViewController.insertBatch))

        //tableView.allowsSelection = true

        loadPolygons("0")

    }

    func insertBatch() {
        var indexPaths = [IndexPath]()
        for i in items.count...items.count + 5 {
            items.append("Item \(i + 1)")
            indexPaths.append(IndexPath(row: i, section: 0))
        }

        var bottomHalfIndexPaths = [IndexPath]()
        for _ in 0...indexPaths.count / 2 - 1 {
            bottomHalfIndexPaths.append(indexPaths.removeLast())
        }

        tableView.beginUpdates()

        tableView.insertRows(at: indexPaths, with: .right)
        tableView.insertRows(at: bottomHalfIndexPaths, with: .left)

        tableView.endUpdates()
    }

    func insert(_ name: String) {
        items.append(name)

        let insertionIndexPath = IndexPath(row: items.count - 1, section: 0)

        tableView.insertRows(at: [insertionIndexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! MyCell
        myCell.nameLabel.text = items[indexPath.row]
        myCell.myTableViewController = self
        return myCell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "headerId")
    }

    func deleteCell(_ cell: UITableViewCell) {
        if let deletionIndexPath = tableView.indexPath(for: cell) {
            items.remove(at: deletionIndexPath.row)
            tableView.deleteRows(at: [deletionIndexPath], with: .automatic)
        }
    }

    func loadPolygons(_ id: String) {
        AWSLambdaManager.sharedInstance.facets(id) { result, exception, error in

            if result != nil {

                self.polygons.removeAll()

                let jsonResult = JSON(result!)
                if let polygons = jsonResult["rank"].array {
                    for polygon in polygons {
                        if let poly = polygon.dictionary {
                            if let name = poly["name"], let n = name.string,
                               let id = poly["id"], let i = id.string {
                                //print(n)

                                self.polygons[n] = i

                                Utils.executeInMainThread {
                                    self.insert(n)
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    func deleteAll() {

        var indexPaths = [IndexPath]()
        for i in 0...items.count-1 {
            indexPaths.append(IndexPath(row: i, section: 0))
        }

        tableView.deleteRows(at: indexPaths, with: .automatic)

    }

}

class Header: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "My Header"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()

    func setupViews() {
        addSubview(nameLabel)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))

    }

}

class MyCell: UITableViewCell {

    var myTableViewController: MyViewController?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()

    let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete", for: UIControlState())
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    func setupViews() {
        addSubview(nameLabel)
        addSubview(actionButton)

        actionButton.addTarget(self, action: #selector(MyCell.handleAction), for: .touchUpInside)

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]-8-[v1(80)]-8-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel, "v1": actionButton]))

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": actionButton]))

    }

    func handleAction() {

        //myTableViewController?.view.removeFromSuperview()

        //myTableViewController?.deleteCell(self)

        // this should delete all the cells
        // then reload the data with the children of the node


        if let name = self.nameLabel.text {
            let id = myTableViewController?.polygons[name]
            if let id = id {

                myTableViewController?.deleteAll()
                //myTableViewController?.loadPolygons(id)
            }
        }

    }

}

