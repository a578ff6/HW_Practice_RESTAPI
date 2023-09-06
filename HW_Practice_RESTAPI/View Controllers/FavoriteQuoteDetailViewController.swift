//
//  FavoriteQuoteDetailViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/4.


import UIKit
import AVFoundation

/// 當從CollectQuoteTableViewController點擊收藏的引言時，可以進入詳細內容頁面
class FavoriteQuoteDetailViewController: UIViewController {
    
    // MARK: - Properties
    /// 顯示作者
    @IBOutlet weak var quoteAuthorDetailLabel: UILabel!
    /// 顯示引言
    @IBOutlet weak var quoteBodyDetailLabel: UILabel!
    /// 存放已收藏的引言
    var quote: Quote?
    /// 建立AVSpeechSynthesizer
    var speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // 透過id顯示引言內容
        loadQuoteDetail(quoteID: quote?.id ?? 0)
    }
    
    // 當離開 FavoriteQuoteDetailViewController 時停止朗讀
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 如果speechSynthesizer正在說話，則停止它
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - User Actions
    /// 點擊按鈕朗讀引言
    @IBAction func speakQuoteButtonTapped(_ sender: UIButton) {
        // 檢查是否有引言可供語音
        guard let quoteText = quoteBodyDetailLabel.text else { return }
        
        // 如果已經在說話，暫停或停止朗讀
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            return
        }
        
        // 初始化語音合成器和語音合成輸入
        let speechUtterance = AVSpeechUtterance(string: quoteText)
        speechUtterance.rate = 0.4
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.pitchMultiplier = 1.2
        speechSynthesizer.speak(speechUtterance)
    }
    
    /// 分享引言按鈕
    @IBAction func shareQuoteButtonTapped(_ sender: UIButton) {
        // 如果speechSynthesizer正在說話，則停止它
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        // 確保有引言可以分享
        guard let quoteText = quoteBodyDetailLabel.text,
                let author = quoteAuthorDetailLabel.text else { return }
        
        // 創建分享內容
        let shareContent = "\(quoteText) - \(author)"
        // 初始化 UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: [shareContent], applicationActivities: nil)
        // 顯示分享視窗
        present(activityViewController, animated: true)
    }
    
    // MARK: - API Calls
    /// 顯示選取的引言內容
    func loadQuoteDetail(quoteID: Int) {
        guard let url = URL(string: "https://favqs.com/api/quotes/\(quoteID)") else {
            print("Invalid URL!")
            return
        }
        /// 建立請求
        var request = createAPIRequest(with: url, httpMethod: "GET")
        // 使用 URLSession 發起 API 請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching quote:", error)
                 return
            }
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    let quoteDetail = try decoder.decode(Quote.self, from: data)
                    // 請求成功則顯示作者、內容
                    DispatchQueue.main.async {
                        self.quoteAuthorDetailLabel.text = quoteDetail.author
                        self.quoteBodyDetailLabel.text = quoteDetail.body
                    }
                } catch {
                    print("Error decoding response:", error)
                }
            }
        }.resume()
    }
    
    /// 建立請求
    func createAPIRequest(with url: URL, httpMethod: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        let appToken = "55d03c09545078bc581705b093a7f0a2"
        request.setValue("Token token=\(appToken)", forHTTPHeaderField: "Authorization")

        if let userToken = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue(userToken, forHTTPHeaderField: "User-Token")
        } else {
            print("User Token not found!")
        }
        return request
    }
    
}
