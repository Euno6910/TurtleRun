import UIKit

class ResultViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var finalScore: Int = 0 // GameViewController로부터 점수를 전달받을 변수
    var isNewHighScore: Bool = false // 최고기록 갱신 여부를 전달받을 변수
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scoreLabel.text = "\(finalScore)" //최종점수
        
        // 연한 하늘색 그라데이션 배경
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0).cgColor, // 연한 하늘색
            UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0).cgColor  // 더 연한 하늘색
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 최고 기록을 갱신했다면 "NEW!" 라벨을 점수 왼쪽에 표시
        if isNewHighScore {
            let newRecordLabel = UILabel()
            newRecordLabel.text = "NEW!"
            newRecordLabel.font = UIFont.boldSystemFont(ofSize: 20)
            newRecordLabel.textColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0) // 밝은 빨간색
            newRecordLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newRecordLabel)

            // 제약조건을 이용해 점수 라벨 왼쪽에 배치
            NSLayoutConstraint.activate([
                newRecordLabel.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
                newRecordLabel.trailingAnchor.constraint(equalTo: scoreLabel.leadingAnchor, constant: -8)
            ])
        }
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        // "다시하기" 버튼: 게임을 재시작합니다.
        
        // 1. 현재 화면을 띄운 GameViewController를 찾습니다.
        guard let gameViewController = self.presentingViewController else { return }
        
        // 2. GameViewController를 띄운 MainViewController를 찾습니다.
        guard let mainViewController = gameViewController.presentingViewController as? MainViewController else {
            // MainViewController를 찾지 못하면, 기존 방식대로 닫기만 합니다.
            gameViewController.dismiss(animated: true, completion: nil)
            return
        }
        
        // 3. MainViewController에서 모든 모달(Game, Result)을 닫습니다.
        mainViewController.dismiss(animated: true) {
            // 4. 닫기 애니메이션이 끝난 후, MainViewController의 restartGame 함수를 호출해 새 게임을 시작합니다.
            mainViewController.restartGame()
        }
    }
    
    @IBAction func mainButtonTapped(_ sender: UIButton) {
        // "메인으로" 버튼: 게임 화면과 결과 화면을 모두 닫고 메인 화면으로 돌아갑니다.

        // 1. 현재 화면을 띄운 GameViewController를 찾습니다.
        guard let gameViewController = self.presentingViewController else { return }
        
        // 2. GameViewController를 띄운 MainViewController를 찾습니다.
        guard let mainViewController = gameViewController.presentingViewController else {
            // MainViewController를 찾지 못하면, 현재 화면만 닫습니다.
            dismiss(animated: true, completion: nil)
            return
        }
        
        // 3. MainViewController에서 자신(Main)이 띄운 모든 화면을 닫습니다.
        mainViewController.dismiss(animated: true, completion: nil)
    }
}
