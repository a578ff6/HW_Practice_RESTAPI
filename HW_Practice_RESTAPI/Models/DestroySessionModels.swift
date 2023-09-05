//
//  DestroySessionModels.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/5.
//

import Foundation

// 用於解析登出成功後的 Response
struct LogoutResponse: Codable {
    // 登出成功時伺服器回傳的消息
    let message: String
}

// 用於解析登出時可能出現的ErrorResponse（目前用不到）
struct LogoutErrorResponse: Codable {
    // 伺服器回傳的錯誤代碼
    let errorCode: Int
    // 伺服器回傳的錯誤消息
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case message
    }
}
