//
//  GeneralManager.swift
//  GeneralAPI
//
//  Created by 王义川 on 15/7/15.
//  Copyright © 2015年 肇庆市创威发展有限公司. All rights reserved.
//

import Foundation
import API


public class Manager<T, U>: API.Manager<T, U>, ManagerType {
    public typealias AuthenticatorProvider = (ParametersType) throws -> Authenticator
    
    public var APIVersion: String? = nil
    public var businessVersion: String? = nil
    
    private let authenticatorProvider: AuthenticatorProvider?
    
    public init(URL: NSURL, authenticatorProvider provider: AuthenticatorProvider? = nil) {
        self.authenticatorProvider = provider
        
        super.init(URL: URL)
    }
    
    public init(URL: NSURL, method: API.Method, authenticatorProvider provider: AuthenticatorProvider? = nil) {
        self.authenticatorProvider = provider
        
        super.init(URL: URL, method: method)
    }
    
    public override func request(parameters: ParametersType, var serializer: RequestType.Serializer, var deserializer: RequestType.Deserializer) -> RequestType {
        if let type = ParametersType.self as? IfConfidential.Type {
            if type.isConfidential() {
                serializer = confidentialSerializer(serializer)
            }
        }
        if let type = ResultType.self as? IfConfidential.Type {
            if type.isConfidential() {
                deserializer = confidentialDeserializer(deserializer)
            }
        }
        return super.request(parameters, serializer: serializer, deserializer: deserializer)
            .process{ [unowned self] request in
                request.setValue(self.APIVersion, forHeaderField: .APIVersion)
                request.setValue(self.businessVersion, forHeaderField: .BusinessVersion)
            }
            .process(priority: .VeryLow) { [unowned self] request in
                if  let authenticator = try self.authenticatorProvider?(parameters) {
                    let signature: NSData = try authenticator.authenticate(request)
                    let signatureString = signature.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
                    request.setValue(signatureString, forHeaderField: .Signature)
                }
            }
            .validate{ [unowned self] parameters, request, response, responseData in
                if  let authenticator = try self.authenticatorProvider?(parameters) {
                    guard let responseSignatureString = response[.Signature] else {
                        throw Error.MissingResponseSignature
                    }
                    
                    let signature = try authenticator.authenticate((response, responseData), request: request)
                    let signatureString = signature.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
                    if responseSignatureString != signatureString {
                        throw Error.ResponseSignatureInvalid
                    }
                }
                
                if response.serverTime == nil {
                    throw Error.NoServerTime
                }
                
                if  response.sessionLifetime == nil {
                    throw Error.NoSessionLifetime
                }
            }
            .response{ (_, request, response, responseData, _, error) -> Void in
                if let sessionLifetime = response?.sessionLifetime {
                    Session.updateSessionExpiredTime(NSDate(timeIntervalSinceNow: sessionLifetime))
                }
                
                switch error {
                case .Some(Error.MissingResponseSignature):
                    Session.clearCurrentSession()
                default: break
                }
            }
    }
    
    private func confidentialSerializer(serializer: RequestType.Serializer) -> RequestType.Serializer {
        return { parameters in
            if let data = try serializer(parameters) {
                guard let session = Session.currentSession else {
                    throw Error.SessionNotCreated
                }
                
                return try session.cipher.encrypt(data)
            } else {
                return nil
            }
        }
    }
    
    private func confidentialDeserializer(deserializer: RequestType.Deserializer) -> RequestType.Deserializer {
        return { parameters, request, response, responseData in
            if var data = responseData {
                guard let session = Session.currentSession else {
                    throw Error.SessionNotCreated
                }
                
                data = try session.cipher.decrypt(data)
                return try deserializer(parameters, request, response, data)
            } else {
                return try deserializer(parameters, request, response, responseData)
            }
        }
    }
}

public protocol ManagerType: API.ManagerType {
    func request(parameters: ParametersType, serializer: Request<ParametersType, ResultType>.Serializer, reformer: (ResultCode, String?, AnyObject?) throws -> ResultType) -> Request<ParametersType, ResultType>
}

extension ManagerType {
    public func request(parameters: ParametersType, serializer: Request<ParametersType, ResultType>.Serializer, reformer: (ResultCode, String?, AnyObject?) throws -> ResultType) -> Request<ParametersType, ResultType> {
        return request(parameters, serializer: serializer, deserializer: Self.deserializer(reformer))
    }
    
    private static func deserializer(reformer: (ResultCode, String?, AnyObject?) throws -> ResultType) -> Request<ParametersType, ResultType>.Deserializer {
        return { _, _, _, responseData in
            guard let data = responseData else {
                throw API.Error.DeserializeFailure("The response data is nil.")
            }
            
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
            guard let obj = json as? [String: AnyObject] else {
                throw API.Error.DeserializeFailure("The response json format is incorrect.")
            }
            
            guard let resultCode = obj["resultCode"] as? Int else {
                throw API.Error.DeserializeFailure("`resultCode` invalid.")
            }
            
            let message: String?
            if let value = obj["message"] {
                guard let msg = value as? String else {
                    throw API.Error.DeserializeFailure("`message` invalid.")
                }
                message = msg
            } else {
                message = nil
            }
            
            let body = obj["body"]
            
            return try reformer(ResultCode(resultCode), message, body)
        }
    }
}

extension ManagerType where ParametersType == Void {
    public func request(reformer reformer: (ResultCode, String?, AnyObject?) throws -> ResultType) -> Request<Void, ResultType> {
        return request((), serializer: Self.serialize, reformer: reformer)
    }
}