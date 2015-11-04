//
//  ResultCode.swift
//  GeneralAPI
//
//  Created by 王义川 on 15/8/10.
//  Copyright © 2015年 肇庆市创威发展有限公司. All rights reserved.
//

import Foundation


public struct ResultCode: RawRepresentable {
    public typealias RawValue = Int
    
    private let value: Int
    
    public init(_ value: Int) {
        self.value = value
    }

    public init?(rawValue: Int) {
        self.value = rawValue
    }
    
    public var rawValue: Int { return value }
}

public func ~= (left: ResultCode, right: ResultCode) -> Bool {
    return left.rawValue ~= right.rawValue
}

public func == (left: ResultCode, right: ResultCode) -> Bool {
    return left.rawValue == right.rawValue
}