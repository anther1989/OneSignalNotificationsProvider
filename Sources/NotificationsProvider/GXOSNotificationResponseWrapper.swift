//
//  GXOSNotificationResponseWrapper.swift
//  GXNotificationsProvider_OneSignal
//

import Foundation
import OneSignal
import GXCoreBL
import GXCoreModule_SD_Notifications

public class GXOSNotificationOpenedResultWrapper: NSObject, GXUNNotificationResponse, GXUNNotification, GXUNNotificationRequest, GXUNNotificationContent {
	
	public let osNotificationOpenedResult: OSNotificationOpenedResult
	
	class func from(result: OSNotificationOpenedResult) -> GXOSNotificationOpenedResultWrapper {
//		if result.userText == nil {
			return GXOSNotificationOpenedResultWrapper(result: result)
//		}
//		else {
//			return GXOSNotificationOpenedResultTextInputWrapper(result: result)
//		}
	}
	
	fileprivate init(result: OSNotificationOpenedResult) {
		self.osNotificationOpenedResult = result
		super.init()
	}
	
	// MARK: - GXUNNotificationResponse
	
	public var notification: GXUNNotification {
		get { return self }
	}
	
	public var actionIdentifier: String {
		get {
			let action = self.osNotificationOpenedResult.action
			guard let actionID = action.actionId else {
				return GXUNNotificationDefaultActionIdentifier
			}
			
			if #available(iOS 10, *) {
				switch actionID {
				case UNNotificationDefaultActionIdentifier:
					return GXUNNotificationDefaultActionIdentifier
				case UNNotificationDismissActionIdentifier:
					return GXUNNotificationDismissActionIdentifier
				default: break
				}
			}
			else {
				if action.type == .opened || actionID == "__DEFAULT__" {
					return GXUNNotificationDefaultActionIdentifier
				}
			}
			return actionID
		}
	}
	
	// MARK: - GXUNNotification
	
	
	public var date: Date? { return nil }
	
	public var request: GXUNNotificationRequest { get { return self } }
	
	// MARK: - GXUNNotificationRequest
	
	public var identifier: String {
		get { return self.osNotificationOpenedResult.notification.notificationId ?? "" }
	}
	
	public var content: GXUNNotificationContent { get { return self } }
	
	// MARK: - GXUNNotificationRequest
	
	public var badge: NSNumber? {
		get {
			let badge = self.osNotificationOpenedResult.notification.badge
			guard badge > 0 else { return nil }
			return NSNumber(value: badge)
		}
	}
	
	public var body: String? {
		get {
			return self.osNotificationOpenedResult.notification.body
		}
	}
	
	public var categoryIdentifier: String? {
		get {
			guard let aps = self.rawPayloadAPS else { return nil }
			
			return aps["category"] as? String
		}
	}
	
	public var subtitle: String? {
		get {
			return self.osNotificationOpenedResult.notification.subtitle
		}
	}
	
	public var threadIdentifier: String? {
		get {
			guard let aps = self.rawPayloadAPS else { return nil }
			
			return aps["thread-id"] as? String
		}
	}
	
	public var title: String? {
		get {
			return self.osNotificationOpenedResult.notification.title
		}
	}
	
	public var userInfo: [AnyHashable : Any] {
		get {
			return self.osNotificationOpenedResult.notification.additionalData ?? [:]
		}
	}
	
	public func actionHandler(for identifier: String) -> GXUNNotificationActionHandler? {
		return GXUNNotificationFactory.actionHandler(for: identifier, fromPushNotification: self.userInfo)
	}
}
private extension GXOSNotificationOpenedResultWrapper {
	var rawPayloadAPS: [AnyHashable : Any]?
	{
		get {
			return self.osNotificationOpenedResult.notification.rawPayload["aps"] as? [AnyHashable : Any]
		}
	}
}


//public class GXOSNotificationOpenedResultTextInputWrapper: GXOSNotificationOpenedResultWrapper {
//	
//	// MARK: GXUNNotificationResponse
//	
//	public var userText: String {
//		get { return self.osNotificationOpenedResult.userText ?? "" }
//	}
//}
