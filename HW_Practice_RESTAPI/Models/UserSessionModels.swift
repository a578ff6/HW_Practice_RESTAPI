//
//  UserSessionModels.swift
//  HW_Practice_RESTAPI
//
//  Created by 曹家瑋 on 2023/9/1.
//

import Foundation

/// 用於封裝發送到登錄API的RequestBody
struct UserRequestBody: Codable {
    /// 包含用戶的登錄名和密碼
    let user: UserSession
}

/// 用戶的登錄資訊，包括用戶名和密碼。
struct UserSession: Codable {
    /// 用戶的登錄名稱或email，根據API的需求，這兩者都可以使用
    let login: String
    /// 用戶的密碼
    let password: String
}

/// 當用戶成功登錄後，用於解析API返回的ResponseBody
struct UserResponseBody: Codable {
    /// 用於之後API請求認證用戶的Token
    let userToken: String
    /// 用戶的登錄名稱
    let login: String
    /// 用戶的email
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case userToken = "User-Token"
        case login
        case email
    }
}

/// 當登錄請求失敗時，用於解析API返回的ErrorResponse（此時status為200）
struct UserSeeionErrorResponse: Codable {
    /// 錯誤碼
    let errorCode: Int
    /// 描述錯誤的訊息
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case message
    }
}


/*
 ERRORS
 An invalid login or password will return an error:

 {
   "error_code": 21,
   "message": "Invalid login or password."
 }
 An account that has been deactivated will return an error:

 {
   "error_code": 22,
   "message": "Login is not active. Contact support@favqs.com."
 }
 A request with missing data will return an error:

 {
   "error_code": 23,
   "message": "User login or password is missing."
 }
 */
