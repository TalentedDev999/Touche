//
//  LoginManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/23/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class LoginManager {

    // MARK: - Cognito Services

    static func getCognitoIdentity() {
        let start = Date()
        CognitoManager.sharedInstance.getIdentityId {
            (cognitoIdentityId) in
            UserManager.sharedInstance.cognitoIdentityId = cognitoIdentityId
            let timeInterval: Double = Date().timeIntervalSince(start)
            print("Time to execute cognito: \(timeInterval) seconds")
        }
    }

    /*
     * Try to get 'ToucheUUID' from local Cognito cache
     * Try to get 'ToucheUUID' from remote if isn't in Cognito local cache
     * Create a new 'ToucheUUID' if it does not exist neither in local and remote
     */
    static func getToucheUUIDFromCognito() {
        CognitoManager.sharedInstance.getToucheUUID()
    }

    // MARK: - Algolia Services


    // MARK: - Firebase Services

    static func signinWithFirebase(_ firebaseToken: String) {
        FirebaseManager.sharedInstance.signInWithCustom(firebaseToken) {
            (User, error) in
            if error != nil {
                let errorMsg = error!.localizedDescription
                print(errorMsg)
                return
            }

            if let firebaseUser = User {
                UserManager.sharedInstance.firebaseUser = firebaseUser
            }
        }
    }

    // MARK: - Lambda Services

    static func refreshTokens(_ toucheUUID: String, completion: @escaping (Bool) -> Void) {
        // Only execute if we don't have a valid token stored
        AWSLambdaManager.sharedInstance.requestTokens(toucheUUID) {
            (result, exception, error) in
            if error != nil {
                let errorMsg = "Login Manager - requestTokens Error: \(error!.localizedDescription)"
                print(errorMsg)
                return
            }

            if exception != nil {
                let excMsg = "User Manager - requestTokens Exception: \(exception!.description)"
                print(excMsg)
                return
            }

            if result != nil {
                let jsonResult = JSON(result!)

                //print(jsonResult)

                let firebaseTokenKey = AWSLambdaManager.RequestTokens.Response.firebaseToken
                let firebaseToken = JsonManager.getStringValueFrom(jsonResult, forFirstKey: firebaseTokenKey)

                let twilioTokenKey = AWSLambdaManager.RequestTokens.Response.twilioToken
                let twilioToken = JsonManager.getStringValueFrom(jsonResult, forFirstKey: twilioTokenKey)

                UserManager.sharedInstance.firebaseToken = firebaseToken
                UserManager.sharedInstance.twilioToken = twilioToken

                completion(true)
                return
            }

            let errorMsg = "User Manager - Request Authentication"
            print(errorMsg)
            completion(false)
        }
    }

    /*
     * Request authentication Token from identity and nonce
     */
    static func requestTokens(_ toucheUUID: String) {
        self.refreshTokens(toucheUUID) { success in
            if success {
                MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.tokensReady)
            } else {
                print("failed refreshing tokens!")
            }
        }
    }

    /*
     * Check User state based on receipt
     */
    static func validateReceipt() {

    }

}
