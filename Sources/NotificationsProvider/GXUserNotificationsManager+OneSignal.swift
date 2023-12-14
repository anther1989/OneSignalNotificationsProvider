//
//  GXUserNotificationsManager+OneSignal.swift
//
//
//

import GXCoreBL

internal extension GXUserNotificationsManager {
	static var notificationsProviderProperties: [String: Any] {
		if let appID = Bundle.main.object(forInfoDictionaryKey: "GX_NOTIFICATIONSPROVIDER_APPID") as? String {
			return ["AppID": appID]
		} else {
			return [:]
		}
	}
}
