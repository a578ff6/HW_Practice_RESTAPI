//
//  UserProfileViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/1.
//

import UIKit

/// 顯示使用者個人的詳細資訊
class UserProfileViewController: UIViewController {

    /// 使用者的email
    @IBOutlet weak var userEmailLabel: UILabel!
    /// 使用者的登錄名稱
    @IBOutlet weak var userLoginNameLabel: UILabel!
    /// 使用者引言收藏數
    @IBOutlet weak var favoritesCountLabel: UILabel!
    /// 使用者在關注的人數
    @IBOutlet weak var followingLabel: UILabel!
    /// 關注該使用者的人數
    @IBOutlet weak var followerLabel: UILabel!
    /// 是否是Pro用戶
    @IBOutlet weak var proUserSwitch: UISwitch!
    
    /// App-Token
    let appToken = "55d03c09545078bc581705b093a7f0a2"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 初始化用戶資料
        loadUserData()
        
        // 當收藏引言狀態更改時，設定通知觀察者重新加載使用者資料
        // 每當 QuoteFavoritedStatusChanged 通知被發送時，UserProfileViewController 就會重新加載使用者資料，以反映收藏引言的最新狀態。
        NotificationCenter.default.addObserver(self, selector: #selector(loadUserData), name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
    }
    
    /// 為 UserProfileViewController 單獨設置 title，並在每次視圖控制器出現時更改它。
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "User Profile"
    }
    
    /// 登出帳號（使用 UINavigationController去 push：因為 UserProfileViewController 在一個 UINavigationController 中，可以  pop 到登錄畫面。）
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        // 創建 UIAlertController 提示用戶是否確定要登出
        let alertController = UIAlertController(title: "登出", message: "你確定要登出嗎？", preferredStyle: .alert)
        // 創建 "確定" 按鈕，點擊後會執行登出操作
        let confrimAction = UIAlertAction(title: "確定", style: .destructive) { _ in
            // 執行登出
            self.destroySession()
        }
        // 創建 "取消" 按鈕
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(confrimAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    /// 資料加載與更新
    @objc func loadUserData() {
        // 從 UserDefaults 中獲取使用者登錄名稱
        guard let userLogin = UserDefaults.standard.string(forKey: "userLogin") else {
            print("User Login not found!")
            return
        }
        // 使用用戶的登錄名稱來建立API請求URL
        guard let url = URL(string: "https://favqs.com/api/users/\(userLogin)") else {
            print("Invalid URL!")
            return
        }
        
        // 設定API請求
        let request = createRequest(for: url, httpMethod: "GET")
        // 發送API請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching user data:", error)
                return
            }
            
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    let userData = try decoder.decode(GetUser.self, from: data)
                    // 在主線程更新UI
                    DispatchQueue.main.async {
                        self.updateUI(with: userData)
                    }
                } catch {
                    print("Error decoding response:", error)    // 如返回錯誤No user session found
                }
            }
        }.resume()
        
    }
    
    /// 進行登出操作。
    func destroySession() {
        // 創建API請求URL
        guard let url = URL(string: "https://favqs.com/api/session") else {
            print("Invalid URL!")
            return
        }

        // createRequest 建立 API請求
        let request = createRequest(for: url, httpMethod: "DELETE")
        
        // 發送非同步API請求來進行登出操作
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 檢查請求是否有錯誤
            if let error = error {
                print("Error destroying session:", error)
                return
            }
            // 檢查是否接收到數據
            guard let data = data else {
                print("No data received.")
                return
            }

            // 解析返回的數據
            let decoder = JSONDecoder()
            do {
                let logoutResponse = try decoder.decode(LogoutResponse.self, from: data)
                print("Successfully decoded LogoutResponse")     // 觀察測試
                print(logoutResponse.message)                    // print登出訊息
            } catch {
                print("Error decoding LogoutResponse:", error)
            }
            
            // 移除保存的使用者訊息
            UserDefaults.standard.removeObject(forKey: "userLogin")
            UserDefaults.standard.removeObject(forKey: "userToken")
            // 主線程返回到 LoginViewController
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }.resume()
    }
    
    /// 創建 API 請求的共用方法
    func createRequest(for url: URL, httpMethod: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
        if let userToken = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue(userToken, forHTTPHeaderField: "User-Token")
        }
        return request
    }
    
    /// 更新UI元件
    func updateUI(with userData: GetUser) {
        userEmailLabel.text = userData.accountDetails.email
        userLoginNameLabel.text = userData.login
        favoritesCountLabel.text = userData.publicFavoritesCount.description
        followingLabel.text = userData.following.description
        followerLabel.text = userData.followers.description
        proUserSwitch.isOn = userData.pro ?? false
    }
    
    // 確保移除Observer以避免內存泄漏
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



// 測試版本（以為有LogoutErrorResponse)
/*
 /// 顯示使用者個人的詳細資訊
 class UserProfileViewController: UIViewController {

     /// 使用者的email
     @IBOutlet weak var userEmailLabel: UILabel!
     /// 使用者的登錄名稱
     @IBOutlet weak var userLoginNameLabel: UILabel!
     /// 使用者引言收藏數
     @IBOutlet weak var favoritesCountLabel: UILabel!
     /// 使用者在關注的人數
     @IBOutlet weak var followingLabel: UILabel!
     /// 關注該使用者的人數
     @IBOutlet weak var followerLabel: UILabel!
     /// 是否是Pro用戶
     @IBOutlet weak var proUserSwitch: UISwitch!
     
     /// App-Token
     let appToken = "55d03c09545078bc581705b093a7f0a2"
     
     override func viewDidLoad() {
         super.viewDidLoad()
         // 初始化用戶資料
         loadUserData()
         
         // 當收藏引言狀態更改時，設定通知觀察者重新加載使用者資料
         // 每當 QuoteFavoritedStatusChanged 通知被發送時，UserProfileViewController 就會重新加載使用者資料，以反映收藏引言的最新狀態。
         NotificationCenter.default.addObserver(self, selector: #selector(loadUserData), name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
     }
     
     /// 為 UserProfileViewController 單獨設置 title，並在每次視圖控制器出現時更改它。
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         self.tabBarController?.navigationItem.title = "User Profile"
     }
     
     /// 登出帳號（使用 UINavigationController去 push：因為 UserProfileViewController 在一個 UINavigationController 中，可以  pop 到登錄畫面。）
     @IBAction func logoutButtonTapped(_ sender: UIButton) {
         // 創建 UIAlertController
         let alertController = UIAlertController(title: "登出", message: "你確定要登出嗎？", preferredStyle: .alert)
         // 創建 "確定" 按鈕
         let confrimAction = UIAlertAction(title: "確定", style: .destructive) { (acion) in
             self.destroySession { success in
                 if success {
                     // 移除保存的使用者訊息
                     UserDefaults.standard.removeObject(forKey: "userLogin")
                     UserDefaults.standard.removeObject(forKey: "userToken")
                     
                     print("觀察") // 測試觀察
                     
                     // 主線程返回到 LoginViewController
                     DispatchQueue.main.async {
                         print("觀察DispatchQueue")    // 測試觀察
                         self.navigationController?.popToRootViewController(animated: true)
                     }
                 } else {
                     print("Failed to destroy session")  // 測試（用不到）
                 }
             }
         }
         // 創建 "取消" 按鈕
         let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
         alertController.addAction(confrimAction)
         alertController.addAction(cancelAction)
         present(alertController, animated: true, completion: nil)
     }
     
     
     /// 資料加載與更新
     @objc func loadUserData() {
         // 從 UserDefaults 中獲取使用者登錄名稱
         guard let userLogin = UserDefaults.standard.string(forKey: "userLogin") else {
             print("User Login not found!")
             return
         }
         // 使用用戶的登錄名稱來建立API請求URL
         guard let url = URL(string: "https://favqs.com/api/users/\(userLogin)") else {
             print("Invalid URL!")
             return
         }
         
         // 設定API請求
         let request = createRequest(for: url, httpMethod: "GET")
         
         // 發送API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Error fetching user data:", error)
                 return
             }
             
             if let data = data {
                 let decoder = JSONDecoder()
                 do {
                     let userData = try decoder.decode(GetUser.self, from: data)
                     // 在主線程更新UI
                     DispatchQueue.main.async {
                         self.updateUI(with: userData)
                     }
                 } catch {
                     print("Error decoding response:", error)    // 如返回錯誤No user session found
                 }
             }
         }.resume()
         
     }
     
     /// 進行登出操作。
     /// - Parameter completion: 一個接收 Boolean 參數的閉包，用於表示登出操作是否成功。
     func destroySession(completion: @escaping(Bool) -> Void) {
         // 創建API請求URL
         guard let url = URL(string: "https://favqs.com/api/session") else {
             print("Invalid URL!")
             completion(false)   // URL建立失敗，返回失敗結果
             return
         }

         // createRequest 建立 API請求
         let request = createRequest(for: url, httpMethod: "DELETE")

         // 發送非同步API請求來進行登出操作
         URLSession.shared.dataTask(with: request) { data, response, error in
             // 檢查是否在請求中發生錯誤
             if let error = error {
                 print("Error destroying session:", error)
                 completion(false)       // 請求錯誤，返回失敗結果
                 return
             }
             // 確保收到了數據
             guard let data = data else {
                 print("No data received.")
                 completion(false)        // 沒有接收到數據，返回失敗結果
                 return
             }
             
             // 解析返回的數據
             let decoder = JSONDecoder()
             if let logoutResponse = try? decoder.decode(LogoutResponse.self, from: data) {
                                  
                 print(logoutResponse.message) // print登出訊息
                 completion(true)             // 登出成功，返回成功結果
             } else if let logoutErrorResponse = try? decoder.decode(LogoutErrorResponse.self, from: data) {
                 
                 print(logoutErrorResponse.message) // print錯誤訊息
                 completion(false)                  // 解析錯誤訊息，返回失敗結果
             } else {
                 print("Unable to decode the response.")
                 completion(false)                // 無法解析回應，返回失敗結果
             }
         }.resume()
         
     }
     
     /// 創建 API 請求的共用方法
     func createRequest(for url: URL, httpMethod: String) -> URLRequest {
         var request = URLRequest(url: url)
         request.httpMethod = httpMethod
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         if let userToken = UserDefaults.standard.string(forKey: "userToken") {
             request.setValue(userToken, forHTTPHeaderField: "User-Token")
         }
         return request
     }
     
     /// 更新UI元件
     func updateUI(with userData: GetUser) {
         userEmailLabel.text = userData.accountDetails.email
         userLoginNameLabel.text = userData.login
         favoritesCountLabel.text = userData.publicFavoritesCount.description
         followingLabel.text = userData.following.description
         followerLabel.text = userData.followers.description
         proUserSwitch.isOn = userData.pro ?? false
     }
     
     // 確保移除Observer以避免內存泄漏
     deinit {
         NotificationCenter.default.removeObserver(self)
     }
 }
 */



// 未使用 Destroy Session
/*
 import UIKit

 /// 顯示使用者個人的詳細資訊
 class UserProfileViewController: UIViewController {

     /// 使用者的email
     @IBOutlet weak var userEmailLabel: UILabel!
     /// 使用者的登錄名稱
     @IBOutlet weak var userLoginNameLabel: UILabel!
     /// 使用者引言收藏數
     @IBOutlet weak var favoritesCountLabel: UILabel!
     /// 使用者在關注的人數
     @IBOutlet weak var followingLabel: UILabel!
     /// 關注該使用者的人數
     @IBOutlet weak var followerLabel: UILabel!
     /// 是否是Pro用戶
     @IBOutlet weak var proUserSwitch: UISwitch!
     

     override func viewDidLoad() {
         super.viewDidLoad()

         // 加載使用者資料
         loadUserData()
         
         // 設定通知觀察者，當收藏引言狀態更改時重新加載使用者資料
         // 每當 QuoteFavoritedStatusChanged 通知被發送時，UserProfileViewController 就會重新加載使用者資料，以反映收藏引言的最新狀態。
         NotificationCenter.default.addObserver(self, selector: #selector(loadUserData), name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
         
     }
     
     /// 為 UserProfileViewController 單獨設置 title，並在每次視圖控制器出現時更改它。
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         self.tabBarController?.navigationItem.title = "User Profile"
     }
     
     
     /// 登出帳號（使用 UINavigationControlle r去 push：因為 UserProfileViewController 在一個 UINavigationController 中，可以  pop 到登錄畫面。）
     @IBAction func logoutButtonTapped(_ sender: UIButton) {
         // 創建 UIAlertController
         let alertController = UIAlertController(title: "登出", message: "你確定要登出嗎？", preferredStyle: .alert)
         
         // 創建 "確定" 按鈕
         let confrimAction = UIAlertAction(title: "確定", style: .destructive) { (acion) in
             // 移除保存的使用者訊息
             UserDefaults.standard.removeObject(forKey: "userLogin")
             UserDefaults.standard.removeObject(forKey: "userToken")
             // 返回到 LoginViewController
             self.navigationController?.popToRootViewController(animated: true)
         }
         
         // 創建 "取消" 按鈕
         let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)

         alertController.addAction(confrimAction)
         alertController.addAction(cancelAction)
         // 顯示警告控制器
         present(alertController, animated: true, completion: nil)
     }
     
     
     @objc func loadUserData() {
         // 檢查 UserDefaults 是否有使用者的登錄名稱
         guard let userLogin = UserDefaults.standard.string(forKey: "userLogin") else {
             print("User Login not found!")
             return
         }
         
         // 使用使用者的登錄名稱來建立API請求URL
         guard let url = URL(string: "https://favqs.com/api/users/\(userLogin)") else {
             print("Invalid URL!")
             return
         }
         
         // 設定API請求
         var request = URLRequest(url: url)
         request.httpMethod = "GET"
         let appToken = "55d03c09545078bc581705b093a7f0a2"       // App-Token
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         
         // 使用User-Token進行身份驗證
         if let userToken = UserDefaults.standard.string(forKey: "userToken") {
             request.setValue(userToken, forHTTPHeaderField: "User-Token")
         } else {
             print("User Token not found!")
             return
         }
         
         // 發送API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Error fetching user data:", error)
                 return
             }
             
             if let data = data {
                 let decoder = JSONDecoder()
                 do {
                     let userData = try decoder.decode(GetUser.self, from: data)
                     // 更新UI在主線程
                     DispatchQueue.main.async {
                         self.updateUI(with: userData)
                     }
                 } catch {
                     print("Error decoding response:", error)
                 }
             }
         }.resume()
         
     }
     // 確保移除Observer以避免內存泄漏
     deinit {
         NotificationCenter.default.removeObserver(self)
     }
     
     /// 更新UI元件
     func updateUI(with userData: GetUser) {
         userEmailLabel.text = userData.accountDetails.email
         userLoginNameLabel.text = userData.login
         favoritesCountLabel.text = userData.publicFavoritesCount.description
         followingLabel.text = userData.following.description
         followerLabel.text = userData.followers.description
         proUserSwitch.isOn = userData.pro ?? false
     }

 }
 */
