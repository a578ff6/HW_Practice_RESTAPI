//
//  MainListOfQuotesTableViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/8/31.
//



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













