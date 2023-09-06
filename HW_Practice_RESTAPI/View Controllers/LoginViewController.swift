//
//  LoginViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/8/31.
//

/*
 建立API請求。
 發送請求，並根據響應進行相應的處理。
 在成功登錄後，將 User-Token 、login 儲存到 UserDefaults 以便後續使用。
 根據API的響應，顯示相應的提示訊息給用戶。
 */


import UIKit
import SafariServices

/// 登錄畫面
class LoginViewController: UIViewController {

    // MARK: - Outlets
    /// Email、用戶名稱的輸入欄位
    @IBOutlet weak var emailTextField: UITextField!
    /// 密碼輸入欄位
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - Properties
    /// 用於表示正在進行網路操作等待時的活動指示器（告知使用者他們需要等待）
    let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置啟動活動指示器位置和外觀
        setupActivityIndicatorUI()
        // 收起鍵盤
        setupKeyboardHandling()
    }
    
    // MARK: - UI Setup
    /// 初始化活動指示器的UI設置（點擊畫面，以及當在textfield輸入完畢點擊enter時會收起鍵盤）
    func setupActivityIndicatorUI() {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    /// 點擊畫面，以及當在textfield輸入完畢點擊enter時會收起鍵盤
    func setupKeyboardHandling() {
        // 添加手勢識別，點擊畫面收起鍵盤。
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // 設定 text field 的代理，使其能回應 return 鍵的事件
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    // MARK: - User Actions
    /// 忘記密碼按鈕
    @IBAction func openForgotPasswordLinkButtonTapped(_ sender: UIButton) {
        if let url = URL(string: "https://favqs.com/forgot-password") {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true)
        }
    }

    // 登入按鈕
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // 啟動活動指示器並禁止UI互動
        startLoadingUI()
        // 登入
        login()
    }
    
    // MARK: - API Calls
    /// 執行登錄操作
    func login() {
        // 驗證輸入欄位
        guard let usernameOrEmail = emailTextField.text, !usernameOrEmail.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            stopLoadingUI()     // 停止活動指示器和啟用 UI 互動
            showAlert(message: "請輸入email和密碼")
            return
        }
        
        // 建立API請求
        let sessionRequestBody = UserRequestBody(user: UserSession(login: usernameOrEmail, password: password))
        
        guard let url = URL(string: "https://favqs.com/api/session") else { return }
        var request = createURLRequest(url: url, requestBody: sessionRequestBody)
        request.httpMethod = "POST"

        // 發送API請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 完成API請求，停止活動指示器並允許UI互動
            DispatchQueue.main.async {
                self.stopLoadingUI()
            }
            
            if let error = error {
                print("DataTask error:", error)
                self.showAlert(message: "網路請求失敗")   // 測試（通常用不到）
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                print("Invalid response or Missing data.")
                self.showAlert(message: "伺服器回應有誤")      // 測試（通常用不到）
                return
            }
            
            let decoder = JSONDecoder()
            // 優先檢查是否有錯誤訊息，因為即使是200的狀態碼，也可能是一個錯誤訊息，所以先解析錯誤。
            if let errorResponse = try? decoder.decode(UserSeeionErrorResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.showAlert(message: errorResponse.message)
                }
                return
            }
            
            // 如果沒有錯誤，解析正常的回應。
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                do {
                    let responseBody = try decoder.decode(UserResponseBody.self, from: data)
                    // print(responseBody.userToken)       // 觀察userToken
                    UserDefaults.standard.set(responseBody.userToken, forKey: "userToken")  // 儲存User Token
                    UserDefaults.standard.set(responseBody.login, forKey: "userLogin")   // 儲存用戶名 （用於使用者的個人資訊url、使用者的個人收藏列表）
                    // 跳轉到 MainListOfQuotesTableViewController
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "showMainListFromLogin", sender: self)
                    }
                } catch {
                    print("Error decoding the response body:", error)
                    self.showAlert(message: "解析伺服器回應失敗")        // 測試（通常用不到）
                }
                
            } else {
                print("Unexpected status code:", httpResponse.statusCode)
                self.showAlert(message: "伺服器回應有誤")               // 測試（通常用不到）
            }
            
        }.resume()
    }
    
    /// 根據給定的 URL 和 RequestBody 創建URLRequest
    func createURLRequest(url: URL, requestBody: UserRequestBody) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let appToken = "55d03c09545078bc581705b093a7f0a2"       // App-Token
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
        
        // 進行編碼
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(requestBody)
            request.httpBody = jsonData
        } catch {
            print("Error encoding session:", error)
        }
        
        return request
    }
    
    // MARK: - UI Handling

    /// 啟動活動指示器並且禁止UI互動
    func startLoadingUI() {
        self.activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
    }
    
    /// 停止活動指示器並且啟動UI互動
    func stopLoadingUI() {
        self.activityIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
    }

    /// 顯示警告訊息
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "錯誤", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
        alertController.addAction(okAction)
        print(message)  // 測試觀察用
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// 添加dismissKeyboard方法來收起鍵盤
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Navigation

    /// 隱藏在 TabBarController 中的返回按鈕（因為由 LoginVC 到 MainListVC ( 有 tabBarController）
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            tabBarController.navigationItem.hidesBackButton = true
        }
    }
    
    /// 當視圖即將出現時隱藏NavigationBar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // 顯示 NavigationBar（確保當轉到其他Controller時，NavigationBar會重新出現）
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
        
}

// MARK: - TextField Delegate
/// 點擊 "return" 鍵時，呼叫 textFieldShouldReturn 方法，並收起鍵盤
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}



/*
 import UIKit
 import SafariServices


 /// 登錄畫面
 class LoginViewController: UIViewController {

     /// Email、用戶名稱的輸入欄位
     @IBOutlet weak var emailTextField: UITextField!
     /// 密碼輸入欄位
     @IBOutlet weak var passwordTextField: UITextField!
     
     /// 用於表示正在進行網路操作等待時的活動指示器（告知使用者他們需要等待）
     let activityIndicator = UIActivityIndicatorView(style: .large)

     override func viewDidLoad() {
         super.viewDidLoad()
         
         // 設置啟動活動指示器位置和外觀
         activityIndicator.center = view.center
         activityIndicator.hidesWhenStopped = true
         view.addSubview(activityIndicator)
         
         // 添加手勢識別，點擊畫面收起鍵盤。
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
         view.addGestureRecognizer(tapGesture)
         
         // 與鍵盤收起有關（點擊鍵盤enter收起）
         emailTextField.delegate = self
         passwordTextField.delegate = self
     }
     
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         navigationController?.setNavigationBarHidden(true, animated: animated)
     }
     
     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         navigationController?.setNavigationBarHidden(false, animated: animated)
     }


     
     // 登錄按鈕
     @IBAction func loginButtonTapped(_ sender: UIButton) {
         
         // 啟動活動指示器並禁止UI互動
         activityIndicator.startAnimating()
         self.view.isUserInteractionEnabled = false
         
         // 驗證輸入
         guard let usernameOrEmail = emailTextField.text, !usernameOrEmail.isEmpty,
               let password = passwordTextField.text, !password.isEmpty else {
             stopLoadingUI()     // 停止活動指示器和啟用 UI 互動
             showAlert(message: "請輸入email和密碼")
             return
         }
         
         // 建立API請求
         let sessionRequestBody = UserRequestBody(user: UserSession(login: usernameOrEmail, password: password))
         
         guard let url = URL(string: "https://favqs.com/api/session") else { return }
         
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         let appToken = "55d03c09545078bc581705b093a7f0a2"       // App-Token
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         
         // 進行編碼
         let encoder = JSONEncoder()
         do {
             let jsonData = try encoder.encode(sessionRequestBody)
             request.httpBody = jsonData
         } catch {
             print("Error encoding session:", error)
             stopLoadingUI()
             return
         }
         
         // 發送API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             
             // 完成API請求，停止活動指示器並允許UI互動
             DispatchQueue.main.async {
                 self.stopLoadingUI()
             }
             
             if let error = error {
                 print("DataTask error:", error)
                 self.showAlert(message: "網路請求失敗")   // 測試（通常用不到）
                 return
             }
             
             guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                 print("Invalid response or Missing data.")
                 self.showAlert(message: "伺服器回應有誤")      // 測試（通常用不到）
                 return
             }
             
             let decoder = JSONDecoder()
             // 優先檢查是否有錯誤訊息，因為即使是200的狀態碼，也可能是一個錯誤訊息，所以先解析錯誤。
             if let errorResponse = try? decoder.decode(UserSeeionErrorResponse.self, from: data) {
                 DispatchQueue.main.async {
                     self.showAlert(message: errorResponse.message)
                 }
                 return
             }
             
             // 如果沒有錯誤，解析正常的回應。
             if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                 do {
                     let responseBody = try decoder.decode(UserResponseBody.self, from: data)
                     UserDefaults.standard.setValue(responseBody.userToken, forKey: "userToken") // 儲存User Token
                     UserDefaults.standard.set(responseBody.login, forKey: "userLogin")   // 儲存用戶名 （用於使用者的個人資訊url、使用者的個人收藏列表）
                     // 跳轉到 MainListOfQuotesTableViewController
                     DispatchQueue.main.async {
                         self.performSegue(withIdentifier: "showMainListFromLogin", sender: self)
                     }
                 } catch {
                     print("Error decoding the response body:", error)
                     self.showAlert(message: "解析伺服器回應失敗")        // 測試（通常用不到）
                 }
                 
             } else {
                 print("Unexpected status code:", httpResponse.statusCode)
                 self.showAlert(message: "伺服器回應有誤")               // 測試（通常用不到）
             }
             
         }.resume()
         
     }
     
     /// 忘記密碼
     @IBAction func openForgotPasswordLinkButtonTapped(_ sender: UIButton) {
         if let url = URL(string: "https://favqs.com/forgot-password") {
             let safariViewController = SFSafariViewController(url: url)
             present(safariViewController, animated: true)
         }
     }
     
     /// 顯示提示訊息
     func showAlert(message: String) {
         let alertController = UIAlertController(title: "錯誤", message: message, preferredStyle: .alert)
         let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
         alertController.addAction(okAction)
         self.present(alertController, animated: true, completion: nil)
     }
     
     /// 停止活動指示器並且啟動UI互動
     func stopLoadingUI() {
         self.activityIndicator.stopAnimating()
         self.view.isUserInteractionEnabled = true
     }
     
     // 添加dismissKeyboard方法來收起鍵盤
     @objc func dismissKeyboard() {
         view.endEditing(true)
     }
     
     // 隱藏在 TabBarController 中的返回按鈕（因為由 LoginVC 到 MainListVC ( 有 tabBarController）
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if let tabBarController = segue.destination as? UITabBarController {
             tabBarController.navigationItem.hidesBackButton = true
         }
     }
         
 }

 /// 點擊 "return" 鍵時，呼叫 textFieldShouldReturn 方法，並收起鍵盤
 extension LoginViewController: UITextFieldDelegate {
     func textFieldShouldReturn(_ textField: UITextField) -> Bool {
         textField.resignFirstResponder()
         return true
     }
     
 }
 */
