//
//  AWSLambdaManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import AWSLambda
import Alamofire
import CryptoSwift
import SwiftyJSON

public typealias AWSLambdaCompletionHandler = ((_ result: AnyObject?, _ exception: NSException?, _ error: Error?) -> Void)?

class AWSLambdaManager {

    //MARK: Properties

    static let sharedInstance = AWSLambdaManager()

    struct RequestTokens {
        static let name = "GetToken"

        struct Params {
            static let toucheUUID = "identityId"
            static let identityId = "identityId"
        }

        struct Response {
            static let algoliaToken = "algoliaToken"
            static let firebaseToken = "firebaseToken"
            static let twilioToken = "twilioToken"
        }

    }

    struct ValidateReceipt {
        static let name = "ValidateReceipt"

        struct Params {
            static let receipt = "receipt"
            static let env = "env"
        }

        struct Response {
            static let message = "message"
            static let status = "status"
            static let statusCode = "statusCode"
        }

    }

    struct NearbyProfiles {
        static let name = "NearbyProfiles"

        struct Params {
            static let lat = "lat"
            static let lon = "lon"
            static let preset = "preset"
            static let seen = "seen"
            static let version = "version"
            static let within = "within"
            static let size = "size"
            static let predicate = "predicate"
        }

        struct Response {
            static let uuids = "uuids"
            static let profiles = "profiles"
        }

    }

    struct GetPopup {
        static let name = "GetPopup"

        struct Params {
            static let lat = "lat"
            static let lon = "lon"
            static let locale = "locale"
            static let version = "version"
        }

        struct Response {
            static let id = "id"
            static let title = "title"
            static let message = "message"
            static let imgS3Key = "imgS3Key"
            static let okButtonText = "okButtonText"
            static let okButtonAction = "okButtonAction"
            static let cancelButtonText = "cancelButtonText"
            static let cancelButtonAction = "cancelButtonAction"
        }

    }

    struct GetNeighborhood {
        static let name = "GetNeighborhood"

        struct Params {
            static let lat = "lat"
            static let lon = "lon"
        }

    }

    struct UpdateLocation {
        static let name = "UpdateLocation"

        struct Params {
            static let lat = "lat"
            static let lon = "lon"
        }

    }

    struct Lists {
        static let name = "Lists"

        struct Params {
            static let id = "id"
            static let direction = "direction"
            static let uuids = "uuids"
        }

    }

    struct TranslateText {
        static let name = "TranslateText"

        struct Params {
            static let message = "message"
            static let language = "language"
        }

    }

    struct GetProfiles {
        static let name = "GetProfiles"

        struct Params {
            static let uuids = "uuids"
        }

    }

    struct Facets {
        static let name = "Facets"

        struct Params {
            static let id = "id"
            static let seen = "seen"
        }

    }

    struct Chat {
        static let name = "Chat"

        struct Params {
            static let action = "action"
            static let targetId = "targetId"
        }

    }

    fileprivate var invoker: AWSLambdaInvoker

    // MARK: Constructor

    fileprivate init() {
        invoker = AWSLambdaInvoker.default()
    }

    // MARK: - Helpers

    func invokeFunctionOnLocal(_ functionName: String, parameters: [String: Any], completion: AWSLambdaCompletionHandler) {
        let start = Date()

        var p = parameters

        p["\(NearbyProfiles.Params.version)"] = UserManager.sharedInstance.version()
        p["identity_id"] = CognitoManager.sharedInstance.credentialsProvider.identityId
        p["identity_pool_id"] = CognitoManager.sharedInstance.getIdentityPoolId()

        print("invoking \(functionName)=>\(parameters)")

        Alamofire.request("https://127k.fwd.wf/lambda/\(functionName)", method: .post, parameters: p, encoding: JSONEncoding.default).responseJSON { response in

            print("Request: \(String(describing: response.request))")
            print("Response: \(String(describing: response.response))")
            //print("Result: \(response.result)")

            if let json = response.result.value {
                //print("JSON: \(json)") // serialized json response
                if let completion = completion {
                    completion(json as! AnyObject, nil, nil)
                }
            }

        }

    }

    func invokeFunctionOnAWS(_ functionName: String, parameters: [String: Any], completion: AWSLambdaCompletionHandler) {
        let start = Date()

        // copy params

        var p = parameters
        p["\(NearbyProfiles.Params.version)"] = UserManager.sharedInstance.version()
//        p["identity_id"] = CognitoManager.sharedInstance.credentialsProvider.identityId
//        p["identity_pool_id"] = CognitoManager.sharedInstance.getIdentityPoolId()
//

        let json = JSON(p)
        let representation = json.rawString([.castNilToNSNull: true])

        let req: [String: Any] = [
                "functionName": functionName,
                "payload": representation!
        ]

        print("invoking \(functionName)=>\(p)")

        print(req)

        invoker.invokeFunction("Universal", jsonObject: req).continueWith { (task) -> AnyObject? in

            if let error = task.error {
                let errorMsg = error.localizedDescription
                print("AWSLambdaManager invokeFunction Error: \(errorMsg) \(task)")

                if let completion = completion {
                    completion(nil, nil, error)
                }

                return nil
            }

            if let result = task.result, let completion = completion {

                let end = NSDate()
                let timeInterval: Double = end.timeIntervalSince(start)
                print("Time to execute \(functionName) lambda: \(timeInterval) seconds")

                print(result)

                if let dataFromString = "\(result)".data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    let json = try! JSON(data: dataFromString)

                    Utils.executeInMainThread {
                        completion(json as AnyObject, nil, nil)
                    }
                }

            }

            return task
        }
    }

    func invokeFunction(_ functionName: String, parameters: [String: Any], completion: AWSLambdaCompletionHandler) {

        // todo: setup caching here

        if let savedValue = FirebasePrefsManager.sharedInstance.pref("lambda_local") {
            if savedValue as! String == "true" {
                self.invokeFunctionOnLocal(functionName, parameters: parameters, completion: completion)
            } else {
                self.invokeFunctionOnAWS(functionName, parameters: parameters, completion: completion)
            }
        } else {
            self.invokeFunctionOnAWS(functionName, parameters: parameters, completion: completion)
        }
    }

    // MARK: Methods

    func getPopup(_ lat: Double, lon: Double, locale: String, version: String, completion: AWSLambdaCompletionHandler) {
        let functionName = GetPopup.name
        let parameters: [String: Any] = [
            GetPopup.Params.lat: lat,
            GetPopup.Params.lon: lon,
            GetPopup.Params.locale: locale,
            GetPopup.Params.version: version
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func requestTokens(_ toucheUUID: String, completion: AWSLambdaCompletionHandler) {
        let functionName = RequestTokens.name

        if let identityId = CognitoManager.sharedInstance.getIdentityId() {
            let parameters = [
                RequestTokens.Params.identityId: identityId
            ]

            invokeFunction(functionName, parameters: parameters, completion: completion)
        }

    }

    func getProfiles(_ uuids: [String], completion: AWSLambdaCompletionHandler) {
        let functionName = GetProfiles.name
        let parameters = [
            GetProfiles.Params.uuids: uuids,
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func validateReceipt(_ receiptData: String, env: String, completion: AWSLambdaCompletionHandler) {
        let functionName = ValidateReceipt.name
        let parameters = [
            ValidateReceipt.Params.receipt: receiptData,
            ValidateReceipt.Params.env: env
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func nearbyProfiles(_ lat: Double, lon: Double, preset: String, predicate: String = "", completion: AWSLambdaCompletionHandler) {
        let functionName = NearbyProfiles.name

        var seenFilter = "All time"
        if let savedValue = FirebasePrefsManager.sharedInstance.pref("seenFilter") {
            seenFilter = savedValue as! String
        }

        var within: [String] = FirebasePrefsManager.sharedInstance.within

        let parameters: [String: Any] = [
            NearbyProfiles.Params.lat: lat,
            NearbyProfiles.Params.lon: lon,
            NearbyProfiles.Params.preset: preset,
            NearbyProfiles.Params.seen: seenFilter,
            NearbyProfiles.Params.within: within,
            NearbyProfiles.Params.predicate: predicate,
            NearbyProfiles.Params.size: 5
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func initChat(_ targetId: String, completion: AWSLambdaCompletionHandler) {
        let functionName = Chat.name
        let parameters = [
            Chat.Params.action: "init",
            Chat.Params.targetId: targetId
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func listChannels(completion: AWSLambdaCompletionHandler) {
        let functionName = Chat.name
        let parameters = [
            Chat.Params.action: "list"
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func getNeighborhood(_ latitude: Double, longitude: Double, completion: AWSLambdaCompletionHandler) {
        let functionName = GetNeighborhood.name
        let parameters = [
            GetNeighborhood.Params.lat: latitude,
            GetNeighborhood.Params.lon: longitude
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func updateLocation(_ latitude: Double, longitude: Double, completion: AWSLambdaCompletionHandler) {
        let functionName = UpdateLocation.name
        let parameters = [
            UpdateLocation.Params.lat: latitude,
            UpdateLocation.Params.lon: longitude
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func translateText(_ message: String, locale: String, completion: AWSLambdaCompletionHandler) {
        let functionName = TranslateText.name
        let parameters = [
            TranslateText.Params.message: message,
            TranslateText.Params.language: locale
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func getLists(_ completion: AWSLambdaCompletionHandler) {
        let functionName = Lists.name

        let parameters = [
            Lists.Params.direction: "get",
            Lists.Params.id: "like"
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func updateLists(_ direction: String, id: String, uuids: [String], completion: AWSLambdaCompletionHandler) {
        let functionName = Lists.name

        let parameters: [String: Any] = [
            Lists.Params.direction: direction,
            Lists.Params.id: id,
            Lists.Params.uuids: uuids
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func facets(_ id: String, completion: AWSLambdaCompletionHandler) {
        let functionName = Facets.name

        var seenFilter = "Last Month"
        if let savedValue = FirebasePrefsManager.sharedInstance.pref("seenFilter") {
            seenFilter = savedValue as! String
        }

        let parameters = [
            Facets.Params.id: id,
            Facets.Params.seen: seenFilter
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

    func fetchLists(completion: AWSLambdaCompletionHandler) {
        let functionName = Lists.name

        let parameters: [String: Any] = [
            Lists.Params.direction: "read"
        ]

        invokeFunction(functionName, parameters: parameters, completion: completion)
    }

}
