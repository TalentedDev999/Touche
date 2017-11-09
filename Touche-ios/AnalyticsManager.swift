//
//  AnalyticsManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 3/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import AWSMobileAnalytics
import TreasureData_iOS_SDK
import Crashlytics
import UIKit

class AnalyticsManager {

    // MARK: - Properties

    static let sharedInstance = AnalyticsManager()

    struct FieldsToLog {
        static let UUID = "UUID"
        static let TargetUUID = "TARGET_UUID"
        static let EventId = "EVENT_ID"
        static let GeoHash = "GEO_HASH"
        static let Lat = "LAT"
        static let Lon = "LON"
        static let AppName = "APP_NAME"
        static let ProvisioningProfileName = "PPRF_NAME"
        static let Lang = "LANG"
        static let PurchaseRestored = "PURCHASE_RESTORED"
        static let PurchaseAttempt = "PURCHASE_ATTEMPT"
        static let PurchaseSuccess = "PURCHASE_SUCCESS"
        static let PurchaseWasCancelled = "PURCHASE_CANCELLED"
        static let SigninFbId = "SIGNIN_FB_ID"
        static let SigninFbEmail = "SIGNIN_FB_EMAIL"
        static let LogoutFb = "LOGOUT_FB"
    }

    // FIXME: more hardcoded keys!!!

    fileprivate let awsAppId = "d485c910b1d64b86a0e5c4241f546d68"

    fileprivate let treasureDataAPIKey = "8782/b951ae49bee0c79f898e90635b714e661d340559"
    // Write-only key

    fileprivate struct TreasureDataModel {
        static let databaseName = "toucheapp"

        struct Tables {
            static let event = "event"
        }

    }

    fileprivate let awsAnalytics: AWSMobileAnalytics
    fileprivate let awsEventClient: AWSMobileAnalyticsEventClient

    fileprivate let tdClient: TreasureData

    // MARK: - Init Methods

    fileprivate init() {
        awsAnalytics = AWSMobileAnalytics(forAppId: awsAppId, identityPoolId: CognitoManager.identityPoolId)
        awsEventClient = awsAnalytics.eventClient

        TreasureData.enableLogging()
        TreasureData.initialize(withApiKey: treasureDataAPIKey)

        tdClient = TreasureData.sharedInstance()
        initTreasureData()

        print("AnalyticsManager was instantiated")
    }

    func initialize() {
    }

    fileprivate func initTreasureData() {
        tdClient.defaultDatabase = TreasureDataModel.databaseName

        tdClient.enableAutoAppendUniqId()
        tdClient.enableAutoAppendAppInformation()
        tdClient.enableAutoAppendModelInformation()
        tdClient.enableAutoAppendLocaleInformation()

        tdClient.disableRetryUploading()
        tdClient.startSession(TreasureDataModel.Tables.event, database: TreasureDataModel.databaseName)
    }

    // MARK: - Helper Methods

    // MARK: - AWS

    // submitEvents = true force to upload the events to AWS
    fileprivate func recordCustomEventToAWS(_ event: String,
                                        withAttributes attrs: [String: String]? = nil,
                                        withMetrics metrics: [String: NSNumber]? = nil,
                                        submitEvents: Bool = false) {

        let customEvent = awsEventClient.createEvent(withEventType: event)

        if let attrs = attrs {
            for (key, value) in attrs {

                if let customEvent = customEvent {
                    customEvent.addAttribute(value, forKey: key)
                }
            }
        }

        if let metrics = metrics {
            for (key, value) in metrics {
                if let customEvent = customEvent {
                    customEvent.addMetric(value, forKey: key)
                }
            }
        }

        awsEventClient.record(customEvent)

        // Events will automatically be submitted at periodic intervals If don’t call submitEvents,
        if submitEvents {
            awsEventClient.submitEvents()
        }
    }

    // MARK: - Treasure Data

    fileprivate func recordCustomEventToTreasureData(_ record: [AnyHashable: Any], database: String? = nil, table: String? = nil) {
        let tdDatabase = database != nil ? database : TreasureDataModel.databaseName
        let tdTable = table != nil ? table : TreasureDataModel.Tables.event

        tdClient.addEvent(record, database: tdDatabase, table: tdTable)
    }

    fileprivate func getTreasureDataRecordFrom(_ attributes: [String: String]? = nil, metrics: [String: NSNumber]? = nil) -> [AnyHashable: Any]? {
        var record = [AnyHashable: Any]()

        if let attrs = attributes {
            for (key, value) in attrs {
                record[key] = value
            }
        }

        if let mtrs = metrics {
            for (key, value) in mtrs {
                record[key] = value
            }
        }

        return record.isEmpty ? nil : record
    }

    fileprivate func uploadTreasureDataEventsInBackground(_ endSessionWhenFinish: Bool = false) {

        let application = UIKit.UIApplication.shared
        var tdBgTask: UIBackgroundTaskIdentifier = 0

        tdBgTask = application.beginBackgroundTask(withName: "tdBgTask", expirationHandler: { () -> Void in
            application.endBackgroundTask(tdBgTask)
            tdBgTask = UIBackgroundTaskInvalid
        })

        tdClient.uploadEvents(callback: { [weak self] in
            print("uploadTreasureDataEvents succeed")
            application.endBackgroundTask(tdBgTask)
            tdBgTask = UIBackgroundTaskInvalid

            if endSessionWhenFinish {
                self?.tdClient.endSession(TreasureDataModel.Tables.event, database: TreasureDataModel.databaseName)
            }

        }) { [weak self] (errorCode, message) in
            print("Treasure Data UploadEvents error: \(errorCode) \(message)")
            application.endBackgroundTask(tdBgTask)
            tdBgTask = UIBackgroundTaskInvalid

            if endSessionWhenFinish {
                self?.tdClient.endSession(TreasureDataModel.Tables.event, database: TreasureDataModel.databaseName)
            }
        }
    }

    // MARK: - Methods

    func recordCustomEventToAWSAndTreasureData(_ event: String,
                                               attrs: [String: String]? = nil,
                                               metrics: [String: NSNumber]? = nil,
                                               submitEvents: Bool = false,
                                               treasureDataDatabase: String? = nil,
                                               treasureDataTable: String? = nil) {

        // Record to Amazon
        recordCustomEventToAWS(event, withAttributes: attrs, withMetrics: metrics, submitEvents: submitEvents)

        if let treasureDataRecord = getTreasureDataRecordFrom(attrs, metrics: metrics) {
            // Record to TreasureData
            // Use default database and table if treasureDatabase & treasureTable = nil
            recordCustomEventToTreasureData(treasureDataRecord, database: treasureDataDatabase, table: treasureDataTable)
        }
    }

    func logEvent(_ eventId: String, withTarget: String? = nil) {
        guard let uuid = UserManager.sharedInstance.toucheUUID else {
            return
        }

        guard "PRODUCTION" == IAPManager.sharedInstance.getEnv() else {
            return
        }

        let provisioningProfileName = ProvisioningProfile.sharedProfile.name
        let provisioningProfileAppName = ProvisioningProfile.sharedProfile.appName
        let currentLanguage = Utils.getCurrentLanguage()

        var awsEventAttrs = [
                FieldsToLog.UUID: uuid
        ]

        if let targetUUID = withTarget {
            awsEventAttrs[FieldsToLog.TargetUUID] = targetUUID
        }

        let currentLat = CoreLocationManager.sharedInstance.getCurrentLatitude()
        let currentLon = CoreLocationManager.sharedInstance.getCurrentLongitude()

        if provisioningProfileName != "" {
            awsEventAttrs[FieldsToLog.ProvisioningProfileName] = provisioningProfileName
        }

        if provisioningProfileAppName != "" {
            awsEventAttrs[FieldsToLog.AppName] = provisioningProfileAppName
        }

        if let currentLanguage = currentLanguage {
            awsEventAttrs[FieldsToLog.Lang] = currentLanguage
        }

        if let currentLat = currentLat {
            let lat = String(currentLat)
            awsEventAttrs[FieldsToLog.Lat] = lat
        }

        if let currentLon = currentLon {
            let lon = String(currentLon)
            awsEventAttrs[FieldsToLog.Lon] = lon
        }

        if currentLat != nil && currentLon != nil {
            let geoHash = GeohashManager.encode(currentLat!, longitude: currentLon!, length: 12)
            awsEventAttrs[FieldsToLog.GeoHash] = geoHash
        }

        // Record to Answers
        Answers.logCustomEvent(withName: eventId, customAttributes: awsEventAttrs)

        // Log to Amazon
        recordCustomEventToAWS(eventId, withAttributes: awsEventAttrs)

        var tdRecord = awsEventAttrs
        tdRecord[FieldsToLog.EventId] = eventId

        // Log to Treasure Data
        recordCustomEventToTreasureData(tdRecord)
    }

    func logEventWith(_ targetUUID: String, eventId: String) {
        guard let uuid = UserManager.sharedInstance.toucheUUID else {
            return
        }

        guard "PRODUCTION" == IAPManager.sharedInstance.getEnv() else {
            return
        }

        let provisioningProfileName = ProvisioningProfile.sharedProfile.name
        let provisioningProfileAppName = ProvisioningProfile.sharedProfile.appName
        let currentLanguage = Utils.getCurrentLanguage()

        let currentLat = CoreLocationManager.sharedInstance.getCurrentLatitude()
        let currentLon = CoreLocationManager.sharedInstance.getCurrentLongitude()

        var awsEventAttrs = [
                FieldsToLog.UUID: uuid,
                FieldsToLog.TargetUUID: targetUUID,
        ]

        if provisioningProfileName != "" {
            awsEventAttrs[FieldsToLog.ProvisioningProfileName] = provisioningProfileName
        }

        if provisioningProfileAppName != "" {
            awsEventAttrs[FieldsToLog.AppName] = provisioningProfileAppName
        }

        if let currentLanguage = currentLanguage {
            awsEventAttrs[FieldsToLog.Lang] = currentLanguage
        }

        if let currentLat = currentLat {
            let lat = String(currentLat)
            awsEventAttrs[FieldsToLog.Lat] = lat
        }

        if let currentLon = currentLon {
            let lon = String(currentLon)
            awsEventAttrs[FieldsToLog.Lon] = lon
        }

        if currentLat != nil && currentLon != nil {
            let geoHash = GeohashManager.encode(currentLat!, longitude: currentLon!, length: 12)
            awsEventAttrs[FieldsToLog.GeoHash] = geoHash
        }

        // Record to Answers
        Answers.logCustomEvent(withName: eventId, customAttributes: awsEventAttrs)

        // Log to Amazon
        recordCustomEventToAWS(eventId, withAttributes: awsEventAttrs)

        var tdRecord = awsEventAttrs
        tdRecord[FieldsToLog.EventId] = eventId

        // Log to Treasure Data
        recordCustomEventToTreasureData(tdRecord)
    }

    func recordConsumeEvent() {

    }

    func applicationDidEnterBackground() {
        uploadTreasureDataEventsInBackground()
    }

    func applicationWillTerminate() {
        uploadTreasureDataEventsInBackground(true)
    }

}
