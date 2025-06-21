import UIKit
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

class GameViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var JumpButton: UIButton!
    @IBOutlet weak var SlideButton: UIButton!
    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var CoinLabel: UILabel!
    @IBOutlet weak var Turtle: UIImageView!

    let db = Firestore.firestore()
    var audioPlayer: AVAudioPlayer?
    var soundEffectPlayers: [AVAudioPlayer] = [] // 효과음 플레이어 배열
    var isJumping = false
    var canDoubleJump = false  // 더블 점프 가능 여부
    var velocity: CGFloat = 0
    var gravity: CGFloat = 0.8 // 중력 가속도. 낮을수록 천천히 떨어짐 (기존 1.1)
    var jumpPower: CGFloat = -20 // 점프 힘 (낮은 음수일수록 강함)
    var groundY: CGFloat = 0
    var displayLink: CADisplayLink?
    var isSliding = false
    var blocks: [UIView] = []
    var coins: [UIView] = []      // 코인 뷰 배열
    var coinCount: Int = 0        // 코인 개수(정수)
    var cloud: UIView?  // 단일 구름
    var moveTimer: Timer?
    var blockSpawnTimer: Timer?
    var coinSpawnTimer: Timer?
    var blockSpawnCount = 0
    var coinSpawnCount = 0
    let blockSpawnInterval: TimeInterval = 11.0
    let coinSpawnInterval: TimeInterval = 17.0
    var score: Int = 0            // 점수
    
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

        // 캐릭터 초기 위치 및 크기 설정
        if let turtle = Turtle {
            let turtleSize = CGSize(width: 80, height: 80) // 달리는 거북이 크기를 키움
            turtle.frame = CGRect(
                x: turtle.frame.origin.x, // 스토리보드의 X위치는 유지
                y: groundY - turtleSize.height, // 캐릭터를 땅 위에 정확히 위치시킴
                width: turtleSize.width,
                height: turtleSize.height
            )
        }
        
        // 로그인된 사용자의 스킨 정보 적용
        applyEquippedSkin()
        
        // CoinLabel 초기값 설정
        CoinLabel.text = "0"
        
        // 시작하자마자 구름 1개 생성
        spawnCloud()
        
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
        
        // 배경음악 재생 시작
        playBackgroundMusic()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 화면이 사라질 때 배경음악 정지
        stopBackgroundMusic()
    }

    @IBAction func JumpButtonTapped(_ sender: UIButton) {
        if !isJumping {
            // 첫 점프
            playSoundEffect(named: "JumpBgm", volume: 0.4)
            isJumping = true
            canDoubleJump = true
            velocity = jumpPower
            displayLink = CADisplayLink(target: self, selector: #selector(updateJump))
            displayLink?.add(to: .main, forMode: .default)
            
            // 점프 시 슬라이드 해제
            if isSliding, let turtle = Turtle {
                applyRunningImage()
                
                let originalFrame = turtle.frame
                let standingHeight = originalFrame.height * 2 // 원래 높이로 복원
                let standingY = originalFrame.origin.y - (standingHeight - originalFrame.height) // 위쪽으로 위치 조정
                
                UIView.animate(withDuration: 0.2) {
                    turtle.frame = CGRect(
                        x: originalFrame.origin.x,
                        y: standingY,
                        width: originalFrame.width,
                        height: standingHeight
                    )
                }
                isSliding = false
            }
        } else if canDoubleJump {
            // 더블 점프
            playSoundEffect(named: "JumpBgm", volume: 0.4)
            canDoubleJump = false
            velocity = jumpPower * 0.8  // 더블 점프는 약간 약하게
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
            self.canDoubleJump = false
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
            playSoundEffect(named: "SlideBgm", volume: 0.4)
            
            // 슬라이드 이미지로 변경
            applySlideImage()
            
            // 높이를 반으로 줄이고 위치 조정
            let originalFrame = turtle.frame
            let slideHeight = originalFrame.height * 0.5 // 높이를 반으로
            let slideY = originalFrame.origin.y + (originalFrame.height - slideHeight) // 아래쪽 기준으로 위치 조정
            
            UIView.animate(withDuration: 0.2) {
                turtle.frame = CGRect(
                    x: originalFrame.origin.x,
                    y: slideY,
                    width: originalFrame.width,
                    height: slideHeight
                )
            }
            isSliding = true
        } else {
            // 원래 상태로 복귀
            applyRunningImage()
            
            let originalFrame = turtle.frame
            let standingHeight = originalFrame.height * 2 // 원래 높이로 복원
            let standingY = originalFrame.origin.y - (standingHeight - originalFrame.height) // 위쪽으로 위치 조정
            
            UIView.animate(withDuration: 0.2) {
                turtle.frame = CGRect(
                    x: originalFrame.origin.x,
                    y: standingY,
                    width: originalFrame.width,
                    height: standingHeight
                )
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

    func spawnCloud() {
        // 구름 크기 고정
        let cloudWidth: CGFloat = 100
        let cloudHeight: CGFloat = 60
        
        // 구름 이미지뷰 생성
        let cloudView = UIImageView(image: UIImage(named: "Cloud"))
        cloudView.frame = CGRect(
            x: view.frame.width,
            y: 100,
            width: cloudWidth,
            height: cloudHeight
        )
        
        // 구름을 모든 뷰 뒤로 보내기
        view.addSubview(cloudView)
        view.sendSubviewToBack(cloudView)
        cloud = cloudView
    }

    @objc func moveObjects() { //우에서 좌로 오브젝트이동
        let moveSpeed: CGFloat = 40 // 블록 이동 속도 적당하게
        let cloudSpeed: CGFloat = 20 // 구름 이동 속도 빠르게
        
        // 구름 이동
        if let cloud = cloud {
            cloud.frame.origin.x -= cloudSpeed
            // 구름이 화면 밖으로 나가면 점수 증가 후 제거 및 새로 생성
            if cloud.frame.maxX < 0 {
                score += 777 * (coinCount + 1)
                updateScoreLabel()
                cloud.removeFromSuperview()
                spawnCloud()
            }
        }
        
        // 기존 오브젝트 이동
        for block in blocks {
            block.frame.origin.x -= moveSpeed
        }
        for coin in coins {
            coin.frame.origin.x -= moveSpeed
        }
        
        // 충돌 체크
        checkCollision()
        
        // 화면 밖으로 나간 오브젝트 제거
        removeOffscreenObjects()
    }
    
    func removeOffscreenObjects() {
        // 화면 밖으로 나간 블록, 코인 삭제 및 블록 점수 증가 처리
        for (index, block) in blocks.enumerated().reversed() {
            if block.frame.maxX < 0 {
                block.removeFromSuperview()
                blocks.remove(at: index)
                // 블록 삭제 시 점수 증가
                score += 111 * (coinCount + 1)
                updateScoreLabel()
            }
        }
        for (index, coin) in coins.enumerated().reversed() {
            if coin.frame.maxX < 0 {
                coin.removeFromSuperview()
                coins.remove(at: index)
            }
        }
    }

    func checkCollision() {
        guard let turtle = Turtle else { return }

        // 코인과의 충돌을 먼저 체크합니다.
        for (index, coin) in coins.enumerated().reversed() { // 안전한 삭제를 위해 역순으로 순회
            if turtle.frame.intersects(coin.frame) {
                playSoundEffect(named: "CoinBgm")
                coins.remove(at: index)
                coin.removeFromSuperview()
                coinCount += 1
                updateCoinLabel()
                // 코인 획득 시 점수 증가
                score += 77 * coinCount
                updateScoreLabel()
                // 코인을 먹었다고 함수를 종료하지 않고, 다른 코인이나 블록과도 충돌했는지 계속 확인합니다.
            }
        }
        
        // 그 다음 블록과의 충돌을 체크합니다.
        for block in blocks {
            if turtle.frame.intersects(block.frame) {
                endGame()
                return // 블록과 충돌하면 게임을 즉시 종료합니다.
            }
        }
    }

    func endGame() {
        // 모든 타이머 중지
        stopAllTimers()
        stopBackgroundMusic()
        
        saveGameResult()
    }
    
    func stopAllTimers() {
        moveTimer?.invalidate()
        blockSpawnTimer?.invalidate()
        coinSpawnTimer?.invalidate()
        displayLink?.invalidate()
    }
    
    func saveGameResult() {
        // 1. 로그인된 사용자가 있는지 확인
        guard let user = Auth.auth().currentUser else {
            // 로그인 상태가 아니면, 저장하지 않고 결과 화면만 표시
            self.showResultScreen(isNewHighScore: false)
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        
        // 2. Transaction을 사용하여 데이터의 동시성 문제를 방지하고 안전하게 읽기-수정-쓰기 작업을 수행
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                // 먼저 현재 사용자 문서 정보를 가져옵니다.
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // 기존 데이터 가져오기 (없으면 0으로 초기화)
            let oldHighScore = userDocument.data()?["highScore"] as? Int ?? 0
            let oldTotalCoins = userDocument.data()?["coins"] as? Int ?? 0
            
            // 새 데이터 계산하기
            let newTotalCoins = oldTotalCoins + self.coinCount
            
            var isNewHighScore = false
            let newHighScore = max(oldHighScore, self.score)
            if newHighScore > oldHighScore {
                isNewHighScore = true
            }
            
            // 데이터 업데이트 준비. merge: true는 다른 필드(예: nickname)를 덮어쓰지 않도록 보장합니다.
            transaction.setData([
                "highScore": newHighScore,
                "coins": newTotalCoins
            ], forDocument: userRef, merge: true)
            
            return isNewHighScore // 이 값을 트랜잭션 성공 시 결과로 전달합니다.

        }) { (object, error) in
            // 3. 트랜잭션 완료 후 결과 처리
            if let error = error {
                print("Transaction failed: \(error)")
                // 저장에 실패하더라도 점수 화면은 보여줍니다.
                self.showResultScreen(isNewHighScore: false)
                return
            }
            
            // 트랜잭션 성공!
            let isNewHighScore = object as? Bool ?? false
            self.showResultScreen(isNewHighScore: isNewHighScore)
        }
    }
    
    func showResultScreen(isNewHighScore: Bool) {
        guard let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        // 최종 점수와 최고기록 갱신 여부를 결과 화면에 전달
        resultVC.finalScore = self.score
        resultVC.isNewHighScore = isNewHighScore
        resultVC.modalPresentationStyle = .overCurrentContext
        resultVC.modalTransitionStyle = .crossDissolve
        self.present(resultVC, animated: true, completion: nil)
    }

    func updateScoreLabel() {
        ScoreLabel.text = "\(score)"
    }

    func updateCoinLabel() { 
        CoinLabel.text = "\(coinCount)"
    }

    func playBackgroundMusic() {
        guard let dataAsset = NSDataAsset(name: "Bgm") else {
            print("Bgm 에셋을 찾을 수 없습니다.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: dataAsset.data)
            audioPlayer?.numberOfLoops = -1 // -1은 무한 반복을 의미합니다.
            audioPlayer?.volume = 0.1 // 배경음악 볼륨을 30%로 설정합니다.
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("배경음악 재생 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundMusic() {
        audioPlayer?.stop()
    }
    
    func playSoundEffect(named soundName: String, volume: Float = 1.0) {
        guard let dataAsset = NSDataAsset(name: soundName) else {
            print("\(soundName) 에셋을 찾을 수 없습니다.")
            return
        }

        do {
            let soundPlayer = try AVAudioPlayer(data: dataAsset.data)
            soundPlayer.delegate = self
            soundPlayer.volume = volume // 전달받은 볼륨으로 설정
            soundEffectPlayers.append(soundPlayer) // 배열에 추가하여 참조 유지
            soundPlayer.play()
        } catch {
            print("\(soundName) 효과음 재생 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 재생이 끝난 플레이어를 배열에서 제거하여 메모리 누수 방지
        soundEffectPlayers.removeAll { $0 === player }
    }

    func applyEquippedSkin() {
        guard let user = Auth.auth().currentUser else {
            // 비로그인 상태면 기본 달리기 스킨으로
            self.Turtle.image = UIImage(named: "TurtleRun")
            self.Turtle.contentMode = .scaleAspectFit
            return
        }
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                // 사용자 정보가 없으면 기본 달리기 스킨으로
                self.Turtle.image = UIImage(named: "TurtleRun")
                self.Turtle.contentMode = .scaleAspectFit
                return
            }
            
            let equippedSkin = data["equippedSkin"] as? String ?? "basic_turtle"
            
            switch equippedSkin {
            case "tanned_turtle":
                self.Turtle.image = UIImage(named: "BlackTurtleRun") // 태닝 거북이 달리기
            default:
                self.Turtle.image = UIImage(named: "TurtleRun") // 기본 거북이 달리기
            }
            
            self.Turtle.contentMode = .scaleAspectFit
        }
    }
    
    func applyRunningImage() {
        guard let user = Auth.auth().currentUser else {
            Turtle.image = UIImage(named: "TurtleRun")
            return
        }
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                self.Turtle.image = UIImage(named: "TurtleRun")
                return
            }
            
            let equippedSkin = data["equippedSkin"] as? String ?? "basic_turtle"
            
            switch equippedSkin {
            case "tanned_turtle":
                self.Turtle.image = UIImage(named: "BlackTurtleRun")
            default:
                self.Turtle.image = UIImage(named: "TurtleRun")
            }
        }
    }
    
    func applySlideImage() {
        guard let user = Auth.auth().currentUser else {
            // 비로그인 상태면 기본 슬라이드 이미지
            Turtle.image = UIImage(named: "TurtleSlide")
            return
        }
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                // 사용자 정보가 없으면 기본 슬라이드 이미지
                self.Turtle.image = UIImage(named: "TurtleSlide")
                return
            }
            
            let equippedSkin = data["equippedSkin"] as? String ?? "basic_turtle"
            
            switch equippedSkin {
            case "tanned_turtle":
                self.Turtle.image = UIImage(named: "BlackTurtleSlide")
            default:
                self.Turtle.image = UIImage(named: "TurtleSlide")
            }
        }
    }
}
