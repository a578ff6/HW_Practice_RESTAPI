//
//  QuoteTableViewCell.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/2.
//

/*
 在 QuoteTableViewCell 中定義了一個 delegate 屬性和兩個按鈕的 IBAction。
 當按鈕被點擊時，QuoteTableViewCell 通知其代理。
 在 MainListOfQuotesTableViewController 中，設置了每個 cell 的代理為自己，藉此實現 QuoteCellDelegate 協議。
 */

import UIKit

/// 用於顯示引言的客製化 cell。
class QuoteTableViewCell: UITableViewCell {
    /// 顯示引言內容
    @IBOutlet weak var quoteBodyLabel: UILabel!
    /// 顯示引言作者的
    @IBOutlet weak var authorLabel: UILabel!
    /// 收藏引言的按鈕
    @IBOutlet weak var addToFavoritesButton: UIButton!
    /// 朗讀引言的按鈕
    @IBOutlet weak var readAloudButton: UIButton!
    
    /// 代理（delegate）屬性，用於在按鈕被點擊時通知代理
    weak var delegate: QuoteCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// 當收藏按鈕被點擊，通知代理
    @IBAction func addToFavoritesButtonTapped(_ sender: UIButton) {
        delegate?.didTapFavoriteButton(in: self)
        
    }
    
    /// 當朗讀按鈕被點擊，通知代理
    @IBAction func readAloudButtonTapped(_ sender: UIButton) {
        delegate?.didTapReadAloudButton(in: self)
    }
    
    /// 設定cell內容。
     /// - Parameter quote: 用於設定單元格的引言
    func configure(with quote: Quote) {
        // 設置引言作者
        quoteBodyLabel.text = quote.body ?? "No Cotent"
        // 設置引言作者
        authorLabel.text = quote.author ?? "Unknown"
        
        // 解包 userDetails
        if let userDetails = quote.userDetails {
            // 更新收藏按鈕的圖示
            updateFavoriteButtonIcon(isFavorited: userDetails.favorite)
        } else {
            // 打印一條消息，告知 userDetails 為 nil
            print("UserDetails not found in the provided quote.")

        }
        // 更新收藏按鈕的圖示
    }
    
    /*
     func configure(with quote: Quote) {
         // 設置引言作者
         quoteBodyLabel.text = quote.body ?? "No Content"
         // 設置引言作者
         authorLabel.text = quote.author ?? "Unknown"
         
         // 安全地解包 userDetails
         if let userDetails = quote.userDetails {
             // 更新收藏按鈕的圖示
             updateFavoriteButtonIcon(isFavorited: userDetails.favorite)
         } else {
             // 這裡你可以設置默認的按鈕狀態，或者打印一條消息，告知 userDetails 為 nil
             print("UserDetails not found in the provided quote.")
         }
     }

     */
    
    /// 根據是否被收藏的狀態，更新收藏按鈕的圖示。
    ///  - Parameters: Bool藉此更新按鈕圖示
    func updateFavoriteButtonIcon(isFavorited: Bool) {
        if isFavorited {
            addToFavoritesButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            addToFavoritesButton.setImage(UIImage(systemName: "heart"), for: .normal)
        }
    }

}

/// 使用代理模式 (delegate pattern)
/// 引言 cell 的代理協議，用於處理按鈕的點擊事件。
protocol QuoteCellDelegate: AnyObject {
    /// 當收藏按鈕被點擊時呼叫此方法
    func didTapFavoriteButton(in cell: QuoteTableViewCell)
    /// 當朗讀按鈕被點擊時呼叫此方法
    func didTapReadAloudButton(in cell: QuoteTableViewCell)
}

