//
//  ASN1Object+ValueReading.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 24/06/2019.
//  Copyright © 2019 Pavel Tikhonenko. All rights reserved.
//

import Foundation

//Value Data Types we expect from ASN1
protocol ASN1ExtractableValueTypes {}

extension ASN1Object: ASN1ExtractableValueTypes { }
extension Bool: ASN1ExtractableValueTypes { }
extension Data: ASN1ExtractableValueTypes { }
extension String: ASN1ExtractableValueTypes { }
extension Date: ASN1ExtractableValueTypes { }
extension Int: ASN1ExtractableValueTypes { }

extension ASN1Object
{
    var valueData: Data?
    {
        let l = length.value
        
        if l == 0 { return nil }
        
        let valueOffset = 1 + length.offset //Identifier + length
        return Data(rawData[valueOffset..<(l + valueOffset)])
    }
    
    static func asn1ReadUTF8String(from data: inout Data, _ l: Int) -> String?
    {
        return readString(from: &data, l, encoding: .utf8)
    }
    
    static func asn1ReadASCIIString(from data: inout Data, _ l: Int) -> String?
    {
        return readString(from: &data, l, encoding: .ascii)
    }
    
    static func readString(from data: inout Data, _ l: Int, encoding: String.Encoding) -> String
    {
        return String(data: data, encoding: encoding) ?? ""
    }
    
    static func readInt(from data: inout Data, offset: Int = 0, l: Int) -> Int
    {
        var r: UInt64 = 0
        
        let start = data.startIndex + offset
        let end = start + l
        
        for i in start..<end
        {
            r = r << 8
            r |= UInt64(data[i])
        }
        
        if r >= Int.max
        {
            return -1 //Invalid data
        }
        
        return Int(r)
    }
    
    func extractValue() -> Any?
    {
        return value()
    }
    
    fileprivate func value() -> ASN1ExtractableValueTypes?
    {
        let type = identifier.type
        
        guard type != .unknown else
        {
            return nil
        }
        
        let l = length.value
        
        guard l > 0, var valueData: Data = valueData else
        {
            return nil
        }

        switch type
        {
        case .integer:
            return ASN1Object.readInt(from: &valueData, l: l)
        case .octetString:
            if let asn1 = try? ASN1Object.initializeASN1Object(from: valueData)
            {
                return asn1
            }else{
                return valueData
            }
            
        case .endOfContent:
            return nil
        case .boolean:
            return true
        case .bitString:
            return ""
        case .null:
            return nil
        case .objectIdentifier:
            return "objectIdentifier"
        case .objectDescriptor:
            return "objectIdentifier"
        case .external:
            return "external"
        case .real:
            return "real"
        case .enumerated:
            return "enumerated"
        case .embeddedPdv:
            return "embeddedPdv"
        case .utf8String:
            return ASN1Object.readString(from: &valueData, l, encoding: .utf8)
        case .relativeOid:
            return "relativeOid"
        case .sequence, .set:
            return ASN1Object(data: valueData)
        case .numericString:
            return "numericString"
        case .printableString:
            return "printableString"
        case .t61String:
            return "t61String"
        case .videotexString:
            return "videotexString"
        case .ia5String:
            return ASN1Object.readString(from: &valueData, l, encoding: .ascii)
        case .utcTime:
            return "utcTime"
        case .generalizedTime:
            return "generalizedTime"
        case .graphicString:
            return "graphicString"
        case .visibleString:
            return "visibleString"
        case .generalString:
            return "generalString"
        case .universalString:
            return "universalString"
        case .characterString:
            return "characterString"
        case .bmpString:
            return "bmpString"
        default:
            return nil
        }
    }
}