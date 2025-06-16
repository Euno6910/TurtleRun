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
    var blockSpawnTimer: Timer?
    var coinSpawnTimer: Timer?
    var blockSpawnCount = 0
    var coinSpawnCount = 0
    let blockSpawnInterval: TimeInterval = 11.0
    let coinSpawnInterval: TimeInterval = 17.0

    override func viewDidLoad() {
        super.viewDidLoad()
        //배경 설정
        //땅(Ground) 생성
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

        // 캐릭터 초기 위치(지면 위)생성
        if let turtle = Turtle {
            var frame = turtle.frame
            frame.origin.y = groundY - frame.height
            turtle.frame = frame
        }
        
        //오브젝트 생성
        //이동 타이머 (0.2초 간격)
        moveTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(moveObjects), userInfo: nil, repeats: true)

        // 시작하자마자 블록 1개 생성
        //spawnBlock()

        // 블록 생성 타이머 (11초 간격)
        blockSpawnTimer = Timer.scheduledTimer(withTimeInterval: blockSpawnInterval, repeats: true) { [weak self] _ in
            self?.blockSpawnCount += 1
            self?.spawnBlock()
        }

        // 코인 생성 타이머 (17초 간격)
        coinSpawnTimer = Timer.scheduledTimer(withTimeInterval: coinSpawnInterval, repeats: true) { [weak self] _ in
            self?.coinSpawnCount += 1
            // 공배수(187초)에서는 코인 생성하지 않음(충돌처리보다 이게 렉 안걸림)
            if (self?.blockSpawnCount ?? 0) * 11 != (self?.coinSpawnCount ?? 0) * 17 {
                self?.spawnCoin()
            }
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

    func spawnBlock() { //블럭 생성
        let blockWidth: CGFloat = 40
        let blockHeight: CGFloat = CGFloat.random(in: 30...60)
        let blockY = CGFloat.random(in: 100...(groundY - blockHeight))
        
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
    }

    func spawnCoin() { //코인 생성
        let coinDiameter: CGFloat = 30
        let minCoinY = CGFloat(100)
        let maxCoinY = groundY - coinDiameter - 20
        let coinY = CGFloat.random(in: minCoinY...maxCoinY)
        
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

    @objc func moveObjects() { //우에서 좌로 오브젝트이동
        let moveSpeed: CGFloat = 80 // 이동 속도(이동 속도를 늘리고 빈도를 줄임으로써 렉 최적화)
        for block in blocks {
            block.frame.origin.x -= moveSpeed
        }
        for coin in coins {
            coin.frame.origin.x -= moveSpeed
        }
        
        // 충돌 체크
        checkCollisions()
        
        // 화면 밖으로 나간 오브젝트 제거
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
    
    func checkCollisions() {
        guard let turtle = Turtle else { return }
        
        // 거북이의 현재 프레임
        let turtleFrame = turtle.frame
        
        // 블록과의 충돌 체크
        for block in blocks {
            if turtleFrame.intersects(block.frame) {
                print("충돌!")
                return
            }
        }
        
        // 코인과의 충돌 체크
        for (index, coin) in coins.enumerated() {
            if turtleFrame.intersects(coin.frame) {
                print("코인!")
                coins.remove(at: index)
                coin.removeFromSuperview()
                return
            }
        }
    }
}
