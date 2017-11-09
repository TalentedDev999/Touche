//
//  FacebookManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import SwiftyJSON

class FacebookManager {
    
    // MARK: - Properties
    
    static let sharedInstance = FacebookManager()
    
    enum PictureType {
        case small
        case normal
        case album
        case large
        case square
    }
    
    struct Permissions {
        static let fields = "fields"
        static let publicProfile = "public_profile"
        static let email = "email"
        static let friends = "user_friends"
        static let birthday = "user_birthday"
        static let photos = "user_photos"
    }
    
    struct GraphFields {
        static let id = "id"
        static let completeName = "name"
        static let firstName = "first_name"
        static let lastName = "last_name"
        static let email = "email"
        static let link = "link"
        static let picture = "picture"
        static let data = "data"
        static let url = "url"
    }

    fileprivate var loginMngr:FBSDKLoginManager
    fileprivate var userToken:FBSDKAccessToken?
    fileprivate var graphResponse:JSON
    
    // MARK: - Init Methods
    
    fileprivate init() {
        loginMngr = FBSDKLoginManager()
        userToken = FBSDKAccessToken.current()
        graphResponse = JSON([])
    }
    
    // MARK: - Helper Methods
    
    fileprivate func requestToken(_ viewController:UIViewController, completion: @escaping (Bool, String?) -> Void) {
        let permissions = [Permissions.publicProfile, Permissions.email, Permissions.birthday, Permissions.friends, Permissions.photos]
        
        loginMngr.logIn(withReadPermissions: permissions, from: viewController) { (result, error) in
            if error != nil {
                let errorMessage = error!.localizedDescription
                completion(false, errorMessage)
                return
            }
            
            if let result = result {

                if result.isCancelled {
                    completion(false, nil)
                    return
                }

                self.userToken = result.token
                // todo: send that token to the server side!!

                self.retrieveProfile(result.token, completion: completion)
            }


        }
    }
    
    fileprivate func retrieveProfile(_ userToken:FBSDKAccessToken, completion: @escaping (Bool, String?) -> Void) {
        let graphPath = userToken.userID
        let permissions = "\(GraphFields.id),\(GraphFields.completeName),\(GraphFields.firstName),\(GraphFields.lastName),\(GraphFields.email),\(GraphFields.picture)"
        let parameters = [Permissions.fields : permissions]
        let graphRequest = FBSDKGraphRequest(graphPath: graphPath, parameters: parameters)!
        
        graphRequest.start { (graphRequest, response, error) in
            if error != nil {
                let errorMessage = error!.localizedDescription
                completion(false, errorMessage)
                return
            }
            
            if response != nil {
                self.graphResponse = JSON(response!)
                completion(true, nil)
                return
            }
        }
    }
    
    // MARK: - Methods
    
    func getToken() -> FBSDKAccessToken? {
        return userToken
    }
    
    func startLoginProcces(viewController vc:UIViewController, completion: @escaping (Bool, String?) -> Void) {
        if userToken != nil {
            retrieveProfile(userToken!, completion: completion)
        } else {
            requestToken(vc, completion: completion)
        }
    }
    
    func retrieveProfile(_ completion: @escaping (Bool, String?) -> Void) {
        guard let userToken = userToken else { completion(false, nil); return }
        retrieveProfile(userToken, completion: completion)
    }
    
    func logOut() {
        loginMngr.logOut()
        userToken = nil
        graphResponse = JSON([])
    }
    
    func hasAValidToken() -> Bool {
        return userToken != nil
    }
    
    func isAlreadyLoggedin() -> Bool {
        return userToken != nil && graphResponse != nil
    }
    
    func getGraphResponse() -> JSON {
        return graphResponse
    }
    
    func getUserId() -> String? {
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: GraphFields.id)
    }
    
    func getUserEmail() -> String? {
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: GraphFields.email)
    }
    
    func getUserFirstName() -> String? {
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: GraphFields.firstName)
    }
    
    func getUserLastName() -> String? {
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: GraphFields.lastName)
    }
    
    func getUserCompleteName() -> String? {
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: GraphFields.completeName)
    }
    
    func getUserLink() -> String? {
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: GraphFields.link)
    }
    
    func getUserProfilePicURLString() -> String? {
        let pictureKey = GraphFields.picture
        let dataKey = GraphFields.data
        let urlKey = GraphFields.url
        
        return JsonManager.getStringValueFrom(graphResponse, forFirstKey: pictureKey, secondKey: dataKey, andThirdKey: urlKey)
    }
    
    func getUserProfilePicURL() -> URL? {
        guard let stringURL = getUserProfilePicURLString() else { return nil }
        return URL(string: stringURL)
    }
    
    func getProfilePicURLWith(_ type:PictureType) -> URL? {
        guard let fbId = userToken?.userID else { return nil }
        
        var strURL = "https://graph.facebook.com/\(fbId)/picture?type="
        
        switch type {
        case .small:
            strURL += "small"
        case .normal:
            strURL += "normal"
        case .album:
            strURL += "album"
        case .large:
            strURL += "large"
        case .square:
            strURL += "square"
        }
        
        return URL(string: strURL)
    }
    
    func getProfilePicURLWith(_ width:Int, height:Int) -> URL? {
        guard let fbId = userToken?.userID else { return nil }
        let strURL = "https://graph.facebook.com/\(fbId)/picture?width=\(width)&height=\(height)"
        return URL(string: strURL)
    }

    func showFBInvite(_ viewController:UIViewController) {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = URL(string: "https://fb.me/581792142018875")
        content.appInvitePreviewImageURL = URL(string: "https://s3.amazonaws.com/touche-assets/app_invite.jpg")
        FBSDKAppInviteDialog.show(from: viewController, with: content, delegate: viewController as! FBSDKAppInviteDialogDelegate)
    }


    
}
