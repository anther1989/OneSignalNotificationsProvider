//
//  NotificationService.swift
//  OneSignalNotificationServiceExtension
//

import UserNotifications
import OneSignalExtension
//import EngageKit
import os.log

class NotificationService: UNNotificationServiceExtension {

	var contentHandler: ((UNNotificationContent) -> Void)?
	var receivedRequest: UNNotificationRequest!
	var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.receivedRequest = request;
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // Logs para confirmar ejecución
        print("📢 NotificationServiceExtension ejecutado")
        os_log("NotificationServiceExtension ejecutado")

        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = "Notificación modificada"
            bestAttemptContent.subtitle = "Extensión ejecutada"
            bestAttemptContent.body += " (modificada por la extensión)"

            contentHandler(bestAttemptContent)
        }
        
        //Handle the Engage Push response//
        /*if Engage.shared.isEngagePayload(bestAttemptContent?.userInfo){
            Engage.shared.handleNSEPush(
                request,
                using: "group.com.firstorion.enterprise.engagecalling.uae", // Insert your App Group ID
                includeThumbnail: false, // (Optional) Defaults to true if left out
                withContentHandler: contentHandler // Pass in the content handler parameter
            )
        } else {*/
            //Handle other Push Response like OneSignal //
           /* if let bestAttemptContent = bestAttemptContent {
                OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: contentHandler)
            }*/
        //}
    }

	override func serviceExtensionTimeWillExpire() {
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        
        // Logs para saber si se agotó el tiempo
        print("⚠️ Extensión está por expirar sin completar")
        os_log("Extensión está por expirar sin completar")

        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
        
		/*if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
			OneSignalExtension.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
			contentHandler(bestAttemptContent)
		}*/
	}

}
