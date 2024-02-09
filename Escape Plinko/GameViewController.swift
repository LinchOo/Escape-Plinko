import UIKit
import SpriteKit
import GameplayKit
import WebKit

var screen = UIScreen.main.bounds
var winnerLink = ""
var loserLink = ""

class GameViewController: UIViewController, URLSessionDelegate {
    static let shared = GameViewController()
    let urlReguest = URL(string: "https://2llctw8ia5.execute-api.us-west-1.amazonaws.com/prod")
    
    let webView = WKWebView()
    let toolbar = UIToolbar()
    
    @IBOutlet weak var playBtnOutlet: UIButton!
    @IBOutlet weak var overlayImgOutlet: UIImageView!
    @IBOutlet weak var resultLabelOutlet: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppUtility.lockOrientation(.portrait)
        getUrl()
    }
    
    @IBAction func playBtnAction(_ sender: Any) {
        startGame()
    }
    func test(){
        playBtnOutlet.alpha = 1
    }
    func resultView(result: String){
        webView.alpha = 0
        if let skView = view.subviews.first(where: { $0 is SKView }) as? SKView {
            skView.removeFromSuperview()
        }
        UIView.animate(withDuration: 0.4, animations: {
            self.overlayImgOutlet.alpha = 0.8
            self.resultLabelOutlet.alpha = 1
            self.resultLabelOutlet.text = result
        })
        if result == "Win Win :)"
        {
            self.loadWebView(link: winnerLink)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                UIView.animate(withDuration: 0.4, animations: {
                    self.webView.alpha = 1
                })
            }
            
        } else
        {
            self.loadWebView(link: loserLink)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                UIView.animate(withDuration: 0.4, animations: {
                    self.webView.alpha = 1
                })
            }
        }
    }
    
    func loadWebView(link: String){
        
        let backButtonItem = UIBarButtonItem(systemItem: .rewind)
        let refreshButtonItem = UIBarButtonItem(systemItem: .refresh)
        let forwardButtonItem = UIBarButtonItem(systemItem: .fastForward)
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        let closeButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: nil, action: #selector(closeAction) )

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.items = [backButtonItem, refreshButtonItem, forwardButtonItem, spacer, closeButtonItem]
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        backButtonItem.action = #selector(backAction)
        refreshButtonItem.action = #selector(refreshAction)
        forwardButtonItem.action = #selector(forwardAction)
        
        guard let urlOpen = URL(string: link) else { return }
        let urlOpenRequest = URLRequest(url: urlOpen)
        webView.load(urlOpenRequest)
    }
    @objc func backAction(){
        guard webView.canGoBack else { return }
        webView.goBack()
    }
    @objc func refreshAction(){
        webView.reload()
    }
    @objc func forwardAction() {
        guard webView.canGoForward else { return }
        webView.goForward()
    }
    @objc func closeAction() {
        overlayImgOutlet.alpha = 0
        resultLabelOutlet.alpha = 0
        UIView.animate(withDuration: 0.4, animations: {
            self.webView.alpha = 0
            self.playBtnOutlet.alpha = 1
        })
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.removeFromSuperview()
        toolbar.removeFromSuperview()
        webView.loadHTMLString("", baseURL: nil)
        
    }
    func startGame(){
        UIView.animate(withDuration: 0.4, animations: {
            self.playBtnOutlet.alpha = 0 // Изменение прозрачности кнопки на 0
            self.overlayImgOutlet.alpha = 0
            self.resultLabelOutlet.alpha = 0
        })
            let skView = SKView(frame: view.frame)
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.ignoresSiblingOrder = true
            skView.allowsTransparency = true
            skView.backgroundColor = .clear
        
            let scene = GameScene(size: view.bounds.size, gameViewController: self)
            scene.scaleMode = .aspectFill
            scene.backgroundColor = .clear
            scene.gameOver = false
        
            skView.presentScene(scene)
            view.addSubview(skView)
        
    }
    func getUrl(){
        let request = URLRequest(url: urlReguest!)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForResource = 60
        configuration.timeoutIntervalForRequest = 60
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    print("Error")
                }
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                guard let winLink = responseJSON["winner"] as? String else { return }
                winnerLink = winLink
                guard let loseLink = responseJSON["loser"] as? String else { return }
                loserLink = loseLink
            }
            return
        }
        task.resume()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

struct AppUtility {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        self.lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
}
