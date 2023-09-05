//
//  GetUserModels.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/3.
//

import Foundation

// 取得特定使用者詳細資訊（從 https://favqs.com/api/users/:login 獲得）
struct GetUser: Codable {
    /// 使用者的登錄名稱或ID。
    let login: String?
    /// 使用者的頭像URL。
//    let picUrl: URL
    /// 使用者的公開收藏數。
    let publicFavoritesCount: Int
    /// 該使用者正在關注的人數。
    let following: Int
    /// 關注該使用者的人數。
    let followers: Int
    /// 使用者是否是Pro會員。
    let pro: Bool?             // 將 pro 屬性設置為 Bool?，因為JSON中的值是 null
    /// 使用者的帳戶詳細資訊。
    let accountDetails: AccountDetails
    
    enum CodingKeys: String, CodingKey {
        case login
//        case picUrl = "pic_url"
        case publicFavoritesCount = "public_favorites_count"
        case following
        case followers
        case pro
        case accountDetails = "account_details"
    }
}

/// 使用者帳戶的詳細資訊。
struct AccountDetails: Codable {
    /// 使用者的電子郵件地址。
    let email: String
}
