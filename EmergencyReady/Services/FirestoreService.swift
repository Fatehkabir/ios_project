import Foundation
import SwiftUI
import FirebaseFirestore

class FirestoreService: ObservableObject {

    @Published var contacts: [EmergencyContact] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var db: Firestore { Firestore.firestore() }
    private var userId: String? = nil
    private var listener: ListenerRegistration? = nil

    private let contactsCacheKey = "EmergencyReady_Cached_Contacts_V1"

    init() {
        loadCachedContacts()
    }

    func startListening(userId: String) {
        stopListening()
        self.userId = userId
        isLoading = true

        let userDocument = db.collection("users").document(userId)

        listener = userDocument.collection("contacts")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("Firestore contacts offline/error: \(error.localizedDescription)")
                    // Keep existing cached contacts
                    return
                }

                let documents = snapshot?.documents ?? []
                let items = documents.compactMap { doc -> EmergencyContact? in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    let phone = data["phone"] as? String ?? ""
                    let relationship = data["relationship"] as? String ?? ""
                    let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    return EmergencyContact(
                        id: doc.documentID,
                        name: name,
                        phone: phone,
                        relationship: relationship,
                        createdAt: timestamp.dateValue()
                    )
                }

                DispatchQueue.main.async {
                    self.contacts = items
                    self.saveContactsToCache(items)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Contact Operations

    func addContact(name: String, phone: String, relationship: String) {
        guard let userId = userId else { return }
        let newContact = [
            "name": name,
            "phone": phone,
            "relationship": relationship,
            "createdAt": Timestamp(date: Date())
        ] as [String : Any]

        db.collection("users").document(userId).collection("contacts").addDocument(data: newContact) { [weak self] error in
            if let error = error { self?.show(error) }
        }
    }

    func updateContact(id: String, name: String, phone: String, relationship: String) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).collection("contacts").document(id).updateData([
            "name": name,
            "phone": phone,
            "relationship": relationship
        ]) { [weak self] error in
            if let error = error { self?.show(error) }
        }
    }

    func deleteContact(id: String) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).collection("contacts").document(id).delete { [weak self] error in
            if let error = error { self?.show(error) }
        }
    }

    // MARK: - Offline Cache

    private func saveContactsToCache(_ items: [EmergencyContact]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: contactsCacheKey)
        }
    }

    private func loadCachedContacts() {
        if let data = UserDefaults.standard.data(forKey: contactsCacheKey),
           let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            self.contacts = decoded
        }
    }

    private func show(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}
