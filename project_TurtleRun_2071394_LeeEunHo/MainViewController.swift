import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class MainViewController: UIViewController {


    @IBOutlet weak var TitleImage: UIImageView!
    @IBOutlet weak var StartButton: UIButton!
    @IBOutlet weak var ShopButton: UIButton!
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var rankButton: UIButton!
    let db = Firestore.firestore()
    
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
        
        // 뷰가 로드될 때 로그인 상태를 확인하고 버튼 업데이트
        updateLoginButtonUI()
        
        // 로그인 상태 변경을 감지하여 UI를 업데이트하는 리스너 추가
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateLoginButtonUI()
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // 이미 로그인된 사용자인지 확인
        if Auth.auth().currentUser != nil {
            // 로그인 상태 -> 로그아웃 처리
            do {
                try Auth.auth().signOut()
                self.showAlert(title: "로그아웃", message: "성공적으로 로그아웃 되었습니다.")
            } catch let signOutError as NSError {
                self.showAlert(title: "오류", message: "로그아웃에 실패했습니다: \(signOutError.localizedDescription)")
            }
        } else {
            // 로그아웃 상태 -> 로그인 화면으로 이동
            performSegue(withIdentifier: "goToLogin", sender: nil)
        }
    }
    
    @IBAction func rankButtonTapped(_ sender: UIButton) {
        showRankingPopup()
    }

    func showRankingPopup() {
        // 1. 사용자가 로그인했는지 확인
        guard let currentUser = Auth.auth().currentUser else {
            showAlert(title: "랭킹", message: "랭킹을 보려면 먼저 로그인이 필요합니다.")
            return
        }

        let group = DispatchGroup()
        var topPlayersInfo: String?
        var myInfo: String?

        // 2. 상위 3명 정보 가져오기
        group.enter()
        db.collection("users")
          .order(by: "highScore", descending: true)
          .limit(to: 3) // 3명까지 가져오기
          .getDocuments { (querySnapshot, error) in
            defer { group.leave() }
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                var rankingText = ""
                let medals = ["🥇", "🥈", "🥉"]
                for (index, document) in documents.enumerated() {
                    let data = document.data()
                    let nickname = data["nickname"] as? String ?? "이름없음"
                    let score = data["highScore"] as? Int ?? 0
                    let medal = index < medals.count ? medals[index] : " \(index + 1)위."
                    rankingText += "\(medal) \(nickname) (\(score)점)\n"
                }
                topPlayersInfo = rankingText.trimmingCharacters(in: .newlines)
            } else {
                topPlayersInfo = "아직 랭킹 기록이 없습니다."
            }
        }

        // 3. 내 정보 가져오기
        group.enter()
        db.collection("users").document(currentUser.uid).getDocument { (document, error) in
            defer { group.leave() }
            if let document = document, document.exists, let data = document.data() {
                let nickname = data["nickname"] as? String ?? "내 닉네임"
                let score = data["highScore"] as? Int ?? 0
                myInfo = "👤 내 점수: \(nickname) (\(score)점)"
            } else {
                myInfo = "아직 등록된 점수가 없습니다."
            }
        }

        // 4. 모든 정보가 준비되면 팝업 표시
        group.notify(queue: .main) {
            let message = "\(topPlayersInfo ?? "랭킹 정보 없음")\n\n\(myInfo ?? "내 점수: 정보 없음")"
            self.showAlert(title: "🏆 실시간 랭킹", message: message)
        }
    }
    
    // 로그인 상태에 따라 버튼 UI 업데이트
    func updateLoginButtonUI() {
        if let user = Auth.auth().currentUser {
            // 로그인 상태 -> Firestore에서 닉네임 가져오기
            db.collection("users").document(user.uid).getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data(), let nickname = data["nickname"] as? String {
                    self.LoginButton.setTitle("\(nickname)님 / 로그아웃", for: .normal)
                } 
            }
        } else {
            // 로그아웃 상태
            LoginButton.setTitle("로그인 / 회원가입", for: .normal)
        }
    }
    
    // 알림창 표시를 위한 함수
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // "다시하기" 시 ResultViewController의 요청을 받아 게임을 재시작하는 함수
    func restartGame() {
        performSegue(withIdentifier: "StartGame", sender: nil)
    }


}
