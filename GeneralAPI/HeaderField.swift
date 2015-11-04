//
//  HeaderField.swift
//  GeneralAPI
//
//  Created by 王义川 on 15/7/15.
//  Copyright © 2015年 肇庆市创威发展有限公司. All rights reserved.
//

import Foundation

public enum HeaderField: String {
    case APIVersion = "CW-APIVersion"
    case BusinessVersion = "CW-BusinessVersion"
    case SessionLifetime = "CW-SessionLifetime"
    case Signature = "CW-Signature"
}

extension NSURLRequest {
    public subscript(headerField: HeaderField) -> String? {
        return allHTTPHeaderFields?[headerField.rawValue]
    }
}

extension NSHTTPURLResponse {
    public subscript(headerField: HeaderField) -> String? {
        return allHeaderFields[headerField.rawValue] as? String
    }
    
    public var sessionLifetime: NSTimeInterval? {
        guard let value = self[.SessionLifetime] else {
            return nil
        }
        return (value as NSString).doubleValue
    }
}

extension NSMutableURLRequest {
    public func setValue(value: String?, forHeaderField field: HeaderField) {
        if let fieldValue = value {
            setValue(fieldValue, forHTTPHeaderField: field.rawValue)
        }
    }
}