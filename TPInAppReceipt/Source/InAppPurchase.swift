//
//  InAppPurchase.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 19/01/17.
//  Updated by Siarhei Ladzeika
//  Copyright © 2017 Pavel Tikhonenko. All rights reserved.
//  Copyright © 2019-present Siarhei Ladzeika. All rights reserved.
//

import Foundation

fileprivate let dateFormatter = { () -> DateFormatter in
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return formatter
}()

public enum InAppType: Int
{
    case unknown = -1
    case nonConsumable = 0
    case consumable = 1
    case nonRenewingSubscription = 2
    case autoRenewableSubscription = 3
}

public struct InAppPurchase
{
    /// The product identifier which purchase related to
    public var productIdentifier: String
    
    /// Transaction identifier
    public var transactionIdentifier: String
    
    /// Original Transaction identifier
    public var originalTransactionIdentifier: String
    
    /// Purchase Date in string format
    public var purchaseDateString: String
    
    /// Original Purchase Date in string format
    public var originalPurchaseDateString: String

    /// Subscription Expiration Date in string format. Returns `nil` if the purchase is not a renewable subscription
    public var subscriptionExpirationDateString: String? = nil

    /// Cancellation Date in string format. Returns `nil` if the purchase is not a renewable subscription
    public var cancellationDateString: String? = nil

    /// This value is `true`if the customer’s subscription is currently in the free trial period, or `false` if not.
    /// Returns `nil` if the purchase is not a renewable subscription
    public var subscriptionTrialPeriod: Bool? = nil
    
    /// This value is `true` if the customer’s subscription is currently in an introductory price period, or `false` if not.
    /// Returns `nil` if the purchase is not a renewable subscription
    public var subscriptionIntroductoryPricePeriod: Bool? = nil

    /// This value returns discount identifier used while purchase
    /// Returns nil if no any discount was used when purchase.
    public var discountIdentifier: String? = nil

    /// Type of purchase
    public var type: InAppType

    ///
    public var webOrderLineItemID: Int? = nil
    
    /// Quantity
    public var quantity: Int
    
    public init()
    {
        originalTransactionIdentifier = ""
        productIdentifier = ""
        transactionIdentifier = ""
        purchaseDateString = ""
        originalPurchaseDateString = ""
        quantity = 0
        type = .unknown
    }
    
    public init(asn1Data: Data)
    {
        self.init(asn1Obj: ASN1Object(data: asn1Data))
    }
    
    init(asn1Obj: ASN1Object)
    {
        self.init()
        
        asn1Obj.enumerateInAppReceiptAttributes { (attribute) in
            if let field = InAppReceiptField(rawValue: attribute.type), var value = attribute.value.extractValue() as? Data
            {
                switch field
                {
                case .quantity:
                    quantity = ASN1.readInt(from: &value)
                case .productIdentifier:
                    productIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .transactionIdentifier:
                    transactionIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .purchaseDate:
                    purchaseDateString = ASN1.readString(from: &value, encoding: .ascii)
                case .originalTransactionIdentifier:
                    originalTransactionIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .originalPurchaseDate:
                    originalPurchaseDateString = ASN1.readString(from: &value, encoding: .ascii)
                case .subscriptionExpirationDate:
                    let str = ASN1.readString(from: &value, encoding: .ascii)
                    subscriptionExpirationDateString = str == "" ? nil : str
                case .cancellationDate:
                    let str = ASN1.readString(from: &value, encoding: .ascii)
                    cancellationDateString = str == "" ? nil : str
                case .webOrderLineItemID:
                    webOrderLineItemID = ASN1.readInt(from: &value)
                case .subscriptionTrialPeriod:
                    subscriptionTrialPeriod = ASN1.readInt(from: &value) != 0
                case .subscriptionIntroductoryPricePeriod:
                    subscriptionIntroductoryPricePeriod = ASN1.readInt(from: &value) != 0
                case .discountIdentifier:
                    discountIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .type:
                    type = InAppType(rawValue: ASN1.readInt(from: &value)) ?? .unknown
                default:
                    break
                }
            }
        }
    }
}

public extension InAppPurchase
{
    /// Purchase Date representation as a 'Date' object
    var purchaseDate: Date
    {
        return purchaseDateString.rfc3339date()!
    }

    /// Original Purchase Date representation as a 'Date' object
    var originalPurchaseDate: Date
    {
        return originalPurchaseDateString.rfc3339date()!
    }
    
    /// Subscription Expiration Date representation as a 'Date' object. Returns `nil` if the purchase has been expired (in some cases)
    var subscriptionExpirationDate: Date?
    {
        assert(isRenewableSubscription, "\(productIdentifier) is not an auto-renewable subscription.")
       
        return subscriptionExpirationDateString?.rfc3339date()
    }

    /// Cancellation Date representation as a 'Date' object. Returns `nil` if the purchase has not been cancelled
    var cancellationDate: Date?
    {
        assert(isRenewableSubscription, "\(productIdentifier) is not an auto-renewable subscription.")

        return cancellationDateString?.rfc3339date()
    }
    
    /// A Boolean value indicating whether the purchase is renewable subscription.
    var isRenewableSubscription: Bool
    {
        return self.subscriptionExpirationDateString != nil
    }
    
    /// Check whether the subscription is active for a specific date
    ///
    /// - Parameter date: The date in which the auto-renewable subscription should be active.
    /// - Returns: true if the latest auto-renewable subscription is active for the given date, false otherwise.
    func isActiveAutoRenewableSubscription(forDate date: Date) -> Bool
    {
        assert(isRenewableSubscription, "\(productIdentifier) is not an auto-renewable subscription.")
        
        if(self.cancellationDateString != nil && self.cancellationDateString != "")
        {
            return false
        }
        
        guard let expirationDate = subscriptionExpirationDate else
        {
            return false
        }
        
        return date >= purchaseDate && date < expirationDate
    }
}
