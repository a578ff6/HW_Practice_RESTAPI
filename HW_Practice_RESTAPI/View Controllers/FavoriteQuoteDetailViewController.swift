//
//  FavoriteQuoteDetailViewController.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/4.
//

import UIKit
import AVFoundation

/// 當從CollectQuoteTableViewController點擊收藏的引言時，可以進入詳細內容頁面
class FavoriteQuoteDetailViewController: UIViewController {
    
    @IBOutlet weak var quoteAuthorDetailLabel: UILabel!
    
    @IBOutlet weak var quoteBodyDetailLabel: UILabel!
    
    var quote: Quote?
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadQuoteDetail(quoteID: quote?.id ?? 0)
    }

    /// 朗讀引言
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
    
    /// 分享引言
    @IBAction func shareQuoteButtonTapped(_ sender: UIButton) {
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
    
    
    func loadQuoteDetail(quoteID: Int) {
        guard let url = URL(string: "https://favqs.com/api/quotes/\(quoteID)") else {
            print("Invalid URL!")
            return
        }
        
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching quote:", error)
                 return
            }
            
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    let quoteDetail = try decoder.decode(Quote.self, from: data)
                    
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
    
    
}
