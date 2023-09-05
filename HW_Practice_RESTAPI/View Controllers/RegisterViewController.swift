//
//  RegisterViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/8/31.
//


/*
 需要收集用戶的登入名稱（login）、電子郵件（email）和密碼（password），並使用提供的API進行運用。
 
 1.在RegisterViewController中添加三個UITextField，用於使用者輸入其登入名稱、電子郵件和密碼。
 2.添加一個 「註冊」 按鈕，當點擊時會觸發註冊過程。
 3.使用URLSession發送POST請求到/api/users，並將用戶輸入的資料作為請求。
 */

import UIKit

/// RegisterViewController 負責註冊新帳號的流程
class RegisterViewController: UIViewController {

    /// 使用者的登入名稱
    @IBOutlet weak var loginTextField: UITextField!
    /// 使用者的電子郵件
    @IBOutlet weak var emailTextField: UITextField!
    /// 使用者的密碼
    @IBOutlet weak var passwordTextField: UITextField!
    
    /// 驗證 login 的正則表達式（學習）
    let loginRegex = "^[a-zA-Z0-9_]{1,20}$"
    /// 驗證 email 的正則表達式（學習）
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    /// 活動指示器（等待伺服器回應時，讓用戶知道目前正在執行）
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置UI元件（活動指示器、鍵盤收起）
        setupActivityIndicator()
        setupKeyboardHandling()
        // 設定 navigation bar 的 button 顏色
        self.navigationController?.navigationBar.tintColor = UIColor(red: 42/255, green: 71/255, blue: 94/255, alpha: 1)        
    }
    
    /// 設定鍵盤的處理方法：點擊畫面以及當在textfield輸入完畢點擊enter時會收起鍵盤
    func setupKeyboardHandling() {
        // 添加手勢收起鍵盤
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        loginTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    /// 設定活動指示器
    func setupActivityIndicator() {
        // 設定活動指示器位置、外觀
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    /// 當用戶點擊註冊按鈕時進行的操作，包括驗證檢查輸入和發送API請求
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        
        guard let login = loginTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text else {
            return
        }
        
        // 檢查Login格式（學習）
        if !NSPredicate(format: "SELF MATCHES %@", loginRegex).evaluate(with: login) {
            stopLoadingUI()
            showAlert(message: "登錄名稱只能包含字母(a-z)、數字(0-9)和底線。長度必須在1至20個字之間")
            return
        }
        
        // 檢查Email格式（學習）
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
            stopLoadingUI()
            showAlert(message: "請輸入有效的電子郵件地址")
            return
        }
        
        // 檢查密碼長度
        if password.count < 5 || password.count > 120 {
            stopLoadingUI()
            showAlert(message: "密碼長度必須在5至120個字之間")
            return
        }
        
        // 如果所有驗證都通過，則發送用戶註冊的API請求
        registerUser(login: login, email: email, password: password)
    }
    
    /// 發送API請求進行用戶註冊
    func registerUser(login: String, email: String, password: String) {
        // 啟動活動指示器和禁止UI互動
        activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
        
        // 建立API請求
        let user = CreatUserRequestBody(user: CreateUser(login: login, email: email, password: password))
        let url = URL(string: "https://favqs.com/api/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let appToken = "55d03c09545078bc581705b093a7f0a2"       // App-Token
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
        
        // 使用 JSONEncoder 將request進行編碼
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(user)
            request.httpBody = jsonData
        } catch {
            print("Error encoding user:", error)
            return
        }

        // 發送API請求並處理response
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 主線程停止活動指示器和啟動UI互動
            DispatchQueue.main.async {
                self.stopLoadingUI()
            }
            
            // 處理API response
            if let error = error {
                print("DataTask error:", error)
                self.showAlert(message: "網路請求失敗")       // 測試（通常用不到）
                return
            }
            
            // 檢查從伺服器接收到的回應是否是有效的 HTTPURLResponse，且確保返回的數據(data)存在
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                print("Invalid response or Missing data.")
                self.showAlert(message: "伺服器回應有誤")      // 測試（通常用不到）
                return
            }
            
            let decoder = JSONDecoder()
            // 優先檢查是否有錯誤訊息
            if let errorResponse = try? decoder.decode(CreatUserErrorResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.showAlert(message: errorResponse.message)  // 來自伺服器端檢查後的註冊失敗訊息
                }
                return
            }
            
            // 如果沒有錯誤，解析正常的回應
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                do {
                    let responseBody = try decoder.decode(CreatUserResponseBody.self, from: data)
                    // 儲存獲得的User Token和登錄名稱
//                    UserDefaults.standard.setValue(responseBody.userToken, forKey: "userToken")   // 儲存User Token
                    UserDefaults.standard.set(responseBody.userToken, forKey: "userToken")
                    UserDefaults.standard.set(responseBody.login, forKey: "userLogin")            // 儲存用戶名 （用於使用者的個人資訊url、使用者的個人收藏列表）
                    // 顯示註冊成功消息
                    DispatchQueue.main.async {
                        self.showAlert(message: "註冊成功！", success: true) // success為true
                    }

                } catch {
                    print("Error decoding the response body:", error)
                    self.showAlert(message: "解析伺服器回應失敗")        // 測試（通常用不到）
                }
                
            }
            // 當API返回非200的狀態碼時，處理該錯誤，並在必要時向使用者顯示錯誤消息。
            else {
                print("Unexpected status code:", httpResponse.statusCode)
                self.showAlert(message: "伺服器回應有誤")              // 測試（通常用不到）
            }
        }.resume()
    }
    
    
    /// 顯示錯誤訊息
    func showAlert(message: String, success: Bool = false) {
        // print("Attempting to show alert with message:", message)    // 測試觀察是否被調用
        let alertController = UIAlertController(title: success ? "成功" : "錯誤", message: message, preferredStyle: .alert)
        print(message)
        // 如果是成功的訊息，點擊OK後導向主畫面（MainListOfQuotes)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if success {
                self.performSegue(withIdentifier: "showMainListFromRegister", sender: self)
            }
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    
    /// 停止活動指示器並重新啟用用戶互動
    func stopLoadingUI() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    /// 添加dismissKeyboard方法來收起鍵盤
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /// 隱藏在 TabBarController 中的返回按鈕（我在storyboard是由 RegisterVC 到 MainListVC ( 因為有tabBarController ）
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            tabBarController.navigationItem.hidesBackButton = true
        }
    }

}

/// 點擊 "return" 鍵時，呼叫 textFieldShouldReturn 方法，並收起鍵盤
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}



// 未整合版本（未優先檢查錯誤的版本errorResponse）
/*
 /// 註冊操作
 class RegisterViewController: UIViewController {

     /// 登錄名稱
     @IBOutlet weak var loginTextField: UITextField!
     /// 電子郵件
     @IBOutlet weak var emailTextField: UITextField!
     /// 密碼
     @IBOutlet weak var passwordTextField: UITextField!
     
     // 驗證規則（學習）
     let loginRegex = "^[a-zA-Z0-9_]{1,20}$"
     let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
     let appToken = "55d03c09545078bc581705b093a7f0a2"
     
     /// 活動指示器（等待伺服器回應時，讓用戶知道目前正在執行）
     let activityIndicator = UIActivityIndicatorView(style: .large)
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // 設置活動指示器
         setupActivityIndicator()
         
         // 添加手勢識別器到主要視圖
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
         view.addGestureRecognizer(tapGesture)
         
         loginTextField.delegate = self
         emailTextField.delegate = self
         passwordTextField.delegate = self
         
         // 設定 navigation bar 的 button 顏色
         self.navigationController?.navigationBar.tintColor = UIColor(red: 42/255, green: 71/255, blue: 94/255, alpha: 1)
     }
     
     /// 註冊按鈕
     @IBAction func registerButtonTapped(_ sender: UIButton) {
         
         // 啟動活動指示器並禁止畫面互動
         activityIndicator.startAnimating()
         self.view.isUserInteractionEnabled = false
         
         guard let login = loginTextField.text,
               let email = emailTextField.text,
               let password = passwordTextField.text else {
             return
         }
         
         // 檢查Login格式
         if !NSPredicate(format: "SELF MATCHES %@", loginRegex).evaluate(with: login) {
             stopLoadingUI()
             showAlert(message: "登錄名稱只能包含字母(a-z)、數字(0-9)和底線。長度必須在1至20個字之間")
             return
         }
         
         // 檢查Email格式
         if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
             stopLoadingUI()
             showAlert(message: "請輸入有效的電子郵件地址")
             return
         }
         
         // 檢查密碼長度
         if password.count < 5 || password.count > 120 {
             stopLoadingUI()
             showAlert(message: "密碼長度必須在5至120個字之間")
             return
         }
         
         // 建立API請求
         let user = CreatUserRequestBody(user: CreateUser(login: login, email: email, password: password))
         let url = URL(string: "https://favqs.com/api/users")!
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         let appToken = "55d03c09545078bc581705b093a7f0a2"       // App-Token
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         
         // 使用 JSONEncoder 進行編碼
         let encoder = JSONEncoder()
         do {
             let jsonData = try encoder.encode(user)
             request.httpBody = jsonData
         } catch {
             print("Error encoding user:", error)
             return
         }
         
         // 發送API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             // 一旦進入這個回調，就停止活動指示器並允許畫面互動
             DispatchQueue.main.async {
                 self.activityIndicator.stopAnimating()
                 self.view.isUserInteractionEnabled = true
             }
                         
             if let error = error {
                 print("DataTask error:", error)
                 return
             }
             
             guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                 print("Invalid response or Missing data.")
                 return
             }
             
             // print("HTTP Status Code:", httpResponse.statusCode)             // 測試用：觀察statusCode是多少
             // print(String(data: data, encoding: .utf8) ?? "Invalid Data")    // 測試用：檢查返回的JSON數據

             let decoder = JSONDecoder()
             // 處理成功的回應
             if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                 do {
                     let responseBody = try decoder.decode(CreatUserResponseBody.self, from: data)
                     print(responseBody)
                     UserDefaults.standard.setValue(responseBody.userToken, forKey: "userToken")         // 儲存User Token
                     UserDefaults.standard.set(responseBody.login, forKey: "userLogin")                  // 儲存用戶名 （用於使用者的個人資訊url、使用者的個人收藏列表）
                     // 註冊成功
                     DispatchQueue.main.async {
                         self.showAlert(message: "註冊成功！", success: true)
                     }

                 } catch {
                     // 即使狀態碼為 200，伺服器會返回一個錯誤訊息。當嘗試註冊一個已經存在的用戶時，會成功執行（因此狀態碼為 200），但仍然返回一個錯誤訊息。
                     do {
                         // 如果解碼 ResponseBody 失敗，會進一步嘗試解碼 ErrorResponse，並顯示在showAlert上
                         let errorResponse = try decoder.decode(CreatUserErrorResponse.self, from: data)
                         DispatchQueue.main.async {
                             self.showAlert(message: errorResponse.message)
                         }
                     } catch {
                         // 如果兩次解碼都失敗，那麼會print一個錯誤訊息，表示無法正確解析伺服器的回應。
                         print("Error decoding both success and error responses:", error)
                     }
                 }
                 
             }
             // 當API返回非200的狀態碼時，處理該錯誤，並在必要時向使用者顯示錯誤消息。
             else {
                 do {
                     let errorResponse = try decoder.decode(CreatUserErrorResponse.self, from: data)
                     DispatchQueue.main.async {
                         self.showAlert(message: errorResponse.message)
                     }
                 } catch {
                     print("Error decoding error response:", error)
                 }
             }
         }.resume()
         
     }
     
     /// 顯示錯誤訊息
     func showAlert(message: String, success: Bool = false) {
         
         // print("Attempting to show alert with message:", message)    // 測試觀察是否被調用
         
         let alertController = UIAlertController(title: success ? "成功" : "錯誤", message: message, preferredStyle: .alert)
         
         // 如果是成功的訊息，點擊OK後導向主畫面（MainListOfQuotes)
         let okAction = UIAlertAction(title: "OK", style: .default) { _ in
             if success {
                 self.performSegue(withIdentifier: "showMainListFromRegister", sender: self)
             }
         }
         
         alertController.addAction(okAction)
         self.present(alertController, animated: true)
     }
     
     /// 停止活動指示器並重新啟用用戶互動
     func stopLoadingUI() {
         DispatchQueue.main.async {
             self.activityIndicator.stopAnimating()
             self.view.isUserInteractionEnabled = true
         }
     }
     
     /// 設定活動指示器
     func setupActivityIndicator() {
         // 設定活動指示器位置、外觀
         activityIndicator.center = view.center
         activityIndicator.hidesWhenStopped = true
         view.addSubview(activityIndicator)
     }
     
     // 添加dismissKeyboard方法來收起鍵盤
     @objc func dismissKeyboard() {
         view.endEditing(true)
     }
     
     // 隱藏在 TabBarController 中的返回按鈕（因為由 RegisterVC 到 MainListVC ( 因為有tabBarController ）
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if let tabBarController = segue.destination as? UITabBarController {
             tabBarController.navigationItem.hidesBackButton = true
         }
     }

 }

 /// 點擊 "return" 鍵時，呼叫 textFieldShouldReturn 方法，並收起鍵盤
 extension RegisterViewController: UITextFieldDelegate {
     func textFieldShouldReturn(_ textField: UITextField) -> Bool {
         textField.resignFirstResponder()
         return true
     }
 }
 */
