//
//  CollectQuotesTableViewCell.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/2.
//

import UIKit

/// 顯示 CollectQuoteTableViewController 的客製化表格
class CollectQuotesTableViewCell: UITableViewCell {

    /// 收藏的引言文字內容
    @IBOutlet weak var collectQuoteBodyLabel: UILabel!
    /// 收藏的引言作者
    @IBOutlet weak var collecAutherLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with quote: Quote) {
        collectQuoteBodyLabel.text = quote.body ?? "No Cotent"
        collecAutherLabel.text = quote.author ?? "Unknown"
    }

}
