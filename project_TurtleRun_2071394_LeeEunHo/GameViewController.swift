import UIKit

class GameViewController: UIViewController {

    @IBOutlet weak var JumpButton: UIButton!
    @IBOutlet weak var SlideButton: UIButton!
    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var CoinLabel: UILabel!
    @IBOutlet weak var Turtle: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. 땅(Ground)
        let groundHeight: CGFloat = 100 // 원하는 높이로 조정
        let groundY = view.frame.height - groundHeight - view.safeAreaInsets.bottom
        let groundView = UIView(frame: CGRect(
            x: 0,
            y: groundY,
            width: view.frame.width,
            height: groundHeight
        ))
        groundView.backgroundColor = UIColor.black
        view.addSubview(groundView)

        // 2. 블록(Block)
        let blockWidth: CGFloat = 40
        let blockHeight: CGFloat = 150
        let blockX: CGFloat = 300
        let blockY: CGFloat = groundY - blockHeight
        let blockView = UIView(frame: CGRect(
            x: blockX,
            y: blockY,
            width: blockWidth,
            height: blockHeight
        ))
        blockView.backgroundColor = UIColor.blue
        blockView.layer.cornerRadius = 8
        view.addSubview(blockView)

        // 3. 버튼을 맨 위로!
        view.bringSubviewToFront(JumpButton)
        view.bringSubviewToFront(SlideButton)
    }
}
