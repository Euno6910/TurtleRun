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
    var displayLink: CADisplayLink?
    var isSliding = false

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
        // 이미 점프 중이라면 무시 (2중 점프 방지)
        if isJumping { return }
        
        // 점프 상태로 설정
        isJumping = true
        
        // 초기 속도를 점프 파워로 설정 (위로 튀어오르게 하기 위함)
        velocity = jumpPower

        // 화면 업데이트를 위해 CADisplayLink 설정 (화면 주사율에 맞춰 반복 호출됨)
        displayLink = CADisplayLink(target: self, selector: #selector(updateJump))
        displayLink?.add(to: .main, forMode: .default)

        // 점프 시 슬라이드 해제
        if isSliding, let turtle = Turtle {
            UIView.animate(withDuration: 0.2) {
                turtle.transform = .identity
            }
            isSliding = false
        }
    }

    @objc func updateJump() {
        guard let turtle = self.Turtle else { return }

        // 현재 거북이의 프레임을 복사
        var frame = turtle.frame

        // 수직 위치에 속도만큼 더해 위치 갱신 (위로 이동 시 velocity는 음수)
        frame.origin.y += self.velocity
        
        // 중력 적용 (속도에 가속도 개념처럼 계속 더해짐)
        self.velocity += self.gravity

        // 바닥에 도착한 경우
        if frame.origin.y >= self.groundY - frame.height {
            // 위치를 정확히 바닥에 맞춤
            frame.origin.y = self.groundY - frame.height

            // 점프 상태 해제 및 속도 초기화
            self.isJumping = false
            self.velocity = 0

            // displayLink 종료 (애니메이션 루프 정지)
            displayLink?.invalidate()
            displayLink = nil
        }

        // 실제 거북이 위치 업데이트
        turtle.frame = frame
    }

    @IBAction func SlideButtonTapped(_ sender: UIButton) {
        print("슬라이드 버튼 눌림")  // 작동 확인용
        guard let turtle = Turtle else { return }

        if !isSliding {
            // 💡 회전 + 아래로 이동 (y값 증가)
            UIView.animate(withDuration: 0.2) {
                let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
                let translation = CGAffineTransform(translationX: 0, y: 20) // 아래로 20pt
                turtle.transform = rotation.concatenating(translation)
            }
            isSliding = true
        } else {
            // 원래 상태로 복귀
            UIView.animate(withDuration: 0.2) {
                turtle.transform = .identity
            }
            isSliding = false
        }
    }
}
