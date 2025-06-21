import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
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
    }

    // 뒤로가기 버튼 클릭 시
    @IBAction func backButtonTapped(_ sender: UIButton) {
        // 현재 화면을 닫고 메인으로 돌아가기
        dismiss(animated: true, completion: nil)
    }

    // 로그인 버튼 클릭 시
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "입력 오류", message: "이메일과 비밀번호를 모두 입력해주세요.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                let nsError = error as NSError
                self?.showAlert(title: "로그인 실패", message: "오류 코드: \(nsError.code)\n\(nsError.localizedDescription)")
                return
            }
            // 로그인 성공 시, 현재 화면을 닫고 메인으로 돌아갑니다.
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    // 회원가입 버튼 클릭 시
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "입력 오류", message: "이메일과 비밀번호를 모두 입력해주세요.")
            return
        }
        
        // 회원가입 시 닉네임을 추가로 받기 위한 팝업
        let alert = UIAlertController(title: "회원가입", message: "사용할 닉네임을 입력해주세요.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "닉네임"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            guard let nickname = alert.textFields?.first?.text, !nickname.isEmpty else {
                self?.showAlert(title: "입력 오류", message: "닉네임을 입력해주세요.")
                return
            }
            
            // 닉네임 중복 확인 후 계정 생성
            self?.checkNicknameAndCreateUser(email: email, password: password, nickname: nickname)
        }))
        
        present(alert, animated: true)
    }
    
    func checkNicknameAndCreateUser(email: String, password: String, nickname: String) {
        db.collection("users").whereField("nickname", isEqualTo: nickname).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            guard querySnapshot?.isEmpty == true else {
                self.showAlert(title: "오류", message: "이미 사용 중인 닉네임입니다.")
                return
            }
            
            // 닉네임 중복 없을 시, 계정 생성
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    let nsError = error as NSError
                    self.showAlert(title: "회원가입 실패", message: "오류 코드: \(nsError.code)\n\(nsError.localizedDescription)")
                    return
                }
                
                guard let user = authResult?.user else { return }
                
                // Firestore에 닉네임 저장
                self.db.collection("users").document(user.uid).setData(["nickname": nickname]) { error in
                    if let error = error {
                         self.showAlert(title: "오류", message: "닉네임 저장에 실패했습니다: \(error.localizedDescription)")
                    } else {
                        // 회원가입 및 닉네임 저장 성공 시, 화면 닫기
                        self.showAlert(title: "회원가입 성공", message: "\(nickname)님 환영합니다!") {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    // 간단한 알림창 표시 함수
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            completion?()
        }))
        self.present(alert, animated: true, completion: nil)
    }
} 
