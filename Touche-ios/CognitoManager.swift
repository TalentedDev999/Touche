//
//  CognitoManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import AWSCognito

class CognitoManager {

    // MARK: Properties

    static let sharedInstance: CognitoManager = CognitoManager()

    static let identityPoolId = "us-east-1:d6fc5f4b-59d1-49b5-9535-f643d5d6e84e"
    // fixme: cannot be hardcoded here

    struct Dataset {
        static let name = "touche"

        struct Keys {
            static let UUID = "uuid"
            static let layerNonce = "nonce"
        }

    }

    var credentialsProvider: AWSCognitoCredentialsProvider

    fileprivate var client: AWSCognito

    // MARK: Constructor

    fileprivate init() {
        credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: CognitoManager.identityPoolId)

        let serviceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration

        AWSLogger.default().logLevel = .none
        client = AWSCognito.default()
    }

    // MARK: Methods

    func getIdentityId() -> String? {
        return credentialsProvider.identityId
    }

    fileprivate func getIdentityIdAsync(_ completion: @escaping (String?) -> Void) {
        credentialsProvider.getIdentityId().continueWith { (task) -> AnyObject? in
            if task.error != nil {
                completion(nil)
                return nil
            }

            if task.isCancelled {
                completion(nil)
                return nil
            }

            if let cognitoIdentityId = task.result as String? {
                completion(cognitoIdentityId)
            }

            return nil
        }
    }


//    func getUUIDFromRemote(_ uuidKey: String, datasetName: String, completion: (String?) -> Void) {
//        synchronize(datasetName) { (task) -> AnyObject? in
//            completion(self.getToucheUUIDFromLocal(uuidKey, datasetName: datasetName))
//        }
//    }

//    fileprivate func createNewToucheUUID(_ uuidKey: String, datasetName: String) {
//        let newToucheUUID = Utils.getRandomUUID()
//        setValueForKeyToDataset(newToucheUUID, key: uuidKey, datasetName: datasetName, sync: true) { (task) -> AnyObject? in
//            return nil
//        }
//        //completion(newToucheUUID)
//    }

//    fileprivate func savePreviousUUIDIntoNewIdentity(_ uuidKey: String, datasetName: String) {
//        guard let toucheUUID = UserManager.sharedInstance.toucheUUID else {
//            return
//        }
//        setValueForKeyToDataset(toucheUUID, key: uuidKey, datasetName: datasetName, sync: true)
//    }

    /*
     * Try to get identity from the local database
     * Try to get it from the cloud if it's not in local
     */
    func getIdentityId(_ completion: @escaping (String) -> Void) {
        if let identityId = getIdentityId() {
            completion(identityId)
            return
        }

        getIdentityIdAsync { (identityId) in
            if let identityId = identityId {
                completion(identityId)
            }
        }
    }

    /*
     * Try to get 'ToucheUUID' from local Cognito cache
     * Try to get 'ToucheUUID' from remote if isn't in Cognito local cache
     * Create a new 'ToucheUUID' if it does not exist neither in local and remote
     */
    public func getToucheUUID() {

        // todo: we could store the id in userdefaults

        print("IdentityId: \(String(describing: self.getIdentityId()))")

        let uuidKey = Dataset.Keys.UUID
        let datasetName = Dataset.name

        let dataset: AWSCognitoDataset = client.openOrCreateDataset(datasetName)
        dataset.synchronizeOnConnectivity().continueWith(block: { (task: AWSTask) -> Void in
            if !task.isFaulted {
                if let toucheUUID = dataset.string(forKey: uuidKey) {
                    print("ToucheUUID was found: \(toucheUUID)")
                    UserManager.sharedInstance.toucheUUID = toucheUUID
                } else {
                    let newToucheUUID = Utils.getRandomUUID()
                    print("generating new ToucheUUID: \(newToucheUUID)")
                    dataset.setString(newToucheUUID, forKey: uuidKey)
                    dataset.synchronize()
                    UserManager.sharedInstance.toucheUUID = newToucheUUID
                }
            }
        })


//        self.synchronize(datasetName) { (task) -> AnyObject? in
//            if let toucheUUID = getValueForKeyFromDataset(uuidKey, datasetName: datasetName) {
//                print("ToucheUUID was found in Cognito local cache: \(toucheUUID)")
//                UserManager.sharedInstance.toucheUUID = toucheUUID
//                return
//            } else {
//                print("ToucheUUID not found")
//            }
//        }

    }

    func getIdentityPoolId() -> String? {
        return credentialsProvider.identityPoolId
    }

//    func synchronize(_ dataset: AWSCognitoDataset, completion: AWSContinuationBlock) -> Void {
//        dataset.synchronizeOnConnectivity().continueWithBlock(completion)
//    }
//
//    func synchronize(_ datasetName: String, completion: AWSContinuationBlock) -> Void {
//        let dataset: AWSCognitoDataset = client.openOrCreateDataset(datasetName)
//        synchronize(dataset, completion: completion)
//    }
//
//    func getValueForKeyFromDataset(_ key: String, datasetName: String) -> String? {
//        let dataset = client.openOrCreateDataset(datasetName)
//        return dataset.string(forKey: key)
//    }
//
//    func setValueForKeyToDataset(_ value: String, key: String, datasetName: String, sync: Bool = false, completion: AWSContinuationBlock? = nil) -> Void {
//        let dataset: AWSCognitoDataset = client.openOrCreateDataset(datasetName)
//        dataset.setString(value, forKey: key)
//
//        if sync && completion != nil {
//            synchronize(dataset, completion: completion!)
//        }
//    }
//
//    func removeObjectForKeyFromDataset(_ key: String, datasetName: String, sync: Bool = false, completion: AWSContinuationBlock? = nil) -> Void {
//        let dataset: AWSCognitoDataset = client.openOrCreateDataset(datasetName)
//        dataset.removeObject(forKey: key)
//
//        if sync && completion != nil {
//            synchronize(dataset, completion: completion!)
//        }
//    }
//
//    func deleteDataset(_ datasetName: String, sync: Bool = false, completion: AWSContinuationBlock? = nil) -> Void {
//        let dataset: AWSCognitoDataset = client.openOrCreateDataset(datasetName)
//        dataset.clear()
//
//        if sync && completion != nil {
//            synchronize(dataset, completion: completion!)
//        }
//    }

//    fileprivate func clearKeyChain() -> Void {
//        credentialsProvider.clearKeychain()
//    }
//
//    func logout() -> Void {
//        credentialsProvider.clearCredentials()
//    }

}
