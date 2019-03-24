//: A SpriteKit based Playground


import PlaygroundSupport
import UIKit
import SpriteKit
import GameplayKit

struct Levels {
    static var levelsDictionary = [String:Any]()
}

struct ZPosition {
    static let background: CGFloat = 0
    static let obstacles: CGFloat = 1
    static let bird: CGFloat = 2
    static let hudBackground: CGFloat = 10
    static let hudLabel: CGFloat = 11
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let edge: UInt32 = 0x1
    static let bird: UInt32 = 0x1 << 1
    static let block: UInt32 = 0x1 << 2
    static let enemy: UInt32 = 0x1 << 3
}

extension CGPoint {
    
    static public func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static public func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static public func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
    
}



struct LevelData {
    let birds : [String]
    
    
    init?(level: Int) {
        guard let levelDict = Levels.levelsDictionary["Level_\(level)"] as?  [String : Any] else{
            return nil
        }
        guard let birds = levelDict["Birds"] as? [String]else {
            return nil
        }
        
        self.birds = birds
    }
    
}



class AnimationHelper{
    static func loadTexttures(from atlas: SKTextureAtlas, withName name: String) -> [SKTexture]{
        var textures = [SKTexture]()
        
        for index in 0..<atlas.textureNames.count{
            let textureName = name + String(index + 1)
            textures.append(atlas.textureNamed(textureName))
        }
        return textures
    }
}



enum BirdType: String {
    case red, blue, yellow, gray
}

class Bird: SKSpriteNode {
    
    let birdType: BirdType
    
    var grabbed = false
    var flying = false {
        didSet {
            if flying {
                physicsBody?.isDynamic = true
                animateFlight(active: true)
            }else{
                animateFlight(active: false)
            }
        }
    }
    
    let flyingFrames : [ SKTexture ]
    
    init(type: BirdType) {
        birdType = type
        print("BirdType : \(type)")
        flyingFrames = [
            SKTexture(imageNamed: "\(type.rawValue)1"),
            SKTexture(imageNamed: "\(type.rawValue)2"),
            SKTexture(imageNamed: "\(type.rawValue)3"),
            SKTexture(imageNamed: "\(type.rawValue)4")
        
        ]
        print(flyingFrames)
        let texture = SKTexture(imageNamed: type.rawValue + "1")
        
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animateFlight(active:Bool){
        if active{
            run(SKAction.repeatForever(SKAction.animate(with: flyingFrames, timePerFrame: 0.2, resize: true, restore: true)))
        }else{
            removeAllActions()
        }
    }
    
}



// MARK: SpriteKitButton


class SpriteKitButton: SKSpriteNode {
    
    var defaultButton: SKSpriteNode
    var action: (Int) -> ()
    var index: Int
    
    init(defaultButtonImage: String, action: @escaping (Int) -> (), index: Int) {
        defaultButton = SKSpriteNode(imageNamed: defaultButtonImage)
        self.action = action
        self.index = index
        
        super.init(texture: nil, color: UIColor.clear, size: defaultButton.size)
        
        isUserInteractionEnabled = true
        addChild(defaultButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //run(soundPlayer.buttonSound)
        defaultButton.alpha = 0.75
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch: UITouch = touches.first! as UITouch
        let location: CGPoint = touch.location(in: self)
        
        if defaultButton.contains(location) {
            defaultButton.alpha = 0.75
        } else {
            defaultButton.alpha = 1.0
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch: UITouch = touches.first! as UITouch
        let location: CGPoint = touch.location(in: self)
        
        if defaultButton.contains(location) {
            action(index)
        }
        
        defaultButton.alpha = 1.0
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        defaultButton.alpha = 1.0
    }
}





extension SKNode {
    
    func aspectScale(to size: CGSize, width: Bool, multiplier: CGFloat) {
        print("self size: \(self.frame.size) to size \(size)")
        let scale = width ? (size.width * multiplier) / self.frame.size.width : (size.height * multiplier) / self.frame.size.height
        self.setScale(scale)
    }
    
}





enum BlockType: String {
    case wood, stone, glass
}

class Block: SKSpriteNode {
    
    let type: BlockType
    var health: Int
    let damageThreshold: Int
    
    init(type: BlockType) {
        self.type = type
        switch type {
        case .wood:
            health = 200
        case .stone:
            health = 500
        case .glass:
            health = 50
        }
        damageThreshold = health/2
        print(health)
        print(damageThreshold)
        let texture = SKTexture(imageNamed: type.rawValue)
        print(texture)
        super.init(texture: texture, color: UIColor.clear, size: CGSize.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createPhysicsBody() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.block
        physicsBody?.contactTestBitMask = PhysicsCategory.all
        physicsBody?.collisionBitMask = PhysicsCategory.all
        
        physicsBody?.linearDamping = 5
    }
    
    func impact(with force: Int) {
        health -= force
        print("Brick \(type.rawValue) health: \(health)")
        if health < 1 {
            removeFromParent()
        } else if health < damageThreshold {
            let brokenTexture = SKTexture(imageNamed: type.rawValue + "Broken")
            texture = brokenTexture
        }
    }
}






enum EnemyType: String {
    case orange
}

class Enemy: SKSpriteNode {
    
    let type: EnemyType
    var health: Int
    let animationFrames: [SKTexture]
    
    init(type: EnemyType) {
        self.type = type
        animationFrames = [SKTexture(imageNamed: "orange1"), SKTexture(imageNamed: "orange2")]
        switch type {
        case .orange:
            health = 100
        }
        let texture = SKTexture(imageNamed: type.rawValue + "1")
        super.init(texture: texture, color: UIColor.clear, size: CGSize.zero)
        animateEnemy()
    }
    
    func animateEnemy() {
        run(SKAction.repeatForever(SKAction.animate(with: animationFrames, timePerFrame: 0.3, resize: false, restore: true)))
    }
    
    func createPhysicsBody() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.all
        physicsBody?.collisionBitMask = PhysicsCategory.all
    }
    
    func impact(with force: Int) -> Bool {
        health -= force
        if health < 1 {
            removeFromParent()
            return true
        }
        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}




class GameCamera: SKCameraNode {
    
    func setConstraints(with scene: SKScene, and frame: CGRect, to node: SKNode?) {
        let scaledSize = CGSize(width: scene.size.width * xScale, height: scene.size.height * yScale)
        let boardContentRect = frame
        
        let xInset = min(scaledSize.width / 2, boardContentRect.width / 2)
        let yInset = min(scaledSize.height / 2, boardContentRect.height / 2)
        let insetContentRect = boardContentRect.insetBy(dx: xInset, dy: yInset)
        
        let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        let levelEdgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        
        
        if let node = node{
            let zeroRange = SKRange(constantValue: 0)
            let positionConstraint = SKConstraint.distance(zeroRange, to: node)
            constraints = [positionConstraint, levelEdgeConstraint]
        }else{
            constraints = [levelEdgeConstraint]
        }
        
    }
    
}


protocol PopupButtonHandlerDelegate {
    func retryTapped()
}


struct PopupButtons {
    static let retry = 2
}

class Popup: SKSpriteNode {
    
    let type: Int
    var popupButtonHandlerDelegate: PopupButtonHandlerDelegate?
    
    init(type: Int, size: CGSize) {
        self.type = type
        super.init(texture: nil, color: UIColor.clear, size: size)
        setupPopup()
    }
    
    func setupPopup() {
        let background = type == 0 ? SKSpriteNode(imageNamed: "popupcleared") : SKSpriteNode(imageNamed: "popupfailed")
        background.aspectScale(to: size, width: false, multiplier: 0.5)
        
        let retryButton = SpriteKitButton(defaultButtonImage: "popretry", action: popupButtonHandler, index: PopupButtons.retry)
        retryButton.aspectScale(to: background.size, width: true, multiplier: 0.2)
       
        let buttonHeightOffset = retryButton.size.height/2
        let backgroundHeightOffset = background.size.height/2
        
        retryButton.position = CGPoint(x: 0, y: -backgroundHeightOffset - buttonHeightOffset)
        background.position = CGPoint(x: 0, y: buttonHeightOffset)

        addChild(retryButton)
        addChild(background)
    }
    
    func popupButtonHandler(index: Int) {
        switch index {
        case PopupButtons.retry:
            popupButtonHandlerDelegate?.retryTapped()
        default:
            break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



enum RoundState {
    case ready, flying, finished, animating, gameOver
}

class GameScene: SKScene {
    
    var sceneManagerDelegate: SceneManagerDelegate?
    var mapNode = SKTileMapNode()
    
    let gameCamera = GameCamera()
    var panRecognizer = UIPanGestureRecognizer()
    var pinchRecognizer = UIPinchGestureRecognizer()
    var maxScale: CGFloat = 0
    var backgroundSound = SKAudioNode(){
        didSet{
            print("didSet  self.backgroundSound.run(SKAction.stop())")
            self.addChild(backgroundSound)
        }
    }
    
    var bird = Bird(type: .red)
    var birds = [
        Bird(type: .red),
        Bird(type: .blue),
        Bird(type: .yellow),
        Bird(type: .gray),
        Bird(type: .blue),
        ]
    let anchor = SKNode()
    
    var level : Int = 1
    
    var roundState = RoundState.ready
    
    var enemies = 0 {
        didSet {
            if enemies < 1 {
                roundState = .gameOver
                presentPopup(victory: true)
            }
        }
    }
    
    
    override func didMove(to view: SKView) {
        print("didMove called")
        physicsWorld.contactDelegate = self
        setupLevel()
        setupGestureRecognizers()
        backgroundSound = SKAudioNode(fileNamed: "Smile_Quiet_Looking_Up.mp3")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch roundState {
        case .ready:
            if let touch = touches.first {
                let location = touch.location(in: self)
                if bird.contains(location) {
                    panRecognizer.isEnabled = false
                    bird.grabbed = true
                    bird.position = location
                }
            }
        case .flying:
            break
        case .finished:
            guard let view = view else { return }
            roundState = .animating
            let moveCameraBackAction = SKAction.move(to: CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2), duration: 2.0)
            moveCameraBackAction.timingMode = .easeInEaseOut
            gameCamera.run(moveCameraBackAction, completion: {
                self.panRecognizer.isEnabled = true
                self.addBird()
            })
        case .animating:
            break
        case .gameOver:
            break
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if bird.grabbed {
                let location = touch.location(in: self)
                bird.position = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bird.grabbed {
            gameCamera.setConstraints(with: self, and: mapNode.frame, to: bird)
            bird.grabbed = false
            bird.flying = true
            roundState = .flying
            constraintToAnchor(active: false)
            let dx = anchor.position.x - bird.position.x
            let dy = anchor.position.y - bird.position.y
            let impulse = CGVector(dx: dx * 1.5, dy: dy * 1.5)
            bird.physicsBody?.applyImpulse(impulse)
            bird.isUserInteractionEnabled = false
        }
    }
    
    func setupGestureRecognizers() {
        guard let view = view else { return }
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        view.addGestureRecognizer(panRecognizer)
        
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    func setupLevel() {
        
        if let mapNode = childNode(withName: "Tile Map Node") as? SKTileMapNode {
            self.mapNode = mapNode
            maxScale = mapNode.mapSize.width/frame.size.width
        }
        
        for child in mapNode.children {
            if let child = child as? SKSpriteNode {
                guard let name = child.name else { continue }
                switch name {
                case "wood","stone","glass":
                    if let block = createBlock(from: child, name: name) {
                        mapNode.addChild(block)
                        child.removeFromParent()
                    }
                case "orange":
                    if let enemy = createEnemy(from: child, name: name) {
                        mapNode.addChild(enemy)
                        enemies += 1
                        child.removeFromParent()
                    }
                default:
                    break
                }
            }
        }
        
        addCamera()
        
        let physicsRect = CGRect(x: 0, y: mapNode.tileSize.height, width: mapNode.frame.size.width, height: mapNode.frame.size.height-mapNode.tileSize.height)
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsRect)
        physicsBody?.categoryBitMask = PhysicsCategory.edge
        physicsBody?.contactTestBitMask = PhysicsCategory.bird | PhysicsCategory.block
        physicsBody?.collisionBitMask = PhysicsCategory.all
        
        anchor.position = CGPoint(x: mapNode.frame.midX/2, y: mapNode.frame.midY/2)
        addChild(anchor)
        addSlingShot()
        addBird()
        
    }
    
    func addSlingShot(){
        let slingShop = SKSpriteNode(imageNamed: "slingshot.jpg")
        let scaleSize = CGSize(width: 0, height: mapNode.frame.midY/2 - mapNode.tileSize.height/2)
        slingShop.aspectScale(to: scaleSize, width: false, multiplier: 1.0)
        slingShop.position = CGPoint(x: anchor.position.x, y: mapNode.tileSize.height + slingShop.size.height / 2)
        slingShop.zPosition = ZPosition.obstacles
        mapNode.addChild(slingShop)
    }
    
    func addCamera() {
        guard let view = view else { return }
        addChild(gameCamera)
        gameCamera.position = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        camera = gameCamera
        gameCamera.setConstraints(with: self, and: mapNode.frame, to: nil)
    }
    
    func addBird() {
        if birds.isEmpty {
            roundState = .gameOver
            presentPopup(victory: false)
            self.backgroundSound.run(SKAction.stop())
            return
        }
        bird = birds.removeFirst()
        bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.frame.width / 3)
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.all
        bird.physicsBody?.collisionBitMask = PhysicsCategory.block | PhysicsCategory.edge
        bird.physicsBody?.isDynamic = false
        bird.position = anchor.position
        bird.physicsBody?.linearDamping = 0.25
        bird.zPosition = ZPosition.bird
        addChild(bird)
        bird.aspectScale(to: mapNode.tileSize, width: true, multiplier: 1.45)
        constraintToAnchor(active: true)
        roundState = .ready
    }
    
    func createBlock(from placeholder: SKSpriteNode, name: String) -> Block? {
        guard let type = BlockType(rawValue: name) else { return nil }
        print(type)
        let block = Block(type: type)
        block.size = placeholder.size
        block.position = placeholder.position
        block.zRotation = placeholder.zRotation
        block.zPosition = ZPosition.obstacles
        block.createPhysicsBody()
        return block
    }
    
    func createEnemy(from placeholder: SKSpriteNode, name: String) -> Enemy? {
        guard let enemyType = EnemyType(rawValue: name) else { return nil }
        let enemy = Enemy(type: enemyType)
        enemy.size = placeholder.size
        enemy.position = placeholder.position
        enemy.createPhysicsBody()
        return enemy
    }
    
    func constraintToAnchor(active: Bool) {
        if active {
            let slingRange = SKRange(lowerLimit: 0.0, upperLimit: bird.size.width*3)
            let positionConstraint = SKConstraint.distance(slingRange, to: anchor)
            bird.constraints = [positionConstraint]
        } else {
            bird.constraints?.removeAll()
        }
    }
    
    func presentPopup(victory: Bool) {
        self.backgroundSound.run(SKAction.stop())
        print(self.backgroundSound)
        if victory {
            let popup = Popup(type: 0, size: frame.size)
            popup.zPosition = ZPosition.hudBackground
            popup.popupButtonHandlerDelegate = self
            gameCamera.addChild(popup)
        } else {
            let popup = Popup(type: 1, size: frame.size)
            popup.zPosition = ZPosition.hudBackground
            popup.popupButtonHandlerDelegate = self
            gameCamera.addChild(popup)
        }
    }
    
    override func didSimulatePhysics() {
        guard let physicsBody = bird.physicsBody else { return }
        if roundState == .flying && physicsBody.isResting {
            gameCamera.setConstraints(with: self, and: mapNode.frame, to: nil)
            bird.removeFromParent()
            roundState = .finished
        }
    }
    
}

extension GameScene: PopupButtonHandlerDelegate {
    
    func retryTapped() {
        self.backgroundSound.run(SKAction.stop())
        print(self.backgroundSound)
       
        let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
        if let scene = GameScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            sceneView.presentScene(scene)
            sceneView.ignoresSiblingOrder = true
            sceneView.showsNodeCount = true
            sceneView.showsFPS = true
            PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
        }
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch mask {
        case PhysicsCategory.bird | PhysicsCategory.block, PhysicsCategory.block | PhysicsCategory.edge:
            if let block = contact.bodyB.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            } else if let block = contact.bodyA.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            }
            if let bird = contact.bodyA.node as? Bird {
                bird.flying = false
            } else if let bird = contact.bodyB.node as? Bird {
                bird.flying = false
            }
        case PhysicsCategory.block | PhysicsCategory.block:
            if let block = contact.bodyA.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            }
            if let block = contact.bodyB.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            }
        case PhysicsCategory.bird | PhysicsCategory.edge:
            bird.flying = false
        case PhysicsCategory.bird | PhysicsCategory.enemy:
            if let enemy = contact.bodyA.node as? Enemy {
                if enemy.impact(with: Int(contact.collisionImpulse)) {
                    enemies -= 1
                }
            } else if let enemy = contact.bodyB.node as? Enemy {
                if enemy.impact(with: Int(contact.collisionImpulse)) {
                    enemies -= 1
                }
            }
        default:
            break
        }
    }
    
}

extension GameScene {
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let view = view else { return }
        let translation = sender.translation(in: view) * gameCamera.yScale
        gameCamera.position = CGPoint(x: gameCamera.position.x - translation.x, y: gameCamera.position.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: view)
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        guard let view = view else { return }
        if sender.numberOfTouches == 2 {
            let locationInView = sender.location(in: view)
            let location = convertPoint(fromView: locationInView)
            if sender.state == .changed {
                let convertedScale = 1/sender.scale
                let newScale = gameCamera.yScale*convertedScale
                if newScale < maxScale && newScale > 0.5 {
                    gameCamera.setScale(newScale)
                }
                
                let locationAfterScale = convertPoint(fromView: locationInView)
                let locationDelta = location - locationAfterScale
                let newPosition = gameCamera.position + locationDelta
                gameCamera.position = newPosition
                sender.scale = 1.0
                gameCamera.setConstraints(with: self, and: mapNode.frame, to: nil)
            }
        }
    }
    
}

protocol SceneManagerDelegate {
    
    func presentGameSceneFor(level: Int)
}

class GameViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = SKView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 668, height: 375)))
        view = skView
        let scene = GameScene(size: view.bounds.size)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        presentGameSceneFor(level: 1)
    }
}

extension GameViewController: SceneManagerDelegate {
    
    func presentGameSceneFor(level: Int) {
        if let gameScene = SKScene(fileNamed: "GameScene") as? GameScene {
            gameScene.sceneManagerDelegate = self
            gameScene.level = level
            present(scene: gameScene)
        }else{
            print("Scene not found")
        }
    }
    
    func present(scene: SKScene) {
        if let view = self.view as! SKView? {
            if let gestureRecognizers = view.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    view.removeGestureRecognizer(recognizer)
                }
            }
            scene.scaleMode = .resizeFill
            view.presentScene(scene)
            
        }
    }
    
    
}



// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill

    // Present the scene
    sceneView.presentScene(scene)
    sceneView.ignoresSiblingOrder = true
    sceneView.showsNodeCount = true
    sceneView.showsFPS = true
    
}



PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
