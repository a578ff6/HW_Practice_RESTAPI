//
//  ListQuoteModels.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/1.
//

import Foundation

// List QuotesAPI、Get the public quotes favorited by user API、Get Quote API、Fav Quote API

/// API回應的主結構
struct QuotesResponse: Codable {
    /// 目前的頁碼
    let page: Int
    /// 是否是最後一頁
    let lastPage: Bool
    /// 包含多個引言陣列
    let quotes: [Quote]
    
    enum CodingKeys: String, CodingKey {
        case page
        case lastPage = "last_page"
        case quotes
    }
}

/// 代表單一引言
struct Quote: Codable {
    /// 引言的唯一 id
    let id: Int
    /// 這個引言是否是對話
    let dialogue: Bool
    /// 表示這個引言是否是私人的
//    let `private`: Bool
    /// 與這句引言相關的標籤
    let tags: [String]
    /// 這句引言在網站上的URL
    let url: URL?
    /// 這句引言的收藏數
    let favoritesCount: Int
    /// 這句引言的點讚數
    let upvotesCount: Int?
    /// 這句引言的倒讚數
    let downvotesCount: Int?
    /// 引言的作者
    let author: String?
    /// 引言的內容
    let body: String?
    /// 關於當前用戶與該引言互動的詳細資訊
    var userDetails: UserDetails?        // 為了能夠修改 favorite 的時候，更新收藏狀態，因此將 userDetails 和 favorite 屬性都標記為 var
    
    enum CodingKeys: String, CodingKey {
        case id, dialogue, tags, url, author, body
        case favoritesCount = "favorites_count"
        case upvotesCount = "upvotes_count"
        case downvotesCount = "downvotes_count"
        case userDetails = "user_details"
    }
}

/// 用於描述用戶與一句引言的互動
struct UserDetails: Codable {
    /// 用戶是否將這句引言加入收藏
    var favorite: Bool          // var
    /// 用戶是否為這句引言點贊
    let upvote: Bool
}

/// 解析錯誤
struct QuoteErrorResponse: Codable {
    // 伺服器回傳的錯誤代碼
    let errorCode: Int
    // 伺服器回傳的錯誤消息
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case message
    }
}
