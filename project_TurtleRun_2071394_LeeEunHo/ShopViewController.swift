import UIKit
import FirebaseAuth
import FirebaseFirestore

class ShopViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var coinBalanceLabel: UILabel!
    @IBOutlet weak var basicTurtleEquipButton: UIButton!
    @IBOutlet weak var tannedTurtlePurchaseButton: UIButton!
    
    // MARK: - Properties
    let db = Firestore.firestore()
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    // 스킨 정보
    let tannedTurtlePrice = 2
    let basicSkinID = "basic_turtle"
    let tannedSkinID = "tanned_turtle"
    
    // MARK: - Lifecycle
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    // MARK: - UI Update
    func updateUI() {
        guard let user = currentUser else {
            // 비로그인 상태에서는 UI를 비활성화
            coinBalanceLabel.text = "코인: -"
            basicTurtleEquipButton.isEnabled = false
            tannedTurtlePurchaseButton.isEnabled = false
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                print("사용자 문서를 찾을 수 없습니다.")
                return
            }
            
            // 코인 표시
            let coins = data["coins"] as? Int ?? 0
            self.coinBalanceLabel.text = "보유 코인: \(coins)개"
            
            // 스킨 상태 업데이트
            let ownedSkins = data["ownedSkins"] as? [String] ?? [self.basicSkinID]
            let equippedSkin = data["equippedSkin"] as? String ?? self.basicSkinID
            
            self.updateSkinButton(button: self.basicTurtleEquipButton,
                                  skinID: self.basicSkinID,
                                  ownedSkins: ownedSkins,
                                  equippedSkin: equippedSkin)
            
            self.updateSkinButton(button: self.tannedTurtlePurchaseButton,
                                  skinID: self.tannedSkinID,
                                  ownedSkins: ownedSkins,
                                  equippedSkin: equippedSkin,
                                  price: self.tannedTurtlePrice)
        }
    }
    
    func updateSkinButton(button: UIButton, skinID: String, ownedSkins: [String], equippedSkin: String, price: Int? = nil) {
        // 기본 거북이는 항상 소유한 것으로 간주
        let isOwned = skinID == basicSkinID || ownedSkins.contains(skinID)
        
        if isOwned {
            if equippedSkin == skinID {
                button.setTitle("장착됨", for: .normal)
                button.isEnabled = false
            } else {
                button.setTitle("장착하기", for: .normal)
                button.isEnabled = true
            }
        } else {
            if let price = price {
                button.setTitle("구매 (\(price)코인)", for: .normal)
            } else {
                button.setTitle("구매하기", for: .normal)
            }
            button.isEnabled = true
        }
    }
    
    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        // 현재 화면을 닫고 메인으로 돌아가기
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func basicTurtleButtonTapped(_ sender: UIButton) {
        equipSkin(skinID: basicSkinID)
    }
    
    @IBAction func tannedTurtleButtonTapped(_ sender: UIButton) {
        // 버튼 타이틀을 기준으로 구매할지 장착할지 결정
        if sender.title(for: .normal)?.starts(with: "구매") == true {
            let alert = UIAlertController(title: "구매 확인", message: "태닝 거북이 스킨을 \(tannedTurtlePrice)코인으로 구매하시겠습니까?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
                self?.purchaseSkin(skinID: self!.tannedSkinID, price: self!.tannedTurtlePrice)
            }))
            present(alert, animated: true)
        } else {
            equipSkin(skinID: tannedSkinID)
        }
    }
    
    // MARK: - Firestore Logic
    func purchaseSkin(skinID: String, price: Int) {
        guard let user = currentUser else { return }
        let userRef = db.collection("users").document(user.uid)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch {
                return nil
            }
            
            let currentCoins = userDocument.data()?["coins"] as? Int ?? 0
            guard currentCoins >= price else {
                // 이 블록 안에서는 UI 업데이트를 직접 할 수 없으므로, 트랜잭션을 중단시키기만 함
                // 에러 포인터를 설정하여 어떤 종류의 실패인지 전달할 수 있음
                return "NotEnoughCoins" // 실패 종류를 식별하기 위한 문자열 반환
            }
            
            // 코인 차감 및 스킨 추가
            transaction.updateData(["coins": currentCoins - price], forDocument: userRef)
            transaction.updateData(["ownedSkins": FieldValue.arrayUnion([skinID])], forDocument: userRef)
            
            return nil
        }) { (result, error) in
            if let failureReason = result as? String, failureReason == "NotEnoughCoins" {
                self.showAlert(message: "코인이 부족합니다.")
            } else if error != nil {
                self.showAlert(message: "구매에 실패했습니다. 다시 시도해주세요.")
            } else {
                self.showAlert(message: "구매 완료!")
                self.updateUI() // 성공 시 UI 갱신
            }
        }
    }
    
    func equipSkin(skinID: String) {
        guard let user = currentUser else { return }
        let userRef = db.collection("users").document(user.uid)
        
        userRef.updateData(["equippedSkin": skinID]) { error in
            if error != nil {
                self.showAlert(message: "스킨 장착에 실패했습니다.")
            } else {
                self.updateUI() // 성공 시 UI 갱신
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
} 
