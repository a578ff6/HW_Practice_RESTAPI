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

/// 代表一個用於顯示引言的客製化的 cell。
class QuoteTableViewCell: UITableViewCell {

    @IBOutlet weak var quoteBodyLabel: UILabel!     // 顯示引言內容的標籤
    @IBOutlet weak var authorLabel: UILabel!        // 顯示引言作者的標籤
    @IBOutlet weak var addToFavoritesButton: UIButton!  // 收藏引言的按鈕
    @IBOutlet weak var readAloudButton: UIButton!       // 朗讀引言的按鈕
    
    // 委託 (delegate) 屬性，用於通知代理當按鈕被點擊
    weak var delegate: QuoteCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    /// 當收藏按鈕被點擊時，通知代理
    @IBAction func addToFavoritesButtonTapped(_ sender: UIButton) {
        delegate?.didTapFavoriteButton(in: self)
        
    }
    
    /// 當朗讀按鈕被點擊時，通知代理
    @IBAction func readAloudButtonTapped(_ sender: UIButton) {
        delegate?.didTapReadAloudButton(in: self)
    }
    
    /// 根據提供的引言數據配置 cell
    func configure(with quote: Quote) {
        quoteBodyLabel.text = quote.body ?? "No Cotent"       // 設置引言內容
        
        // 如果 author 是 nil，則將其設置為 "Unknown"
        authorLabel.text = quote.author ?? "Unknown"       // 設置引言作者
        
        updateFavoriteButtonIcon(isFavorited: quote.userDetails.favorite)   // 更新收藏按鈕的圖標
    }
    
    /// 根據是否被收藏的狀態，更新收藏按鈕的圖標 （在 configure(with:) 方法中，調用）
    func updateFavoriteButtonIcon(isFavorited: Bool) {
        if isFavorited {
            addToFavoritesButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            addToFavoritesButton.setImage(UIImage(systemName: "heart"), for: .normal)
        }
    }

}

/// 使用委託模式 (delegate pattern)
/// 引言 cell 的代理協議，用於響應按鈕的點擊事件
protocol QuoteCellDelegate: AnyObject {
    /// 當收藏按鈕被點擊時呼叫此方法
    func didTapFavoriteButton(in cell: QuoteTableViewCell)
    /// 當朗讀按鈕被點擊時呼叫此方法
    func didTapReadAloudButton(in cell: QuoteTableViewCell)
}

