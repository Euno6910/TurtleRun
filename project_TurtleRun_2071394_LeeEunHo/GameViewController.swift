import UIKit

class GameViewController: UIViewController {

    @IBOutlet weak var JumpButton: UIButton!
    @IBOutlet weak var SlideButton: UIButton!
    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var CoinLabel: UILabel!
    @IBOutlet weak var Turtle: UIImageView!

    var isJumping = false
    var velocity: CGFloat = 0
    var gravity: CGFloat = 1.1 // 중력 가속도
    var jumpPower: CGFloat = -20 // 점프 힘 (낮은 음수일수록 강함)
    var groundY: CGFloat = 0
    var jumpTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. 땅(Ground)
        let groundHeight: CGFloat = 100 // 땅 높이
        groundY = view.frame.height - groundHeight - view.safeAreaInsets.bottom
        let groundView = UIView(frame: CGRect(
            x: 0,
            y: groundY,
            width: view.frame.width,
            height: groundHeight
        ))
        groundView.backgroundColor = UIColor.black
        view.addSubview(groundView)

        // 2. 장애물(Block)
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

        // 캐릭터 초기 위치(지면 위)
        if let turtle = Turtle {
            var frame = turtle.frame
            frame.origin.y = groundY - frame.height
            turtle.frame = frame
        }
    }

    @IBAction func JumpButtonTapped(_ sender: UIButton) {
        if isJumping { return } // 이미 점프 중이면 무시
        isJumping = true
        velocity = jumpPower

        jumpTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self = self, let turtle = self.Turtle else { return }
            // 속도에 따라 y값 변경
            var frame = turtle.frame
            frame.origin.y += self.velocity
            self.velocity += self.gravity // 중력 적용

            // 지면에 닿으면 멈춤
            if frame.origin.y >= self.groundY - frame.height {
                frame.origin.y = self.groundY - frame.height
                self.isJumping = false
                self.velocity = 0
                timer.invalidate()
            }
            turtle.frame = frame
        }
    }
}
