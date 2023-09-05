//
//  CreatUserModels.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/8/31.
//

import Foundation

/// 代表創建用戶的RequestBody
struct CreatUserRequestBody: Codable {
    /// 要創建的用戶的資料
    let user: CreateUser
}

/// 包含要創建的用戶的所有必要資訊
struct CreateUser: Codable {
    /// 用戶的登入名稱
    let login: String
    /// 用戶的電子郵件地址
    let email: String
    /// 用戶的密碼
    let password: String
}

/// 代表創建用戶後的ResponseBody
struct CreatUserResponseBody: Codable {
    /// userToken 用於進一步的認證和授權
    let userToken: String
    /// 創建的用戶的登入名稱
    let login: String
    
    enum CodingKeys: String, CodingKey {
        case userToken = "User-Token"
        case login
    }
}

/// 代表在創建用戶時可能出現的錯誤的Response（此時status為200）
struct CreatUserErrorResponse: Codable {
    /// 錯誤的代碼
    let errorCode: Int
    /// 錯誤的描述訊息
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case message
    }
}

