//
//  GXUserNotificationsProviderOneSignal.swift
//  GXNotificationsProvider_OneSignal
//

import Foundation
import GXCoreBL
import GXCoreModule_SD_Notifications
import OneSignalFramework

@objc(GXUserNotificationsProviderOneSignal)
open class GXUserNotificationsProviderOneSignal: NSObject, GXUserNotificationsProviderProtocol, GXRemoteNotificationsProviderAppDelegateProtocol, OSNotificationLifecycleListener, OSNotificationClickListener, OSPushSubscriptionObserver {
	
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
		OneSignal.initialize(appId ?? "", withLaunchOptions: launchOptions)
		OneSignal.Notifications.addForegroundLifecycleListener(self)
		OneSignal.Notifications.addClickListener(self)
		let pushSubscription = OneSignal.User.pushSubscription
		if let userId = pushSubscription.id {
			self.userId = userId
            print("🔑 OneSignal playerId desde initializeProvider: \(userId)")
		} else {
			pushSubscription.addObserver(self)
		}
	}
	
	public final var usesMethodSwizzerlingOnDelegateClasses: Bool { true }
	
	public final var usesMethodSwizzerlingOnDelegateClassesForSilentNotifications: Bool { false }
	
	public final var remoteAppDelegate: any GXRemoteNotificationsProviderAppDelegateProtocol { self }
	
	// MARK: Remote
	
	open func registerForPushNotifications() -> Void {
		OneSignal.Notifications.requestPermission()
	}
	
	public final var registeringForPushNotificationsAlsoRegisterForUserNotification: Bool { true }
	
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
	
	public final var handlesSilentNotificationsCompletion: Bool { false }
	
	public final var handlesNotificationsResponsesCompletion: Bool { false }
	
	// MARK: GXRemoteNotificationsProviderAppDelegateProtocol
	
	public final func onDidRegisterForRemoteNotifications(withDeviceToken devToken: Data) { }
	
	public final func onDidFailToRegisterForRemoteNotificationsWithError(_ error: Error) { }
	
	#if !os(tvOS)
	public final func onDidReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping () -> Void) {
		guard let notification = OSNotification.parse(withApns: userInfo), let additionalData = notification.additionalData, notification.isSilentNotification,
		let notificationActionHandler = GXUNNotificationFactory.actionHandler(for: GXUNNotificationDefaultActionIdentifier, fromPushNotification: additionalData) else {
			completionHandler()
			return
		}
		GXUserNotificationsManager.handleReceivedSilentNotification(notificationActionHandler, withCompletionHandler: completionHandler)
	}
	#endif // !os(tvOS)

	// MARK: OSNotificationLifecycleListener
	
	open func onWillDisplay(event: OSNotificationWillDisplayEvent) {
		guard event.notification.isSilentNotification else {
			if GXUserNotificationsManager.defaultGXUNNotificationPresentationOptions.isEmpty {
				event.preventDefault()
			}
			return
		}
		event.preventDefault()
		if let additionalData = event.notification.additionalData,
		   let notificationActionHandler = GXUNNotificationFactory.actionHandler(for: GXUNNotificationDefaultActionIdentifier, fromPushNotification: additionalData) {
			GXUserNotificationsManager.handleReceivedSilentNotification(notificationActionHandler)
		}
	}
	
	// MARK: OSNotificationClickListener
	
	open func onClick(event: OSNotificationClickEvent) {
		guard !event.notification.isSilentNotification else { return }
		
		let gxNotificationResponse = GXOSNotificationOpenedResultWrapper.from(event: event)
		GXUserNotificationsManager.handleReceivedNotificationResponse(gxNotificationResponse)
	}
	
	// MARK: OSPushSubscriptionObserver
	
	open func onPushSubscriptionDidChange(state: OneSignalUser.OSPushSubscriptionChangedState) {
		if let newUserId = state.current.id {
			self.userId = newUserId
            print("🔑 OneSignal playerId recibido en onPushSubscriptionDidChange: \(newUserId)")
			if let completion = waitingForUserIdCompletion {
				waitingForUserIdCompletion = nil
				let additionalData = GXUserNotificationsProviderOneSignal.registrationHandlerAdditionalData(withUserId: newUserId)
				completion(additionalData)
			}
		}
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
