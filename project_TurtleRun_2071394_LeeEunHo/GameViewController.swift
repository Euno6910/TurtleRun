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
    var blocks: [UIView] = []
    var coins: [UIView] = []
    var moveTimer: Timer?
    var blockSpawnCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        //땅(Ground)
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

        // 버튼을 맨 위로
        view.bringSubviewToFront(JumpButton)
        view.bringSubviewToFront(SlideButton)

        // 캐릭터 초기 위치(지면 위)
        if let turtle = Turtle {
            var frame = turtle.frame
            frame.origin.y = groundY - frame.height
            turtle.frame = frame
        }

        //이동 타이머 (0.2초 간격)
        moveTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(moveObjects), userInfo: nil, repeats: true) //너무 낮게하면 프라임드랍..

        // 시작하자마자 블록 1개, 코인 1개 생성
        spawnBlockAndMaybeCoin(forceCoin: true)

        // 블록 생성 타이머 (10초 간격)
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.spawnBlockAndMaybeCoin(forceCoin: false)
        }
    }

    @IBAction func JumpButtonTapped(_ sender: UIButton) {
        // 이미 점프 중이라면 무시 (2중 점프 방지)
        if isJumping { return }
        
        // 점프 상태로 설정
        isJumping = true
        
        // 초기 속도를 점프 파워로 설정 (위로 튀어오르게 하기 위함)
        velocity = jumpPower

        // 화면 업데이트를 위해 CADisplayLink 설정 (화면 주사율에 맞춰 반복 호출됨) 타이머보다 시뮬로 보기에 나은듯.
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
        guard let turtle = Turtle else { return }

        if !isSliding {
            // 회전 + 아래로 이동 (y값 증가) 자연스럽게 애니메이션
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

    func spawnBlockAndMaybeCoin(forceCoin: Bool) {
        let coinDiameter: CGFloat = 30
        let minCoinY = CGFloat(100)
        let maxCoinY = groundY - coinDiameter - 20
        var coinY: CGFloat = 0
        var shouldSpawnCoin = false
        blockSpawnCount += 1
        if blockSpawnCount % 2 == 0 || forceCoin {
            shouldSpawnCoin = true
            coinY = CGFloat.random(in: minCoinY...maxCoinY)
        }
        // 블록 높이
        let blockWidth: CGFloat = 40
        let blockHeight: CGFloat = CGFloat.random(in: coinDiameter...(coinDiameter * 2.5))
        // 블록 y 위치: 코인과 겹치지 않게, 코인과 최소 10pt 이상 떨어지게
        var blockY: CGFloat
        repeat {
            blockY = CGFloat.random(in: minCoinY...(groundY - blockHeight))
        } while shouldSpawnCoin && abs((blockY + blockHeight/2) - (coinY + coinDiameter/2)) < (coinDiameter/2 + blockHeight/2 + 10)
        // 블록 생성
        let blockView = UIView(frame: CGRect(
            x: view.frame.width,
            y: blockY,
            width: blockWidth,
            height: blockHeight
        ))
        blockView.backgroundColor = UIColor.blue
        blockView.layer.cornerRadius = 8
        view.addSubview(blockView)
        blocks.append(blockView)
        // 코인 생성
        if shouldSpawnCoin {
            let coinView = UIView(frame: CGRect(
                x: view.frame.width,
                y: coinY,
                width: coinDiameter,
                height: coinDiameter
            ))
            coinView.backgroundColor = UIColor.yellow
            coinView.layer.cornerRadius = coinDiameter / 2
            coinView.layer.borderWidth = 2
            coinView.layer.borderColor = UIColor.orange.cgColor
            view.addSubview(coinView)
            coins.append(coinView)
        }
    }

    @objc func moveObjects() { //우에서 좌로 오브젝트이동
        let moveSpeed: CGFloat = 50 // 이동 속도(조절 가능)
        for block in blocks {
            block.frame.origin.x -= moveSpeed
        }
        for coin in coins {
            coin.frame.origin.x -= moveSpeed
        }
        // 화면 밖으로 나간 오브젝트는 제거(메모리 관리)
        blocks.removeAll { block in
            if block.frame.maxX < 0 {
                block.removeFromSuperview()
                return true
            }
            return false
        }
        coins.removeAll { coin in
            if coin.frame.maxX < 0 {
                coin.removeFromSuperview()
                return true
            }
            return false
        }
    }
}
