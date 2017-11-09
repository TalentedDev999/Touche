//
//  FirebaseGameManager.swift
//  Touche-ios
//
//  Created by Ben LeBlond on 8/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase

class FirebaseGameManager {
    
    // MARK: - Properties
    
    static let sharedInstance = FirebaseGameManager()
    
    struct Database {
        struct Nodes {
            static let game = "game"
            static let gameData = "gameData"
            static let gameAction = "gameAction"
            static let gameReaction = "gameReaction"
        }
                
        struct Action {
            static let price = "price"
        }
        
        struct Game {
            static let id = "id"
            static let date = "date"
        }
    }
    
    private let toucheUUID:String

    private let gameRef: DatabaseReference
    private let gameActionRef: DatabaseReference
    private let gameReactionRef: DatabaseReference
    private let gameUserRef: DatabaseReference
    private let gameDataRef: DatabaseReference
    
    private var actionObserver:UInt?
    private var reactionObserver:UInt?
    private var draggingObserver:UInt?
    
    var gamesModel:[GameModel]
    var reactions:[String:ReactionModel]
    var mostRecentGameModel: GameModel?
    
    // MARK: - Methods
    
    private init() {
        toucheUUID = UserManager.sharedInstance.toucheUUID!
        gameRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.game)
        gameUserRef = FirebaseManager.sharedInstance.getReference(gameRef, childNames: toucheUUID)
        gameDataRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.gameData)
        gameActionRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.gameAction)
        gameReactionRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.gameReaction)
        gamesModel = [GameModel]()
        reactions = [String:ReactionModel]()
        mostRecentGameModel = nil
    }

    private func buildGameModelFrom(snapshot: DataSnapshot) -> GameModel? {
        guard let snapshotDict = snapshot.value as? [String:AnyObject] else {
            return nil
        }
        
        if let gameId = snapshotDict[Database.Game.id] as? String {
            let gameModel = GameModel(gameId: gameId, fromUUID: toucheUUID, toUUID: snapshot.key)
            return gameModel
        }
        
        return nil
    }

    private func buildGamesDataFrom(snapshot: DataSnapshot) {
        guard let snapshotDict = snapshot.value as? [String:[String:String]] else {
            return
        }
        
        var auxGameModel = [GameModel]()
        
        for game in snapshotDict {
            let opponentId = game.0
            if let gameId = game.1[Database.Game.id] {
                let newBubble = GameModel(gameId: gameId, fromUUID: toucheUUID, toUUID: opponentId)
                auxGameModel.append(newBubble)
            }
        }
        
        gamesModel = auxGameModel
    }
    
    private func appendNewGameModel(gameModel:GameModel) {
        for auxGameModel in self.gamesModel {
            if auxGameModel.gameId == gameModel.gameId {
                return
                
            }
        }
        
        self.gamesModel.append(gameModel)
        
        let gamesDataDidChangeEvent = EventNames.Games.Data.didChange
        MessageBusManager.sharedInstance.postNotificationName(gamesDataDidChangeEvent)
    }
    
    private func gameIdBetween(fromUUID:String, toUUID:String, completion:(String?) -> Void) {
        let gameRef1 = FirebaseManager.sharedInstance.getReference(gameRef, childNames: fromUUID.uppercaseString, toUUID.uppercaseString)
        
        gameRef1.observeSingleEventOfType(.Value, withBlock:  { (snapshot) in
            if snapshot.exists() {
                let gameId = snapshot.value?[Database.Game.id] as? String
                
                completion(gameId)
                return
            }
            completion(nil)
        })
    }
    
    private func createNewGameBetween(fromUUID:String, toUUID:String, completion:(String) -> Void) {
        let gameRef1 = FirebaseManager.sharedInstance.getReference(gameRef, childNames: fromUUID.uppercaseString, toUUID.uppercaseString)
        let gameRef2 = FirebaseManager.sharedInstance.getReference(gameRef, childNames: toUUID.uppercaseString, fromUUID.uppercaseString)
        
        let newGameDataRef = gameDataRef.childByAutoId()
        
        let dateValue = FIRServerValue.timestamp()

        let gameValue = [Database.Game.date : dateValue,
                            Database.Game.id : newGameDataRef.key]
        
        FirebaseManager.sharedInstance.setValue(gameRef1, value: gameValue)
        FirebaseManager.sharedInstance.setValue(gameRef2, value: gameValue)

        completion(newGameDataRef.key)
    }
    
    /*
     * Get user games history when app starts
     */
    func getInitialGameModel(completion:() -> Void) {
        gameUserRef.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            self.buildGamesDataFrom(snapshot)
            completion()
        })
    }
    
    func getGameIdBetween(fromUUID:String, toUUID:String, completion:(String) -> Void) {
        gameIdBetween(fromUUID, toUUID: toUUID, completion: { (gameId) in
            if let gameId = gameId {
                completion(gameId)
                return
            }
            
            self.createNewGameBetween(fromUUID, toUUID: toUUID, completion: { (gameId) in
                completion(gameId)
            })
        })
    }

    func getActions(completion: (DataSnapshot) -> Void) {
        gameActionRef.queryOrderedByChild(Database.Action.price).observeEventType(.ChildAdded, withBlock: { (snapshot) in
            completion(snapshot)
        })
    }
    
    func getReactions(completion:(() -> Void)? = nil) {
        gameReactionRef.observeSingleEventOfType(.Value, withBlock:  { (snapshot) in
            guard let snapshotDict = snapshot.value as? [String:[String:String]] else {
                return
            }
            
            for auxSnapshot in snapshotDict {
                let reaction = ReactionModel(type: auxSnapshot.0, snapshotDict: auxSnapshot.1)
                if reaction.isValid() {
                    self.reactions[auxSnapshot.0] = reaction
                }
            }
            
            completion?()
        })
    }
    
    func getReactionBy(type:String, completion:(reactions:ReactionModel) -> Void) {
        let reactionTypeRef = FirebaseManager.sharedInstance.getReference(gameReactionRef, childNames: type)
        reactionTypeRef.observeSingleEventOfType(.Value, withBlock:  { (snapshot) in
            
        })
    }
    
    func sendAction(gameModel:GameModel, action:ActionModel) {
        let actionIdRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameModel.gameId)
        let actionRef = actionIdRef.childByAutoId()
        
        let gameValue:[String:AnyObject] = [
            ActionModel.Action.name : action.name,
            ActionModel.Action.icon : action.icon,
            ActionModel.Action.price : action.price,
            ActionModel.Action.reactionType : action.reactionType,
            ActionModel.Action.senderUUID : gameModel.fromUUID,
            ActionModel.Action.date : FIRServerValue.timestamp(),
            
            ActionModel.Action.reaction : [
                ReactionModel.Reaction.Value : "",
                ReactionModel.Reaction.Direction : "",
                ReactionModel.Reaction.Date : ""
            ]
        ]
        
        FirebaseManager.sharedInstance.setValue(actionRef, value: gameValue)
        
        updateGameDate(gameModel)
    }
    
    func sendReaction(gameModel:GameModel, actionId:String, value:String, direction:String) {
        let reactionRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameModel.gameId, actionId, ActionModel.Action.reaction)
        
        let reactionValue = [ReactionModel.Reaction.Value : value]
        let reactionDirection = [ReactionModel.Reaction.Direction : direction]
        let reactionDate = [ReactionModel.Reaction.Date : FIRServerValue.timestamp()]
        
        reactionRef.updateChildValues(reactionValue)
        reactionRef.updateChildValues(reactionDirection)
        reactionRef.updateChildValues(reactionDate)
        
        updateGameDate(gameModel)
    }
    
    private func updateGameDate(gameModel:GameModel) {
        let gameIdRef1 = FirebaseManager.sharedInstance.getReference(gameRef, childNames: gameModel.fromUUID, gameModel.toUUID, Database.Game.date)
        let gameIdRef2 = FirebaseManager.sharedInstance.getReference(gameRef, childNames: gameModel.toUUID, gameModel.fromUUID, Database.Game.date)

        FirebaseManager.sharedInstance.setValue(gameIdRef1, value: FIRServerValue.timestamp())
        FirebaseManager.sharedInstance.setValue(gameIdRef2, value: FIRServerValue.timestamp())
    }
    
    func updateDraggingDirection(gameId:String, actionId:String, direction:String) {
        let draggingDirectionRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId, actionId, ActionModel.Action.draggingIndicator, ActionModel.Action.draggingDirection)
        FirebaseManager.sharedInstance.setValue(draggingDirectionRef, value: direction)
    }
    
    // MARK: - Observers
    
    func observeGameUserRef() {
        gameUserRef.observeEventType(.ChildAdded, withBlock:  { (snapshot) in
            if let gameModel = self.buildGameModelFrom(snapshot) {
                self.appendNewGameModel(gameModel)
            }
        })
        
        gameUserRef.observeEventType(.ChildChanged, withBlock:  { (snapshot) in
            if let gameModel = self.buildGameModelFrom(snapshot) {
                self.mostRecentGameModel = gameModel
                MessageBusManager.sharedInstance.postNotificationName(EventNames.Games.started)
            }
        })
        
        /*
         gameUserRef.observeEventType(.ChildRemoved, withBlock:  { (snapshot) in
         if let gameModel = self.buildGameModelFrom(snapshot) {
         // TODO: REMOVE GAME
         }
         })
         */
    }

    func observeActionsFrom(gameId: String, completion: (DataSnapshot) -> Void) {
        let gameIdRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId)
        actionObserver = gameIdRef.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            completion(snapshot)
        })
    }
    
    func observeReactionsFrom(gameId:String, actionId:String, completion:(direction:String?) -> Void) {
        let reactionRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId, actionId, ActionModel.Action.reaction)
        reactionObserver = reactionRef.observeEventType(.ChildChanged, withBlock:  { (snapshot) in
            if snapshot.key == ReactionModel.Reaction.Direction {
                if let direction = snapshot.value as? String {
                    completion(direction: direction)
                    return
                }
                
            }

            completion(direction: nil)
        })
    }
    
    func observeDraggingDirection(gameId:String, actionId:String, completion:(draggingDirection:String?) -> Void) {
        let draggingDirectionRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId, actionId, ActionModel.Action.draggingIndicator)
        draggingObserver = draggingDirectionRef.observeEventType(.ChildChanged, withBlock:  { (snapshot) in
            if let draggingDirection = snapshot.value as? String {
                completion(draggingDirection: draggingDirection)
                return
            }
            
            completion(draggingDirection: nil)
        })
    }
    
    func stopObserveActionsFrom(gameId:String) {
        if let ao = actionObserver {
            let actionIdRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId)
            actionIdRef.removeObserverWithHandle(ao)
            actionObserver = nil
        }
    }
    
    func stopObserveReactionsFrom(gameId:String, actionId:String) {
        if let ro = reactionObserver {
            let reactionRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId, actionId, ActionModel.Action.reaction)
            reactionRef.removeObserverWithHandle(ro)
            reactionObserver = nil
        }
    }
    
    func stopObserveDraggingDirection(gameId:String, actionId:String) {
        if let dro = draggingObserver {
            let draggingRef = FirebaseManager.sharedInstance.getReference(gameDataRef, childNames: gameId, actionId, ActionModel.Action.draggingIndicator)
            draggingRef.removeObserverWithHandle(dro)
            draggingObserver = nil
        }
        
    }
}
