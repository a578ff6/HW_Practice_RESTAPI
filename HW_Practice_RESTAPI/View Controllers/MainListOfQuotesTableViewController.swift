//
//  MainListOfQuotesTableViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/8/31.
//



import UIKit
import AVFoundation

/// /// 主要顯示引言列表的表格視圖控制器，用於顯示引言列表。用戶可以點擊收藏引言。
class MainListOfQuotesTableViewController: UITableViewController {
    
    // MARK: - Properties
    /// 從API取得的引言陣列
    var quoteItems: [Quote] = []
    /// 創建 AVSpeechSynthesizer 功能
    var speechSynthesizer = AVSpeechSynthesizer()
    /// 活動指示器
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // 載入引言列表
        loadQuotes()
        // 註冊「取消收藏引言」的通知
        NotificationCenter.default.addObserver(self, selector: #selector(quoteUnfavorited(_:)), name: NSNotification.Name("QuoteUnfavorited"), object: nil)
        // 設置活動指示器
        setupActivityIndicator()
        // 設置分頁相關功能
        setupTableView()
    }
    
    /// 設置Title（因為我 Navigation Controller 與 Tab Bar Controller 的連結，故使用此方式。（學習））
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton = true  // 隱藏BarButtonItem
        self.tabBarController?.navigationItem.title = "Main List Of Quotes"
    }
    
    /// 當切換到其他畫面時，停止朗讀
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 如果 AVSpeechSynthesizer 正在朗讀，則停止它
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - UI Setup
    /// 設置活動指示器
    func setupActivityIndicator() {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    /// 啟動活動指示器，禁用UI互動
    func startLoadingUI() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    /// 停止活動指示器，啟動UI互動
    func stopLoadingUI() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    /// 設置分頁滾動調整：防止自動調整 contentInset （學習）
    func setupTableView() {
        
        // 設置分頁效果
        tableView.isPagingEnabled = true

        // UITableView 在 iOS 11 或更高版本中，可以在 Size Inspector 中找到 Content Insets 選項，並從下拉菜單中選擇 Never。這將對應於 tableView.contentInsetAdjustmentBehavior = .never。
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    // MARK: - User Interactions
    /// 滑動到另一個 cell 時朗讀停止
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 確認當前的單元格是否與上一次的單元格不同，如果是，則停止朗讀
        // 計算當前顯示的單元格索引
        
        if tableView.indexPathsForVisibleRows != nil {
            // 如果 AVSpeechSynthesizer 正在朗讀，則停止它
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
    }
    
    // MARK: - Notifications
    /// 當接收到取消收藏名言的通知，找到具有相對應 ID 的名言，然後更新收藏狀態（學習）
    @objc func quoteUnfavorited(_ notification: Notification) {

        // 1.通知中提取名言的ID。
        // 2.找到具有該ID的名言在 quoteItems 陣列中的索引。
        // 3.確保可以正確地從 quoteItems 陣列中提取 userDetails。
        guard let quoteID = notification.object as? Int,
              let index = quoteItems.firstIndex(where: {$0.id == quoteID}),
              var userDetails = quoteItems[index].userDetails
        else {
            return
        }

        // 更新這個名言的收藏狀態
        userDetails.favorite = false                                // false 未收藏。
        quoteItems[index].userDetails = userDetails                 // 使用更新後的 userDetails 更新 quoteItems 陣列中的名言。
        let indexPath = IndexPath(row: index, section: 0)           // 計算名言在 tableView 中的位置。
        tableView.reloadRows(at: [indexPath], with: .automatic)     // 刷新對應的cell。
      }
   
    
    // MARK: - Table view data source
    /// 設定表格視圖的行數
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quoteItems.count
    }
    
    /// 為每一行的表格視圖配置單元格
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(QuoteTableViewCell.self)", for: indexPath) as? QuoteTableViewCell else {
            fatalError("The dequeued cell is not an instance of QuoteTableViewCell.")
        }
        // 設置單元格的代理和內容
        cell.delegate = self
        cell.configure(with: quoteItems[indexPath.row])
        return cell
    }
    
    /// 設置 heightForRowAt
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.size.height
    }
    
    // MARK: - API Calls
    /// 從API加載引言列表
    func loadQuotes() {
        
        // 啟動活動指示器並禁止UI互動
        startLoadingUI()
        
        // 創建API的URL（List Quotes）
        guard let url = URL(string: "https://favqs.com/api/quotes") else { return }
        // 設置API請求
        let request = createAPIRequest(with: url, httpMethod: "GET")
        
        // 在 URLSession 的回應中，當資料加載完畢或出現錯誤時，停止活動指示器
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 停止活動指示器並啟用UI互動
            DispatchQueue.main.async {
                self.stopLoadingUI()
            }
            
            if let error = error {
                print("Error fetching quotes:", error)
                return
            }
            // 解析API回應數據
            if let data = data {
                self.decodeQuotes(from: data)
            }
        }.resume()
    }
    
    /// 創建API請求
    func createAPIRequest(with url: URL, httpMethod: String) -> URLRequest {
        // 設置API請求的參數
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        let appToken = "55d03c09545078bc581705b093a7f0a2"
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
        // 從 UserDefaults 中使用鍵 "userToken" 獲取 userToken。（先前我在登入或註冊成功後將 userToken 存放到 UserDefaults）
        if let userToken = UserDefaults.standard.string(forKey: "userToken") {
            // 將其設置為請求的 header
            request.setValue(userToken, forHTTPHeaderField: "User-Token")
        } else {
            print("User Token not found!")
        }
        return request
    }
    
    /// 解析API回應數據
    func decodeQuotes(from data: Data) {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(QuotesResponse.self, from: data)
            self.quoteItems = response.quotes
            // print("Loaded quotes from API:", self.quoteItems)   // 檢查印出 API 回應的引言列表
            // 在主線程中更新UI
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error decoding response:", error)
        }
    }
    
    // MARK: - Cleanup
    // 移除所有通知觀察者，避免內存泄露
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - QuoteCellDelegate
/// 擴充 MainListOfQuotesTableViewController 以實現 QuoteCellDelegate
extension MainListOfQuotesTableViewController: QuoteCellDelegate {
    
    /// 當點擊收藏按鈕時執行的操作
    func didTapFavoriteButton(in cell: QuoteTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let selectedQuote = quoteItems[indexPath.row]
        
        // 解包 userDetails
        guard let userDetails = selectedQuote.userDetails else { return }
        
        // 切換名言的收藏狀態
        toggleFavorite(for: selectedQuote, at: indexPath)
        // 根據收藏狀態更新按鈕的圖示
        cell.updateFavoriteButtonIcon(isFavorited: userDetails.favorite)
    }
    
    /// 處理點擊朗讀引言
    func didTapReadAloudButton(in cell: QuoteTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let selectedQuote = quoteItems[indexPath.row]
        // 如果語音合成器正在說話，則停止
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            return
        }
        // 使用 AVSpeechSynthesizer 進行引言的朗讀
        let speechUtterance = AVSpeechUtterance(string: selectedQuote.body ?? "")
        speechUtterance.rate = 0.5
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.pitchMultiplier = 1.3
        speechSynthesizer.speak(speechUtterance)
    }
    
    /// 處理 收藏 / 取消收藏 的操作
    func toggleFavorite(for quote: Quote, at indexPath: IndexPath) {
        // 解包 userDetails
        guard let userDetails = quote.userDetails else { return }

        // 根據名言當前的收藏狀態來決定呼叫哪個 API endpoint（Fav Quote)
        let endpoint = userDetails.favorite ? "/api/quotes/\(quote.id)/unfav" : "/api/quotes/\(quote.id)/fav"
        guard let url = URL(string: "https://favqs.com" + endpoint) else { return }
        
        // 創建API請求
        let request = createAPIRequest(with: url, httpMethod: "PUT")
        
        // 發起API請求以切換收藏狀態
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error toggling favorite:", error)
                return
            }
            
            if let data = data {
                self.processFavoriteToggleResponse(data, for: indexPath)
            }
        }.resume()
        
    }
    
    /// 處理收藏或取消收藏後的API回應
    func processFavoriteToggleResponse(_ data: Data, for indexPath: IndexPath) {
        let decoder = JSONDecoder()
        do {
            // 解析 API 回應
            let updatedQuote = try decoder.decode(Quote.self, from: data)
            self.quoteItems[indexPath.row] = updatedQuote   // 測試
            
            // 解包 userDetails
            guard let userDetails = updatedQuote.userDetails else {
                print("UserDetails not found in the updated quote.")
                return
            }
            
            // print("Updated quote:", self.quoteItems[indexPath.row])                 // 印出更新後的引言詳細資訊（測試）
            // 根據 API 回應的名言狀態決定要顯示的訊息（測試觀察收藏、取消收藏用）
            print(userDetails.favorite ? "Quote has been added to favorites!": "Quote has been removed from favorites!")
            
            DispatchQueue.main.async {
                // 刷新表格，使更改在 UI 上生效
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                // 當添加或取消收藏時，會即時反映在 CollectQuoteTableViewController
                NotificationCenter.default.post(name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
            }
        } catch {
            print("Error decoding response:", error)
        }
    }
    
}




/*
 import UIKit
 import AVFoundation

 /// /// 主要顯示引言列表的表格視圖控制器，用於顯示引言列表。用戶可以點擊收藏引言。
 class MainListOfQuotesTableViewController: UITableViewController {
     
     // MARK: - Properties
     /// 從API取得的引言陣列
     var quoteItems: [Quote] = []
     /// 創建 AVSpeechSynthesizer 功能
     var speechSynthesizer = AVSpeechSynthesizer()
     
     // MARK: - Life Cycle
     override func viewDidLoad() {
         super.viewDidLoad()
         // 載入引言列表
         loadQuotes()
         // 註冊「取消收藏引言」的通知
         NotificationCenter.default.addObserver(self, selector: #selector(quoteUnfavorited(_:)), name: NSNotification.Name("QuoteUnfavorited"), object: nil)
         // 設置分頁效果
         tableView.isPagingEnabled = true
     }
     
     /// 設置Title（因為我 Navigation Controller 與 Tab Bar Controller 的連結，故使用此方式。（學習））
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         self.navigationItem.hidesBackButton = true  // 隱藏BarButtonItem
         self.tabBarController?.navigationItem.title = "Main List Of Quotes"
     }
     
     /// 當切換到其他畫面時，停止朗讀
     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         // 如果 AVSpeechSynthesizer 正在朗讀，則停止它
         if speechSynthesizer.isSpeaking {
             speechSynthesizer.stopSpeaking(at: .immediate)
         }
     }
     
     /// 滑動到另一個 cell 時朗讀停止
     override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         // 確認當前的單元格是否與上一次的單元格不同，如果是，則停止朗讀
         // 計算當前顯示的單元格索引
         if let visibleRows = tableView.indexPathsForVisibleRows {
             // 如果 AVSpeechSynthesizer 正在朗讀，則停止它
             if speechSynthesizer.isSpeaking {
                 speechSynthesizer.stopSpeaking(at: .immediate)
             }
         }
     }
     
     // 移除所有通知觀察者，避免內存泄露
     deinit {
         NotificationCenter.default.removeObserver(self)
     }
     
     // MARK: - Notifications
     /// 當接收到取消收藏名言的通知，找到具有相對應 ID 的名言，然後更新收藏狀態（學習）
     @objc func quoteUnfavorited(_ notification: Notification) {
         
         guard let quoteID = notification.object as? Int,
               let index = quoteItems.firstIndex(where: {$0.id == quoteID})
         else {
             return
         }
         // 更新這個名言的收藏狀態
         quoteItems[index].userDetails.favorite = false
         let indexPath = IndexPath(row: index, section: 0)
         tableView.reloadRows(at: [indexPath], with: .automatic)
     }
     
     // MARK: - Table view data source
     /// 設定表格視圖的行數
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return quoteItems.count
     }
     
     /// 為每一行的表格視圖配置單元格
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(QuoteTableViewCell.self)", for: indexPath) as? QuoteTableViewCell else {
             fatalError("The dequeued cell is not an instance of QuoteTableViewCell.")
         }
         // 設置單元格的代理和內容
         cell.delegate = self
         cell.configure(with: quoteItems[indexPath.row])
         return cell
     }
     
     /// 設置 heightForRowAt
     override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return tableView.frame.size.height
     }
     
     /// viewDidLayoutSubviews(): 是UIViewController的一部分，每當視圖的大小或位置有所改變時，這個方法都會被執行。（學習）
     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
         /// 取得 Navigation Bar 的高度以及 Tab Bar 的高度。如果沒有找到這些元件，就預設它的高度是 0。
         let barHeights = (navigationController?.navigationBar.frame.height ?? 0 ) + (tabBarController?.tabBar.frame.height ?? 0)
         // 設定 tableView 的 contentInset對表格視圖留白，確保內容不被標籤列遮擋
         // 將 bottom 的留白設為 Navigation Bar 和 Tab Bar 的高度總和，確保當滾動到最下方時，內容不會被 Tab Bar 遮住。
         tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: barHeights, right: 0)
     }
     
     // MARK: - API Calls
     /// 從API加載引言列表
     func loadQuotes() {
         // 創建API的URL（List Quotes）
         guard let url = URL(string: "https://favqs.com/api/quotes") else { return }
         // 設置API請求
         let request = createAPIRequest(with: url, httpMethod: "GET")
         
         // 開始API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Error fetching quotes:", error)
                 return
             }
             // 解析API回應數據
             if let data = data {
                 self.decodeQuotes(from: data)
             }
         }.resume()
     }
     
     /// 創建API請求
     func createAPIRequest(with url: URL, httpMethod: String) -> URLRequest {
         // 設置API請求的參數
         var request = URLRequest(url: url)
         request.httpMethod = httpMethod
         let appToken = "55d03c09545078bc581705b093a7f0a2"
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         // 從 UserDefaults 中使用鍵 "userToken" 獲取 userToken。（先前我在登入或註冊成功後將 userToken 存放到 UserDefaults）
         if let userToken = UserDefaults.standard.string(forKey: "userToken") {
             // 將其設置為請求的 header
             request.setValue(userToken, forHTTPHeaderField: "User-Token")
         } else {
             print("User Token not found!")
         }
         return request
     }
     
     /// 解析API回應數據
     func decodeQuotes(from data: Data) {
         let decoder = JSONDecoder()
         do {
             let response = try decoder.decode(QuotesResponse.self, from: data)
             self.quoteItems = response.quotes
             // print("Loaded quotes from API:", self.quoteItems)   // 檢查印出 API 回應的引言列表
             // 在主線程中更新UI
             DispatchQueue.main.async {
                 self.tableView.reloadData()
                 // 滾動到第一個單元格
 //                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true) // 測試
             }
         } catch {
             print("Error decoding response:", error)
         }
     }

 }

 // MARK: - QuoteCellDelegate

 /// 擴充 MainListOfQuotesTableViewController 以實現 QuoteCellDelegate
 extension MainListOfQuotesTableViewController: QuoteCellDelegate {
     
     /// 當點擊收藏按鈕時執行的操作
     func didTapFavoriteButton(in cell: QuoteTableViewCell) {
         guard let indexPath = tableView.indexPath(for: cell) else { return }
         let selectedQuote = quoteItems[indexPath.row]
         // 切換名言的收藏狀態
         toggleFavorite(for: selectedQuote, at: indexPath)
         // 根據收藏狀態更新按鈕的圖示
         cell.updateFavoriteButtonIcon(isFavorited: selectedQuote.userDetails.favorite)
     }
     
     /// 處理點擊朗讀引言
     func didTapReadAloudButton(in cell: QuoteTableViewCell) {
         guard let indexPath = tableView.indexPath(for: cell) else { return }
         let selectedQuote = quoteItems[indexPath.row]
         // 如果語音合成器正在說話，則停止
         if speechSynthesizer.isSpeaking {
             speechSynthesizer.stopSpeaking(at: .immediate)
             return
         }
         // 使用 AVSpeechSynthesizer 進行引言的朗讀
         let speechUtterance = AVSpeechUtterance(string: selectedQuote.body ?? "")
         speechUtterance.rate = 0.5
         speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
         speechUtterance.pitchMultiplier = 1.3
         speechSynthesizer.speak(speechUtterance)
     }
     
     /// 處理 收藏 / 取消收藏 的操作
     func toggleFavorite(for quote: Quote, at indexPath: IndexPath) {
         // 根據名言當前的收藏狀態來決定呼叫哪個 API endpoint（Fav Quote)
         let endpoint = quote.userDetails.favorite ? "/api/quotes/\(quote.id)/unfav" : "/api/quotes/\(quote.id)/fav"
         guard let url = URL(string: "https://favqs.com" + endpoint) else { return }
         
         // 創建API請求
         let request = createAPIRequest(with: url, httpMethod: "PUT")
         
         // 發起API請求以切換收藏狀態
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Error toggling favorite:", error)
                 return
             }
             
             if let data = data {
                 self.processFavoriteToggleResponse(data, for: indexPath)
             }
         }.resume()
         
     }
     
     /// 處理收藏或取消收藏後的API回應
     func processFavoriteToggleResponse(_ data: Data, for indexPath: IndexPath) {
         let decoder = JSONDecoder()
         do {
             // 解析 API 回應
             let updatedQuote = try decoder.decode(Quote.self, from: data)
             self.quoteItems[indexPath.row] = updatedQuote   // 測試
             
             // print("Updated quote:", self.quoteItems[indexPath.row])                 // 印出更新後的引言詳細資訊（測試）
             // 根據 API 回應的名言狀態決定要顯示的訊息（測試觀察收藏、取消收藏用）
             print(updatedQuote.userDetails.favorite ? "Quote has been added to favorites!": "Quote has been removed from favorites!")
             
             DispatchQueue.main.async {
                 // 刷新表格，使更改在 UI 上生效
                 self.tableView.reloadRows(at: [indexPath], with: .automatic)
                 // 當添加或取消收藏時，會即時反映在 CollectQuoteTableViewController
                 NotificationCenter.default.post(name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
             }
         } catch {
             print("Error decoding response:", error)
         }
     }
     
 }
 */








// 未整合版本
/*
 import UIKit
 import AVFoundation

 /// 主要的表格視圖，用於顯示引言列表。用戶可以點擊收藏引言。
 class MainListOfQuotesTableViewController: UITableViewController {
     
     /// 從API取得的引言陣列
     var quoteItems: [Quote] = []
     /// 創建 AVSpeechSynthesizer 實例
     var speechSynthesizer = AVSpeechSynthesizer()
     
     override func viewDidLoad() {
         super.viewDidLoad()
         // 載入引言列表
         loadQuotes()
         
         // 註冊「取消收藏名言」的通知
         NotificationCenter.default.addObserver(self, selector: #selector(quoteUnfavorited(_:)), name: NSNotification.Name("QuoteUnfavorited"), object: nil)
         
         // 設置分頁效果
         tableView.isPagingEnabled = true
     }

     // MARK: - Table view data source
     
     /// 當接收到取消收藏名言的通知，找到具有相對應 ID 的名言，然後更新收藏狀態
     @objc func quoteUnfavorited(_ notification: Notification) {
         guard let quoteID = notification.object as? Int else { return }
         // 尋找與此ID匹配的名言
         if let index = quoteItems.firstIndex(where: {$0.id == quoteID}) {
             // 更新這個名言的收藏狀態
             quoteItems[index].userDetails.favorite = false
             let indexPath = IndexPath(row: index, section: 0)
             tableView.reloadRows(at: [indexPath], with: .automatic)
         }
     }
     // 移除所有通知觀察者，避免內存泄露
     deinit {
         NotificationCenter.default.removeObserver(self)
     }
     
     /// 為 MainListOfQuotesTableViewController 單獨設置 title，並在每次視圖控制器出現時更改它。
     /// 因為我Navigation Controller 與 Tab Bar Controller 的連結，故使用此方式。（學習）
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         self.navigationItem.hidesBackButton = true  // 隱藏BarButtonItem
         self.tabBarController?.navigationItem.title = "Main List Of Quotes"
     }
     
     /// 設置 heightForRowAt
     override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return tableView.frame.size.height
     }
     
     /// viewDidLayoutSubviews(): 是UIViewController的一部分，每當視圖的大小或位置有所改變時，這個方法都會被執行。（學習）
     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
         
         // 這邊是取得 Navigation Bar 的高度以及 Tab Bar 的高度。如果沒有找到這些元件，就預設它的高度是 0。
         let barHeights = (navigationController?.navigationBar.frame.height ?? 0 ) + (tabBarController?.tabBar.frame.height ?? 0)
         
         // 設定 tableView 的 contentInset。這個屬性可以控制畫面的留白。
         // 在這邊，將 bottom 的留白設為 Navigation Bar 和 Tab Bar 的高度總和，
         // 這樣可以確保當滾動到最下方時，內容不會被 Tab Bar 遮住。
         tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: barHeights, right: 0)
     }
     
     /// 設定表格視圖的行數
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return quoteItems.count
     }
     
     /// 為每一行的表格視圖配置單元格
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(QuoteTableViewCell.self)", for: indexPath) as? QuoteTableViewCell else {
             fatalError("The dequeued cell is not an instance of QuoteTableViewCell.")
         }
         
         // 設置單元格的代理和內容
         cell.delegate = self
         cell.configure(with: quoteItems[indexPath.row])
         return cell
     }
     
     /// 從API加載引言列表
     func loadQuotes() {
         // 創建API的URL（List Quotes）
         guard let url = URL(string: "https://favqs.com/api/quotes") else { return }
         
         // 設置API請求的參數
         var request = URLRequest(url: url)
         request.httpMethod = "GET"
         let appToken = "55d03c09545078bc581705b093a7f0a2"
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         
         // 從 UserDefaults 中使用鍵 "userToken" 獲取 userToken。（先前我在登入或註冊成功後將 userToken 存放到 UserDefaults）
         if let userToken = UserDefaults.standard.string(forKey: "userToken") {
             // 如果成功，將其設置為請求的 header。
             request.setValue(userToken, forHTTPHeaderField: "User-Token")
         } else {
             print("User Token not found!")
             return
         }
         
         // 開始API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Error fetching quotes:", error)
                 return
             }
             // 解析API回應數據
             if let data = data {
                 let decoder = JSONDecoder()
                 do {
                     let response = try decoder.decode(QuotesResponse.self, from: data)
                     self.quoteItems = response.quotes
                     // print("Loaded quotes from API:", self.quoteItems)   // 檢查印出 API 回應的引言列表
                     
                     // 在主線程中更新UI
                     DispatchQueue.main.async {
                         self.tableView.reloadData()
                     }
                 } catch {
                     print("Error decoding response:", error)
                 }
             }
                 
         }.resume()
     }

 }

 /// 擴充 MainListOfQuotesTableViewController 以實現 QuoteCellDelegate
 extension MainListOfQuotesTableViewController: QuoteCellDelegate {
     
     /// 當點擊收藏按鈕時執行的操作
     func didTapFavoriteButton(in cell: QuoteTableViewCell) {
         if let indexPath = tableView.indexPath(for: cell) {
             let selectedQuote = quoteItems[indexPath.row]
             
             // 呼叫toggleFavorite 方法來處理收藏/取消收藏的操作
             toggleFavorite(for: selectedQuote, at: indexPath)
             // 更新按鈕的圖標
             cell.updateFavoriteButtonIcon(isFavorited: selectedQuote.userDetails.favorite)
         }
     }
     
     /// 處理點擊朗讀引言
     func didTapReadAloudButton(in cell: QuoteTableViewCell) {
         if let indexPath = tableView.indexPath(for: cell) {
             let selectedQuote = quoteItems[indexPath.row]
             
             // 如果已經在說話，暫停或停止朗讀
             if speechSynthesizer.isSpeaking {
                 speechSynthesizer.stopSpeaking(at: .immediate)
                 return
             }
             
             // 使用 AVSpeechSynthesizer 進行朗讀
             let speechUtterance = AVSpeechUtterance(string: selectedQuote.body ?? "")
             speechUtterance.rate = 0.5
             speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
             speechUtterance.pitchMultiplier = 1.3
             speechSynthesizer.speak(speechUtterance)
         }
     }
     
     /// 處理 收藏 / 取消收藏 的操作
     func toggleFavorite(for quote: Quote, at indexPath: IndexPath) {
         // 根據名言當前的收藏狀態來決定呼叫哪個 API endpoint（Fav Quote)
         let endpoint: String
         if quote.userDetails.favorite {
             endpoint = "/api/quotes/\(quote.id)/unfav"
         } else {
             endpoint = "/api/quotes/\(quote.id)/fav"
         }
         
         guard let url = URL(string: "https://favqs.com" + endpoint) else { return }
         
         // 設置API請求的參數
         var request = URLRequest(url: url)
         request.httpMethod = "PUT"
         let appToken = "55d03c09545078bc581705b093a7f0a2"
         request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
         
         if let userToken = UserDefaults.standard.string(forKey: "userToken") {
             request.setValue(userToken, forHTTPHeaderField: "User-Token")
         } else {
             print("User Token not found!")
             return
         }
         
         // 發起API請求
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Error toggling favorite:", error)
                 return
             }
             
             if let data = data {
                 let decoder = JSONDecoder()
                 do {
                     // 解析 API 回應
                     let updatedQuote = try decoder.decode(Quote.self, from: data)
                     // 更新名言列表中的收藏狀態
                     self.quoteItems[indexPath.row] = updatedQuote
                     
                     // print("Updated quote:", self.quoteItems[indexPath.row])                 // 印出更新後的引言詳細資訊（測試）
                     // 根據 API 回應的名言狀態決定要顯示的訊息（測試觀察收藏、取消收藏用）
                     if updatedQuote.userDetails.favorite {
                         print("Quote has been added to favorites!")
                     } else {
                         print("Quote has been removed from favorites!")
                     }
                     
                     // 刷新表格，使更改在 UI 上生效
                     DispatchQueue.main.async {
                         self.tableView.reloadRows(at: [indexPath], with: .automatic)
                         // 當添加或取消收藏時，會即時反映在 CollectQuoteTableViewController
                         NotificationCenter.default.post(name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
                     }
                 } catch {
                     print("Error decoding response:", error)
                 }
             }
             
         }.resume()
         
     }
 }
 */





