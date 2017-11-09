//
//  SoundManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 10/12/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation.AVPlayer
import SwiftySound

class SoundManager {
    
    static let sharedInstance = SoundManager()

    internal struct Sounds {
        static let breakup = "sound_breakup"
        static let moderationApproved = "sound_moderation_approved"
        static let moderationDeclined = "sound_moderation_declined"
        //static let error = "sound_error"
        static let match = "sound_match"
        static let newMessage = "sound_new_message"
        static let newPictureMessage = "sound_new_picture_message"
        static let rat = "sound_mouse"
        static let menu = "sound_menu"
        static let chicken = "sound_dismiss"
        static let swoosh = "sound_swoosh"
        static let swoosh2 = "sound_throw"
        static let wave = "sound_wave"
        static let warp = "sound_warp"
        static let snap = "sound_snap"
        static let whip = "sound_whip"
        static let typing = "sound_typing"
        static let reply = "sound_reply"
        static let chest = "sound_chest"
        static let upload = "sound_upload"

        static let bombBlow = "Bomb_Blow"
        static let boomerangFly = "Boomerang_Fly"
        static let bottleOpen = "Bottle_Open"
        static let bottleSwing2 = "Bottle_Swing2"
        static let chuChuDieWobble = "ChuChu_DieWobble"
        static let error = "Error"
        static let fanfareNewSong = "Fanfare_NewSong"
        static let getHeart = "Get_Heart"
        static let getItem = "Get_Item"
        static let glow = "Glow"
        static let gong = "Gong"
        static let mainMenuLetter = "MainMenu_Letter"
        static let mainMenuLetterBack = "MainMenu_Letter_Back"
        static let pauseMenuClose = "PauseMenu_Close"
        static let pauseMenuCursor = "PauseMenu_Cursor"
        static let pauseMenuEquip = "PauseMenu_Equip"
        static let pauseMenuQuit = "PauseMenu_Quit"
        static let pauseMenuSave = "PauseMenu_Save"
        static let pictoBoxErase = "PictoBox_Erase"
        static let pictoBoxSave = "PictoBox_Save"
        static let pictoBoxSnap = "PictoBox_Snap"
        static let pigGrunt = "Pig_Grunt"
        static let textboxBegin = "Textbox_Begin"
        static let textboxClose = "Textbox_Close"
        static let textboxComplete = "Textbox_Complete"
        static let textboxNext = "Textbox_Next"
        static let textboxOpen = "Textbox_Open"
        static let textboxQuestion = "Textbox_Question"
        static let textboxQuestion_No = "Textbox_Question_No"
        
    }
    
    func playSound(_ soundName: String) {
//        Utils.executeInMainThread {
//            if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") {
//                var mySound: SystemSoundID = 0
//                AudioServicesCreateSystemSoundID(soundURL, &mySound)
//                // Play
//                AudioServicesPlaySystemSound(mySound);
//            }
//        }
        Sound.play(file: "\(soundName).wav")
    }
    
}
