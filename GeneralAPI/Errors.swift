//
//  Errors.swift
//  GeneralAPI
//
//  Created by 王义川 on 15/7/15.
//  Copyright © 2015年 肇庆市创威发展有限公司. All rights reserved.
//

import Foundation


public enum Error: ErrorType {
    case EncryptFailure
    case DecryptFailure
    case AuthenticateFailure
    case NoServerTime
    case NoSessionLifetime
    case SessionNotCreated
    case MissingResponseSignature
    case ResponseSignatureInvalid
}