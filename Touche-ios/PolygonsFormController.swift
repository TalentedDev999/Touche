//
// Created by Lucas Maris on 3/23/17.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Eureka
import PKHUD
import TagListView
import SwiftyJSON

class PolygonsFormController: FormViewController {

    var polygonsIds: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView?.tableHeaderView = EurekaLogoView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 130))

        setupForm()

        display("0")
    }

    func display(_ id: String) {

        print("displaying \(id)...")

        // cleanup
        let section = self.form.allSections.last!
        Utils.executeInMainThread {
            section.removeAll()
        }

        self.fetch(id) { items in
            if items.count > 0 {
                self.buildRows(items) { rows in

                    let total: Int = items.map {
                        $0.count
                    }.reduce(0, { $1 + $0 })

                    let labelRow = LabelRow()
                    labelRow.title = "\(total) guys"

                    Utils.executeInMainThread {
                        section.append(labelRow)
                        for row in rows {
                            section.append(row)
                        }
                        section.reload()
                    }
                }
            } else {
                // there are no more items to choose, go back to root
                // self.display("0")


//                Utils.executeInMainThread {
//
//                    FirebasePrefsManager.sharedInstance.within = self.polygonsIds
//
//                    let json = JSON(self.polygonsIds)
//                    if let representation = json.string {
//                        print(representation)
//                        FirebasePrefsManager.sharedInstance.save("searchWithin", value: representation)
//                    }
//
//                    self.navigationController?.popViewController(animated: true)
//                    MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
//                }
            }
        }
    }

    func fetch(_ id: String, completion: @escaping ([PolygonModel]) -> Void) {
        var items: [PolygonModel] = []

        //HUD.show(.rotatingImage(UIImage(icon: .FARefresh, size: CGSize(width: 100, height: 100))))

        AWSLambdaManager.sharedInstance.facets(id) { result, exception, error in
            if result != nil {
                let jsonResult = JSON(result!)
                if let polygons = jsonResult["rank"].array {
                    for polygon in polygons {
                        if let poly = polygon.dictionary {
                            if let nameEnglish = poly["name:en"], let nE = nameEnglish.string,
                               let name = poly["name"], let n = name.string,
                               let count = poly["count"], let c = count.int,
                               let id = poly["id"], let i = id.string {

                                items.append(PolygonModel(id: i, name: n, nameEnglish: nE, count: c))
                            }
                        }
                    }
                }

                Utils.executeInMainThread {
                    //HUD.hide()
                }

                completion(items)
            }
        }


    }

    func buildRows(_ items: [PolygonModel], completion: @escaping ([ButtonRowOf<PolygonModel>]) -> Void) {

        var rows: [ButtonRowOf<PolygonModel>] = []

        for item in items {
            let buttonRow = ButtonRowOf<PolygonModel>(item.id)
            buttonRow.value = item
            buttonRow.title = "\(item.name) (\(item.count))"

            buttonRow.cellSetup({ (cell, row) in
                self.setupButtonRowStyles(cell, row: row)
            })

            buttonRow.onCellSelection({ (cell, row) in
                print(row.value!.name)

                let eureka = self.tableView?.tableHeaderView as! EurekaLogoView
                eureka.addLabel(row.value!.name)

                // todo: save data
                self.polygonsIds.append(row.value!.id)

                self.display(row.value!.id)

            })

            rows.append(buttonRow)
        }

        completion(rows)

    }

    func setupForm() {
        let seenOptions = [
                "Last Hour",
                "Today",
                "Last Week",
                "Last Month",
                "All Time"
        ]

        form +++ Section("Seen")
        <<< PushRow<String>() {
            $0.tag = "seenFilter"
            $0.options = seenOptions.map({ $0.translate() })
        }.onChange { row in
            //print(row.value ?? "No Value")
            if let value = row.value {
                if let selected = seenOptions.filter({ $0.translate() == value }).first {
                    FirebasePrefsManager.sharedInstance.save("seenFilter", value: selected)
                    self.display("0")
                }
            }
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
            if let saved = FirebasePrefsManager.sharedInstance.pref("seenFilter") {
                row.value = (saved as! String).translate()
            } else {
                row.value = "Last Month".translate()
            }
        }
        +++ Section()

        self.tableView?.backgroundColor = UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0)
        self.tableView?.separatorColor = UIColor.clear
    }

    func setupLabelRowStyles(_ cell: BaseCell, row: BaseRow) {
        cell.textLabel?.font = UIFont(name: ToucheApp.Fonts.Light.montserrat, size: ToucheApp.Fonts.Sizes.medium)
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.font = UIFont(name: ToucheApp.Fonts.Light.montserrat, size: ToucheApp.Fonts.Sizes.medium)
    }

    func setupSwitchRowStyles(_ cell: BaseCell, row: SwitchRow) {
        cell.backgroundColor = UIColor(red: 0.23, green: 0.23, blue: 0.27, alpha: 1.00)
        cell.tintColor = UIColor.white
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 0.66, green: 0.04, blue: 0.05, alpha: 1.0)
        cell.selectedBackgroundView = bgColorView
        cell.textLabel?.font = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: ToucheApp.Fonts.Sizes.medium)
        cell.textLabel?.textColor = UIColor.white
    }

    func setupButtonRowStyles(_ cell: BaseCell, row: BaseRow) {
        cell.backgroundColor = UIColor(red: 0.23, green: 0.23, blue: 0.27, alpha: 1.00)
        cell.tintColor = UIColor.white
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 0.66, green: 0.04, blue: 0.05, alpha: 1.0)
        cell.selectedBackgroundView = bgColorView
        cell.textLabel?.font = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: ToucheApp.Fonts.Sizes.medium)
        cell.textLabel?.textColor = UIColor.white
    }
}

class EurekaLogoView: UIView {

    var tagListView: TagListView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        tagListView = TagListView(frame: frame)
        tagListView.autoresizingMask = .flexibleWidth
        tagListView.contentMode = .scaleAspectFit

        tagListView.textFont = UIFont(name: ToucheApp.Fonts.Light.montserrat, size: ToucheApp.Fonts.Sizes.medium)!
        tagListView.cornerRadius = 2.0
        tagListView.paddingX = 1.0
        tagListView.paddingY = 1.0
        tagListView.borderWidth = 0.1

        self.addSubview(tagListView!)


//        let imageView = UILabel()
//        imageView.text = "Heeeeeyyyy!!!!"
//        imageView.frame = CGRect(x: 0, y: 0, width: 320, height: 130)
//        imageView.autoresizingMask = .FlexibleWidth
//
//        self.frame = CGRect(x: 0, y: 0, width: 320, height: 130)
//        imageView.contentMode = .ScaleAspectFit
//        self.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addLabel(_ name: String) {
        if let tlv: TagListView = tagListView {
            tlv.addTag(name)
        }
    }

    func tapOnKeywordHashtag(_ sender: UIGestureRecognizer) {
        let label = (sender.view as! UILabel)
        print("Tag: \(label.tag) -> Key \(label.text!)")
        if let tlv: TagListView = tagListView {
            tlv.removeTag(label.text!)
        }
    }

    func longPressOnKeywordHashtag(_ sender: UIGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if let label = sender.view as? UILabel, let keyword = label.text {
                print("Tag: \(label.tag) -> Long Press Key \(keyword)")
//                if let tlv: TagListView = tagListView {
//                    tlv.removeTag(label)
//                }
            }
        }
    }
}



