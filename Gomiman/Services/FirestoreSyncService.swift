import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

public final class FirestoreSyncService: @unchecked Sendable {
    public static let shared = FirestoreSyncService()

    public static let collectionUsers = "users"
    public static let collectionFeedback = "feedback"

    private init() {}

    /// Sync user and device metadata to Firestore collection 'users'
    public func syncBaseInfo(_ userInfo: UserInfoModel) async -> Result<Void, Error> {
        guard let docId = userInfo.deviceUniqueId, !docId.isEmpty else {
            return .failure(NSError(domain: "FirestoreSyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Device ID cannot be empty"]))
        }

        #if canImport(FirebaseFirestore)
        do {
            let db = Firestore.firestore()
            var userMap: [String: Any] = [
                "deviceUniqueId": userInfo.deviceUniqueId as Any,
                "version": userInfo.version,
                "buildNumber": userInfo.buildNumber,
                "timeZoneOffsetInHours": userInfo.timeZoneOffsetInHours,
                "platform": "iOS",
                "isPhysicalDevice": userInfo.isPhysicalDevice,
                "brand": userInfo.brand,
                "model": userInfo.model,
                "device": userInfo.device,
                "name": userInfo.name,
                "systemVersion": userInfo.systemVersion,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            if let token = userInfo.fcmToken {
                userMap["fcmToken"] = token
            }

            try await db.collection(Self.collectionUsers).document(docId).setData(userMap, merge: true)
            #if DEBUG
            print("[FirestoreSync] Successfully synced base info for docId: \(docId)")
            #endif
            return .success(())
        } catch {
            #if DEBUG
            print("[FirestoreSync] Failed to sync base info: \(error.localizedDescription)")
            #endif
            return .failure(error)
        }
        #else
        return .success(())
        #endif
    }

    /// Sync refreshed FCM Token to Firestore collection 'users'
    public func syncFCMToken(_ token: String) async -> Result<Void, Error> {
        let docId = PreferencesManager.shared.getOrCreateDeviceUniqueId()

        #if canImport(FirebaseFirestore)
        do {
            let db = Firestore.firestore()
            let updateData: [String: Any] = [
                "fcmToken": token,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            try await db.collection(Self.collectionUsers).document(docId).setData(updateData, merge: true)
            #if DEBUG
            print("[FirestoreSync] FCM token synced to Firestore for docId: \(docId)")
            #endif
            return .success(())
        } catch {
            return .failure(error)
        }
        #else
        return .success(())
        #endif
    }

    /// Direct fallback write of garbage schedule to Firestore
    public func syncGarbageSettingDirectly(collections: [GarbageCollectionModel], version: Int64) async -> Result<Void, Error> {
        let docId = PreferencesManager.shared.getOrCreateDeviceUniqueId()

        #if canImport(FirebaseFirestore)
        do {
            let db = Firestore.firestore()
            let data: [String: Any] = [
                "userGarbageInfo": collections.map { $0.toDictionary() },
                "version": version,
                "garbageVersion": version,
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await db.collection(Self.collectionUsers).document(docId).setData(data, merge: true)
            #if DEBUG
            print("[FirestoreSync] Direct fallback write of \(collections.count) schedules succeeded")
            #endif
            return .success(())
        } catch {
            return .failure(error)
        }
        #else
        return .success(())
        #endif
    }

    /// Submit feedback to Firestore collection 'feedback'
    public func submitFeedback(message: String) async -> Result<Void, Error> {
        let docId = PreferencesManager.shared.getOrCreateDeviceUniqueId()
        let userInfo = UserInfoCollector.collect()

        #if canImport(FirebaseFirestore)
        do {
            let db = Firestore.firestore()
            let feedbackData: [String: Any] = [
                "deviceUniqueId": docId,
                "identifierForVendor": docId,
                "message": message,
                "feedbackMessage": message,
                "platform": "iOS",
                "appVersion": userInfo.version,
                "buildNumber": userInfo.buildNumber,
                "deviceModel": userInfo.model,
                "osVersion": userInfo.systemVersion,
                "timestamp": FieldValue.serverTimestamp(),
                "createdAt": FieldValue.serverTimestamp()
            ]

            _ = try await db.collection(Self.collectionFeedback).addDocument(data: feedbackData)
            #if DEBUG
            print("[FirestoreSync] Feedback submitted successfully to Firestore")
            #endif
            return .success(())
        } catch {
            return .failure(error)
        }
        #else
        return .success(())
        #endif
    }
}
