//
//  FirebaseBankManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/23/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase
import CryptoSwift

class FirebaseTranslationManager {
    
    static let sharedInstance = FirebaseTranslationManager()

    fileprivate var translationRef: DatabaseReference

    fileprivate var languageTable = [String: String]()

    init() {

        translationRef = Database.database().reference().child("translation").child(UserManager.sharedInstance.lang())

        translationRef.observe(.childAdded, with: {
            (snapshot) in
            if let translated = snapshot.value as? String {
                print("new translation added: \(snapshot.key)=\(translated)")
                self.languageTable[snapshot.key] = translated
            }
        })

        translationRef.observe(.childChanged, with: {
            (snapshot) in
            if let translated = snapshot.value as? String {
                print("new translation changed: \(snapshot.key)=\(translated)")
                self.languageTable[snapshot.key] = translated
            }
        })

    }

    func translate(_ message: String) -> String {
        if UserManager.sharedInstance.lang() == "en" {
            return message
        } else {
            if let translated = languageTable[message.md5()] {
                return translated
            } else {
                AWSLambdaManager.sharedInstance.translateText(message, locale: UserManager.sharedInstance.locale()) { result, exception, error in
                    print(result)
                }

                return message
            }
        }
    }

    func initialize() {

    }
}
