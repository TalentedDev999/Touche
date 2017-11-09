//
// Created by Lucas Maris on 2/15/17.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Eureka
import PopupDialog

class AdvancedSearch: FormViewController {

    var popup: PopupDialog?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.isNavigationBarHidden = false

        Utils.setViewBackground(self.view)
        Utils.navigationControllerSetup(self.navigationController)

        let seenOptions = [
                "Last Hour",
                "Today",
                "Last Week",
                "Last Month",
                "All Time"
        ]

        form +++ Section()
//                <<< SwitchRow() {
//            $0.title = "Photos Only"
//            $0.tag = "picF ilter"
//        }.onChange { row in
//            if let value = row.value {
//                FirebasePrefsManager.sharedInstance.save("picFilter", value: String(value))
//            }
//        }.cellSetup() { cell, row in
//            self.setupSwitchRowStyles(cell, row: row)
//            if let saved = FirebasePrefsManager.sharedInstance.pref("picFilter") {
//                row.value = NSString(string: saved).boolValue
//            } else {
//                row.value = true
//            }
//        }.cellUpdate { cell, row in
//            self.setupSwitchRowStyles(cell, row: row)
//        }
                +++ Section()
                <<< PickerInlineRow<String>() {
            $0.tag = "seenFilter"
            $0.options = seenOptions.map({ $0.translate() })
        }.onChange { row in
            //print(row.value ?? "No Value")
            if let value = row.value {
                if let selected = seenOptions.filter({ $0.translate() == value }).first {
                    FirebasePrefsManager.sharedInstance.save("seenFilter", value: selected)
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
