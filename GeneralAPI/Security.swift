//
//  Security.swift
//  GeneralAPI
//
//  Created by 王义川 on 15/7/15.
//  Copyright © 2015年 肇庆市创威发展有限公司. All rights reserved.
//

import Foundation

public protocol IfConfidential {
    static func isConfidential() -> Bool
}

public protocol Confidential: IfConfidential {
}

extension Confidential {
    public static func isConfidential() -> Bool {
        return true
    }
}

extension Optional: IfConfidential {
    public static func isConfidential() -> Bool {
        if let valueType = Wrapped.self as? IfConfidential.Type {
            return valueType.isConfidential()
        } else {
            return false
        }
    }
}

public protocol Cipher {
    func encrypt(data: NSData) throws -> NSData
    func decrypt(data: NSData) throws -> NSData
}

public protocol Authenticator {
    func authenticate(request: NSURLRequest) throws -> NSData
    func authenticate(response: (URLResponse: NSHTTPURLResponse, responseData: NSData?), request: NSURLRequest) throws -> NSData
}