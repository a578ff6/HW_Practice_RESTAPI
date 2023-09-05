//
//  CollectQuoteTableViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/1.
//

import UIKit

/// 負責顯示和管理已收藏的引言
class CollectQuoteTableViewController: UITableViewController {
    
    /// 存放已收藏的引言
    var collectedQuotes: [Quote] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化：加載已收藏的引言列表
        loadCollectedQuotes()
        
        // 註冊通知，當在 MainListOfQuotesTableViewController 收藏或取消收藏名言時，即時更新此頁面的收藏名言列表。
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectedQuotes), name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
    }
    
    /// 當名言的收藏狀態發生變化時，重新加載已收藏的名言列表
    @objc func reloadCollectedQuotes() {
        loadCollectedQuotes()
    }
    /// 在控制器被銷毀時移除通知觀察者，以避免任何可能的內存泄漏
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Table view data source

    /// 為 CollectQuoteTableViewController 單獨設置 title，並在每次視圖控制器出現時更改它。
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "Favorite Quotes"
    }
    
    /// 設定表格視圖的行數
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectedQuotes.count
    }
    
    /// 為每一行的表格視圖配置單元格
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 從 tableView 中取得一個可重用的單元格
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(CollectQuotesTableViewCell.self)", for: indexPath) as? CollectQuotesTableViewCell else {
            fatalError("The dequeued cell is not an instance of CollectQuotesTableViewCell.")
        }
        
        // 使用索引路徑來取得對應的引言
        let quote = collectedQuotes[indexPath.row]
        // 用此引言來配置單元格
        cell.configure(with: quote)
        return cell
    }
    
    /// 確保在進入FavoriteQuoteDetailViewController之前，將選定的引言傳遞給它。（測試）
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQuoteDetail",
           let destinationVC = segue.destination as? FavoriteQuoteDetailViewController,
           let selectedIndex = tableView.indexPathForSelectedRow {
            let selectedQuote = collectedQuotes[selectedIndex.row]
            destinationVC.quote = selectedQuote
        }
    }
    
    
    /// 處理表格視圖中的單元格滑動刪除操作。（當使用者在已收藏的名言上滑動並選擇刪除會觸發）
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // 檢查是否是刪除操作
        if editingStyle == .delete {
            // 從當前索引路徑取得要取消收藏的名言
            let quoteToUnfavorive = collectedQuotes[indexPath.row]
            
            // 呼叫 unfavoriteQuote 方法通過API取消收藏該名言
            unfavoriteQuote(quote: quoteToUnfavorive) { success in
                if success {
                    DispatchQueue.main.async {
                        // 成功取消收藏（從本地數據和視圖中移除該名言）
                        self.collectedQuotes.remove(at: indexPath.row)
                        // 從表格視圖中刪除該名言的行
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        // 發送通知告 MainListOfQuotesTableViewController 這個名言已被取消收藏（根據id）
                        NotificationCenter.default.post(name: NSNotification.Name("QuoteUnfavorited"), object: quoteToUnfavorive.id)
                        // 這裡也發送 QuoteFavoritedStatusChanged 通知，以更新 UserProfileViewController的favoritesCountLabel
                        NotificationCenter.default.post(name: NSNotification.Name("QuoteFavoritedStatusChanged"), object: nil)
                    }
                } else {
                    print("Failed to unfavorite quote.")
                }
            }
            
        }

    }
    
    /*
     unfavoriteQuote 函數會建立一個API請求到 favqs.com 來取消收藏指定的引言。完成後，根據HTTP回應的狀態碼來決定是否成功，並通過回調函數 completion 傳遞結果。
     如果HTTP狀態碼為200，則認為操作成功，可以將此函數添加到 CollectQuoteTableViewController 中，並在需要取消收藏引言時調用它。
     */
    
    /// 使用API取消收藏指定的引言。
    /// - Parameters:
    ///   - quote: 想取消收藏的引言。
    ///   - completion: 完成後的回調，返回一個Bool表示操作是否成功。
    func unfavoriteQuote(quote: Quote, completion: @escaping(Bool) -> Void) {
        
        // 定義API的endpoint，用於取消收藏指定ID的引言。（Fav Quote）
        let endpoint = "/api/quotes/\(quote.id)/unfav"
        
        // 建立URL（To unmark a quote as a user's favorite）
        guard let url = URL(string: "https://favqs.com" + endpoint) else {
            completion(false)    // 如果URL無效，回調返回失敗。
            return
        }
        
        // 創建一個URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let appToken = "55d03c09545078bc581705b093a7f0a2"
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
        
        // 從UserDefaults中獲取用戶的Token，並設置為請求的header。
        if let userToken = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue(userToken, forHTTPHeaderField: "User-Token")
        } else {
            print("User Token not found!")
            completion(false)            // 如果找不到用戶Token，回調返回失敗。
            return
        }
        
        // 發起API請求。
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error unfavorite the quote:", error)
                completion(false)
                return
            }
            
            // 檢查HTTP回應的狀態碼。如果狀態碼為200，表示操作成功。
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
            
        }.resume()
        
    }
    
    /// 透過 API 請求，載入使用者已收藏的名言列表。
    func loadCollectedQuotes() {
        
        // 從 UserDefaults 中獲取用戶名（藉此取得使用者的收藏列表API）
        // userLogin 就是使用者的個人id（用來抓取該使用者）
        guard let userLogin = UserDefaults.standard.string(forKey: "userLogin") else {
            print("User Login not found!")
            return
        }
        
        // 這裡的 endpoint 是根據 API 決定的，使用用戶名來構建URL
        guard let url = URL(string: "https://favqs.com/api/quotes/?filter=\(userLogin)&type=user") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let appToken = "55d03c09545078bc581705b093a7f0a2"
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")
        
        if let userToken = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue(userToken, forHTTPHeaderField: "User-Token")
        } else {
            print("User Token not found!")
            return
        }
        
        // 使用 URLSession 發起 API 請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching collected quotes:", error)
                return
            }
            
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    // 解析 API 回應的 JSON 數據
                    let response = try decoder.decode(QuotesResponse.self, from: data)
                    // 更新本地的 collectedQuotes 列表
                    self.collectedQuotes = response.quotes
                    // 主線程中更新 tableView，顯示最新的名言列表
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


