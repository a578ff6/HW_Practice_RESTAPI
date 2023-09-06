//
//  CollectQuotesTableViewCell.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/2.
//

import UIKit


/// 用於顯示 `CollectQuoteTableViewController` 中的客製化 cell
class CollectQuotesTableViewCell: UITableViewCell {

    /// 顯示收藏引言的文字內容
    @IBOutlet weak var collectQuoteBodyLabel: UILabel!
    /// 顯示收藏引言的作者名稱
    @IBOutlet weak var collecAutherLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// 設定cell內容。
     /// - Parameter quote: 用於設定單元格的引言。
    func configure(with quote: Quote) {
        // 設置引言作者
        collectQuoteBodyLabel.text = quote.body ?? "No Cotent"
        // 設置引言作者
        collecAutherLabel.text = quote.author ?? "Unknown"
    }

}
