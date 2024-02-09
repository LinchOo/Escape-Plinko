import SpriteKit
import GameplayKit
import CoreMotion

enum CollisionTypes: UInt32 {
    case Ball = 1
    case Border = 2
    case Border_lose = 3
    case corner = 5
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameViewController: GameViewController?
    init(size: CGSize, gameViewController: GameViewController) {
        self.gameViewController = gameViewController
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var motionManager: CMMotionManager!
    
    var startButton: SKSpriteNode!
    var border: SKSpriteNode!
    var direction: Bool = false
    var isContact: Bool = false
    
    var spawnTimer: Timer?
    var gameTimer: Timer?
    var gameTime = 30
    
    let ball = SKSpriteNode(imageNamed: "ball")
    let loseBorder = SKSpriteNode(imageNamed: "border_1")
    
    var planks = [SKSpriteNode]()
    var plankSpeed: CGFloat = 0.5
    
    var gameOver: Bool = false
    
    func startGeneratingBorders() {
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { Timer in
            self.createPlanks()
        }
    }
    func gameTimerFunc(){
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { Timer in
            self.gameTime -= 1
            if self.gameTime == 0 {
                self.gameViewController?.resultView(result: "Win Win :)")
                self.gameOver = true
                self.stopGeneratingBorders()
                self.planks.removeAll()
            }
        })
    }
    func stopGeneratingBorders() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
    func addBall(){
        
        ball.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "ball"), alphaThreshold: 0.5, size: CGSize(width: 26, height: 26))
        
        ball.size = CGSize(width: 30, height: 30)
        ball.physicsBody?.categoryBitMask = CollisionTypes.Ball.rawValue
        ball.physicsBody?.contactTestBitMask = CollisionTypes.Border.rawValue
        ball.position = CGPoint(x: screen.width / 2, y: screen.height - 51)
        ball.physicsBody?.mass = 1
        ball.physicsBody?.friction = 0.8
        ball.physicsBody?.velocity.dy = -50
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.addChild(self.ball)
        }
        
        loseBorder.size = CGSize(width: screen.width, height: 20)
        loseBorder.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: screen.width, height: 20))
        loseBorder.physicsBody?.affectedByGravity = false
        loseBorder.physicsBody?.isDynamic = false
        loseBorder.physicsBody?.categoryBitMask = CollisionTypes.Border_lose.rawValue
        loseBorder.physicsBody?.contactTestBitMask = CollisionTypes.Ball.rawValue
        loseBorder.position = CGPoint(x: screen.width / 2, y: screen.height - 0)
        loseBorder.alpha = 0
        addChild(loseBorder)
    }
    func createPlanks(){
        if direction {
            let border = SKSpriteNode(imageNamed: "border_1")
            border.size = CGSize(width: screen.width - 80, height: 20)
            border.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "border_1"), alphaThreshold: 0.5, size: CGSize(width: screen.width - 80, height: 20))
            border.physicsBody?.affectedByGravity = false
            border.physicsBody?.isDynamic = false
            border.physicsBody?.categoryBitMask = CollisionTypes.Border.rawValue
            border.physicsBody?.contactTestBitMask = CollisionTypes.Ball.rawValue
            border.position = CGPoint(x: screen.width / 2 - 40, y: -border.size.height)
            addChild(border)
            planks.append(border)
            direction = false
            
        }else{
            let border = SKSpriteNode(imageNamed: "border_1")
            border.size = CGSize(width: screen.width - 80, height: 20)
            border.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "border_1"), alphaThreshold: 0.5, size: CGSize(width: screen.width - 80, height: 20))
            border.physicsBody?.affectedByGravity = false
            border.physicsBody?.isDynamic = false
            border.physicsBody?.categoryBitMask = CollisionTypes.Border.rawValue
            border.physicsBody?.contactTestBitMask = CollisionTypes.Ball.rawValue
            border.position = CGPoint(x: screen.width / 2 + 40, y: -border.size.height)
            addChild(border)
            planks.append(border)
            direction = true
        }
    }
    override func didMove(to view: SKView) {
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0
        physicsBody?.categoryBitMask = CollisionTypes.corner.rawValue
        
        gameTimerFunc()
        startGeneratingBorders()
        addBall()
        
        self.physicsWorld.gravity.dy = -2.5
        
    }
    override func update(_ currentTime: TimeInterval) {
        if !gameOver{
            for plank in planks {
                plank.position.y += plankSpeed
                if plank.position.y > size.height + plank.size.height {
                    plank.removeFromParent()
                }
            }
        }
        if let accelometerData = motionManager.accelerometerData{
            if isContact{
                ball.physicsBody?.velocity.dx = accelometerData.acceleration.x * 300
            }
        }
    }
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 2) ||
            (contact.bodyA.categoryBitMask == 2 && contact.bodyB.categoryBitMask == 1) {
            isContact = true
        }
        if (contact.bodyA.categoryBitMask == 3 && contact.bodyB.categoryBitMask == 1) ||
            (contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 3) {
            self.gameViewController?.resultView(result: "You Lose")
            self.gameOver = true
            self.stopGeneratingBorders()
            self.planks.removeAll()
        }
    }
}
