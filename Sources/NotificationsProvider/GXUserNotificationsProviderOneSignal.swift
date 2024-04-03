//
//  GXUserNotificationsProviderOneSignal.swift
//  GXNotificationsProvider_OneSignal
//

import Foundation
import GXCoreBL
import GXCoreModule_SD_Notifications
import OneSignal

@objc(GXUserNotificationsProviderOneSignal)
open class GXUserNotificationsProviderOneSignal: NSObject, GXUserNotificationsProviderProtocol, OSSubscriptionObserver {
	
	private var userId : String? = nil
	private class func registrationHandlerAdditionalData(withUserId userId: String?) -> [String: Any] {
		if let userId = userId {
			return [ "NotificationPlatformId": userId ]
		}
		else {
			return [:]
		}
	}
	private var waitingForUserIdCompletion: (([String: Any]) -> Void)? = nil
	
	public static let notificationsProviderTypeIdentifier = "OneSignal"
	
	// MARK: - GXUserNotificationsProviderProtocol
	public let typeIdentifier = GXUserNotificationsProviderOneSignal.notificationsProviderTypeIdentifier
	
	open func initializeProvider(withLaunchOptions launchOptions: [AnyHashable: Any]?) -> Void {
		let appId = GXUserNotificationsManager.notificationsProviderProperties["AppID"] as? String
		
		OneSignal.setLocationShared(false)
		OneSignal.initWithLaunchOptions(launchOptions)
		OneSignal.setAppId(appId ?? "")
		
		let notifWillShowInForegroundHandler: OSNotificationWillShowInForegroundBlock = { notification, completion in
			guard notification.isSilentNotification else {
				completion(GXUserNotificationsManager.defaultGXUNNotificationPresentationOptions.isEmpty ? nil : notification)
				return
			}
			
			if let additionalData = notification.additionalData, let notificationActionHandler = GXUNNotificationFactory.actionHandler(for: GXUNNotificationDefaultActionIdentifier, fromPushNotification: additionalData) {
				GXUserNotificationsManager.handleReceivedSilentNotification(notificationActionHandler)
			}
			
			completion(nil)
		}
		OneSignal.setNotificationWillShowInForegroundHandler(notifWillShowInForegroundHandler)

		let notificationOpenedBlock: OSNotificationOpenedBlock = { result in
			guard !result.notification.isSilentNotification else { return }
			
			let gxNotificationResponse = GXOSNotificationOpenedResultWrapper.from(result: result)
			GXUserNotificationsManager.handleReceivedNotificationResponse(gxNotificationResponse)
		}
		OneSignal.setNotificationOpenedHandler(notificationOpenedBlock)
		if let userId = OneSignal.getDeviceState().userId {
			self.userId = userId
		} else {
			OneSignal.add(self as OSSubscriptionObserver);
		}
	}
	
	public final var usesMethodSwizzerlingOnDelegateClasses: Bool {
		get { return true }
	}
	
	// MARK: OSSubscriptionObserver
	
	open func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges) {
		if let newUserId = stateChanges.to.userId {
			self.userId = newUserId
			if let completion = waitingForUserIdCompletion {
				waitingForUserIdCompletion = nil
				let additionalData = GXUserNotificationsProviderOneSignal.registrationHandlerAdditionalData(withUserId: newUserId)
				completion(additionalData)
			}
		}
	}
	
	// MARK: Remote
	
	open func registerForPushNotifications() -> Void {
		OneSignal.promptForPushNotifications(userResponse: nil)
	}
	
	public final var registeringForPushNotificationsAlsoRegisterForUserNotification: Bool {
		get { return true }
	}
	
	open func registrationHandlerAdditionalData(completion: @escaping ([String: Any]) -> Void) -> Void {
		if let userId = self.userId {
			let additionalData = GXUserNotificationsProviderOneSignal.registrationHandlerAdditionalData(withUserId: userId)
			completion(additionalData)
		}
		else {
			if let currentCompletion = waitingForUserIdCompletion {
				waitingForUserIdCompletion = {
					currentCompletion($0)
					completion($0)
				}
			}
			else {
				waitingForUserIdCompletion = completion
			}
		}
	}
	
	public final var handlesSilentNotificationsCompletion: Bool {
		get { return false }
	}
	
	public final var handlesNotificationsResponsesCompletion: Bool {
		get { return false }
	}
}

private extension OSNotification {
	
	// Source https://github.com/OneSignal/OneSignal-iOS-SDK/blob/5ff232ea9392f63e87306752025a45eceb18fa5b/iOS_SDK/OneSignalSDK/OneSignalCore/Source/OSNotification.m#L46
	/// No alert, sound, or badge payload
	var isSilentNotification: Bool {
		get {
			lazy var apsPayload = self.rawPayload["aps"] as? [AnyHashable : Any]
			let hasAlert = self.body != nil || self.title != nil || self.subtitle != nil || apsPayload?["alert"] != nil
			guard !hasAlert else { return false }
			let hasBadge = self.badge != 0 || self.badgeIncrement != 0 || rawPayload["badge"] != nil || apsPayload?["badge"] != nil
			guard !hasBadge else { return false }
			let hasSound = self.sound != nil
			guard !hasSound else { return false }
			let hasActionButtons = self.actionButtons?.isEmpty == false
			guard !hasActionButtons else { return false }
			return true
		}
	}
}
