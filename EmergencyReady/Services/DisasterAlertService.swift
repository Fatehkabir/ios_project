import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

// Real-time synchronization of Regional Disaster Alerts from Firestore with local caching and offline fallback.
class DisasterAlertService: ObservableObject {
    @Published var alerts: [DisasterAlert] = []
    @Published var lastSyncTime: Date? = nil
    @Published var isListening = false
    @Published var errorMessage: String? = nil

    private var db: Firestore { Firestore.firestore() }
    private var listener: ListenerRegistration? = nil
    private let cacheKey = "EmergencyReady_Cached_Disasters_V1"
    private let syncTimeKey = "EmergencyReady_Disasters_LastSync_V1"

    init() {
        loadCachedAlerts()
        startListening()
    }

    func startListening() {
        listener?.remove()
        isListening = true

        listener = db.collection("disaster_alerts")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("DisasterAlertService: Firestore error (using local cache): \(error.localizedDescription)")
                    self.errorMessage = "Offline mode: Showing cached alerts"
                    return
                }

                guard let documents = snapshot?.documents else { return }

                var loadedAlerts: [DisasterAlert] = []
                for doc in documents {
                    let d = doc.data()
                    let id = doc.documentID
                    let title = d["title"] as? String ?? ""
                    let description = d["description"] as? String ?? ""
                    let region = d["region"] as? String ?? ""
                    let categoryId = d["categoryId"] as? String ?? "flood"
                    let severity = d["severity"] as? String ?? "Severe"
                    let isActive = d["isActive"] as? Bool ?? true
                    let createdStamp = d["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    let expiresStamp = d["expiresAt"] as? Timestamp ?? Timestamp(date: Date().addingTimeInterval(86400 * 2))
                    let createdBy = d["createdBy"] as? String ?? "Admin"

                    let alert = DisasterAlert(
                        id: id,
                        title: title,
                        description: description,
                        region: region,
                        categoryId: categoryId,
                        severity: severity,
                        isActive: isActive,
                        createdAt: createdStamp.dateValue(),
                        expiresAt: expiresStamp.dateValue(),
                        createdBy: createdBy
                    )

                    // Only keep non-expired alerts
                    if !alert.isExpired {
                        loadedAlerts.append(alert)
                    }
                }

                DispatchQueue.main.async {
                    self.alerts = loadedAlerts
                    self.lastSyncTime = Date()
                    self.errorMessage = nil
                    self.saveToCache(loadedAlerts)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        isListening = false
    }

    // Filter alerts for the user's selected region
    func activeAlerts(forRegion region: String) -> [DisasterAlert] {
        let cleanRegion = region.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanRegion.isEmpty {
            return alerts.filter { !$0.isExpired }
        }
        return alerts.filter {
            !$0.isExpired && ($0.region.lowercased() == cleanRegion || $0.region.lowercased() == "all" || $0.region.lowercased() == "national")
        }
    }

    // MARK: - Admin Management Operations (Create / Edit / Toggle / Delete)

    func createAlert(_ alert: DisasterAlert, completion: ((Error?) -> Void)? = nil) {
        let data: [String: Any] = [
            "title": alert.title,
            "description": alert.description,
            "region": alert.region,
            "categoryId": alert.categoryId,
            "severity": alert.severity,
            "isActive": alert.isActive,
            "createdAt": Timestamp(date: alert.createdAt),
            "expiresAt": Timestamp(date: alert.expiresAt),
            "createdBy": alert.createdBy
        ]

        db.collection("disaster_alerts").addDocument(data: data) { error in
            completion?(error)
        }
    }

    func updateAlert(_ alert: DisasterAlert, completion: ((Error?) -> Void)? = nil) {
        let data: [String: Any] = [
            "title": alert.title,
            "description": alert.description,
            "region": alert.region,
            "categoryId": alert.categoryId,
            "severity": alert.severity,
            "isActive": alert.isActive,
            "expiresAt": Timestamp(date: alert.expiresAt)
        ]

        db.collection("disaster_alerts").document(alert.id).updateData(data) { error in
            completion?(error)
        }
    }

    func toggleAlertStatus(_ alert: DisasterAlert) {
        db.collection("disaster_alerts").document(alert.id).updateData([
            "isActive": !alert.isActive
        ])
    }

    func deleteAlert(id: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("disaster_alerts").document(id).delete { error in
            completion?(error)
        }
    }

    // MARK: - Local Offline Cache

    private func saveToCache(_ items: [DisasterAlert]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: syncTimeKey)
        }
    }

    private func loadCachedAlerts() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([DisasterAlert].self, from: data) {
            self.alerts = decoded.filter { !$0.isExpired }
        }
        let savedTime = UserDefaults.standard.double(forKey: syncTimeKey)
        if savedTime > 0 {
            self.lastSyncTime = Date(timeIntervalSince1970: savedTime)
        }
    }
}
