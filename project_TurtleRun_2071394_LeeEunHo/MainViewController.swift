import UIKit

class MainViewController: UIViewController {


    @IBOutlet weak var TitleImage: UIImageView!
    @IBOutlet weak var StartButton: UIButton!
    @IBOutlet weak var GuideButton: UIButton!
    @IBOutlet weak var ShopButton: UIButton!
    @IBOutlet weak var LoginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    // "다시하기" 시 ResultViewController의 요청을 받아 게임을 재시작하는 함수
    func restartGame() {
        performSegue(withIdentifier: "StartGame", sender: nil)
    }


}
