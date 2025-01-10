//
//  GXOSNotificationResponseWrapper.swift
//  GXNotificationsProvider_OneSignal
//

import Foundation
import OneSignalFramework
import GXCoreBL
import GXCoreModule_SD_Notifications

public class GXOSNotificationOpenedResultWrapper: NSObject, GXUNNotificationResponse, GXUNNotification, GXUNNotificationRequest, GXUNNotificationContent {
	
	public let osNotificationClickEvent: OSNotificationClickEvent
	
	class func from(event: OSNotificationClickEvent) -> GXOSNotificationOpenedResultWrapper {
//		if result.userText == nil {
			return GXOSNotificationOpenedResultWrapper(event: event)
//		}
//		else {
//			return GXOSNotificationOpenedResultTextInputWrapper(event: event)
//		}
	}
	
	fileprivate init(event: OSNotificationClickEvent) {
		self.osNotificationClickEvent = event
		super.init()
	}
	
	// MARK: - GXUNNotificationResponse
	
	public var notification: GXUNNotification {
		get { return self }
	}
	
	public var actionIdentifier: String {
		get {
			guard let actionID = self.osNotificationClickEvent.result.actionId else {
				return GXUNNotificationDefaultActionIdentifier
			}
			
			switch actionID {
			case UNNotificationDefaultActionIdentifier:
				return GXUNNotificationDefaultActionIdentifier
			case UNNotificationDismissActionIdentifier:
				return GXUNNotificationDismissActionIdentifier
			default: break
			}
			return actionID
		}
	}
	
	// MARK: - GXUNNotification
	
	
	public var date: Date? { return nil }
	
	public var request: GXUNNotificationRequest { get { return self } }
	
	// MARK: - GXUNNotificationRequest
	
	public var identifier: String {
		get { return self.osNotificationClickEvent.notification.notificationId ?? "" }
	}
	
	public var content: GXUNNotificationContent { get { return self } }
	
	// MARK: - GXUNNotificationRequest
	
	public var badge: NSNumber? {
		get {
			let badge = self.osNotificationClickEvent.notification.badge
			guard badge > 0 else { return nil }
			return NSNumber(value: badge)
		}
	}
	
	public var body: String? {
		get {
			return self.osNotificationClickEvent.notification.body
		}
	}
	
	public var categoryIdentifier: String? {
		get {
			self.osNotificationClickEvent.notification.category
		}
	}
	
	public var subtitle: String? {
		get {
			return self.osNotificationClickEvent.notification.subtitle
		}
	}
	
	public var threadIdentifier: String? {
		get {
			return self.osNotificationClickEvent.notification.threadId
		}
	}
	
	public var title: String? {
		get {
			return self.osNotificationClickEvent.notification.title
		}
	}
	
	public var userInfo: [AnyHashable : Any] {
		get {
			return self.osNotificationClickEvent.notification.additionalData ?? [:]
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
			return self.osNotificationClickEvent.notification.rawPayload["aps"] as? [AnyHashable : Any]
		}
	}
}


//public class GXOSNotificationOpenedResultTextInputWrapper: GXOSNotificationOpenedResultWrapper {
//	
//	// MARK: GXUNNotificationResponse
//	
//	public var userText: String {
//		get { return self.osNotificationClickEvent.result.userText ?? "" }
//	}
//}
