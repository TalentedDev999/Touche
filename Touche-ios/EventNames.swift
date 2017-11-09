//
//  NotificationNames.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

struct EventNames {
    
    struct Login {
        static let cognitoIdentityIdAvailable = "cognitoIdentityIdAvailable"
        static let toucheUUIDAvailable = "toucheUUIDAvailable"
        static let tokensReady = "tokensReady"
        static let firebaseReady = "firebaseReady"
        static let twilioReady = "twilioReady"
        static let iapReady = "iapReady"
        static let services_available = "login_services_available"
    }

    struct List {
        static let didChange = "listChangeEvent"
    }

    struct Location {
        struct AuthorizationChanged {
            static let authorizedWhenInUsed = "location_authorization_status_authorized_when_in_use"
            static let authorizedAlways = "location_authorization_status_authorized_always"
        }
        
        struct Dialog {
            static let dontAllow = "location_authorization_dialog_dontAllow"
        }
        
        static let newLocationAvailable = "location_new_location_available"
        static let freshPolygons = "fresh_polygons_available"
    }

    struct Permissions {
        static let permsAvailable = "permsAvailable"
        static let permsUnavailable = "permsUnavailable"
    }

    struct People {
        static let tapOnBubble = "people_tap_on_bubble"
        static let refresh = "refresh"
    }

    struct Popup {
        static let showPopup = "show_popup"
    }
        
    struct Profile {
        static let didChange = "profileChangeEvent"
        
        struct Cycles {
            static let cyclesDidChange = "profile_cycles_did_change"
        }
    }

    struct Chat {
        struct Conversations {
            static let wereRetrieved = "chat_conversations_were_retrieved"
            static let didChange = "chat_conversations_did_change"
        }
        
        struct UnreadMessages {
            static let totalUnreadMessagesDidChange = "chat_total_unread_messages_did_change"
            static let unreadMessagesDidChange = "chat_unread_messages_did_change"
        }
        
        struct Conversation {
            static let tapOnPicBubble = "chat_conversation_tap_on_pic_bubble"
            static let addNewPic = "chat_add_new_pic_to_image_viewer"
        }
        
        struct Profile {
            static let profileDidChange = "chat_profile_did_change"
        }
    }
    
    struct Games {
        static let tapOnAction = "new_game_from_pople"
        static let newGames = "new_game_created"
        static let started  = "game_started"
        
        struct Data {
            static let didChange = "games_data_did_change"
        }
    }

    struct Upgrade {
        static let subscriptionWereRetrieve = "upgrade_subscription_were_retrieve"
        static let subscriptionDidChange = "upgrade_subscription_did_change"
        static let buyButtonWasPressed = "upgrade_buy_button_was_pressed"
        static let transactionFinished = "upgrade_transaction_finished"
        static let transactionError = "upgrade_transaction_error"
    }

    struct BubbleCount {
        static let didOccur = "bubbleCountDidOccur"
    }
    
    struct MainTabBar {
        static let gotoPhotos = "main_tabbar_goto_photos"
        static let gotoChat = "main_tabbar_goto_chat"
        static let gotoProfile = "main_tabbar_goto_profile"
    }

    struct LifeEvents {
        static let didOccur = "didOccur"
        static let mutualLike = "mutualLike"
        static let breakUp = "breakUp"
    }
    
    struct Bank {
        static let usageDidChange = "bank_usage_did_change"
        static let overLimitEvent = "overLimitEvent"
    }
    
    struct ModerationPicture {
        static let fail = "moderation_picture_fail"
        static let success = "moderation_picture_success"
    }

}
