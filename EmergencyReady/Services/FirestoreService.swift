import Foundation
import SwiftUI
import FirebaseFirestore

// ALL Firestore reading and writing lives here, so the SwiftUI views stay simple.
//
// Database layout (every document is under the logged-in user's uid):
//   users/{uid}                      -> { checklistSeeded: true }
//   users/{uid}/contacts/{id}        -> name, phone, relationship, createdAt
//   users/{uid}/favorites/{guideId}  -> guideId, createdAt
//   users/{uid}/checklistItems/{id}  -> title, isCompleted, createdAt
//
// We use "snapshot listeners": Firestore calls our closure once at the start and again
// every time the data changes, so the screens always show the latest data.
class FirestoreService: ObservableObject {

    // @Published = SwiftUI redraws any view that reads these when they change.
    @Published var contacts: [EmergencyContact] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var favoriteIds: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var db: Firestore { Firestore.firestore() }
    private var userId: String? = nil
    private var listeners: [ListenerRegistration] = []

    // Used to know when ALL three first loads have finished.
    private var contactsLoaded = false
    private var checklistLoaded = false
    private var favoritesLoaded = false

    // MARK: - Start / stop

    // Called when the user logs in (MainTabView appears).
    func startListening(userId: String) {
        stopListening()
        self.userId = userId
        isLoading = true
        contactsLoaded = false
        checklistLoaded = false
        favoritesLoaded = false

        let userDocument = db.collection("users").document(userId)

        // READ contacts (live)
        let contactsListener = userDocument.collection("contacts").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error { self.show(error) }
            let documents = snapshot?.documents ?? []
            self.contacts = documents
                .compactMap { EmergencyContact(id: $0.documentID, data: $0.data()) }
                .sorted { $0.createdAt < $1.createdAt }
            self.contactsLoaded = true
            self.updateLoadingState()
        }

        // READ checklist items (live)
        let checklistListener = userDocument.collection("checklistItems").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error { self.show(error) }
            let documents = snapshot?.documents ?? []
            self.checklistItems = documents
                .compactMap { ChecklistItem(id: $0.documentID, data: $0.data()) }
                .sorted { $0.createdAt < $1.createdAt }
            self.checklistLoaded = true
            self.updateLoadingState()
        }

        // READ favourites (live). The document id IS the guide id.
        let favoritesListener = userDocument.collection("favorites").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error { self.show(error) }
            let documents = snapshot?.documents ?? []
            self.favoriteIds = Set(documents.map { $0.documentID })
            self.favoritesLoaded = true
            self.updateLoadingState()
        }

        listeners = [contactsListener, checklistListener, favoritesListener]
        createDefaultChecklistIfNeeded(userDocument: userDocument)
    }

    // Called on logout: stop listening and forget the previous user's data.
    func stopListening() {
        for listener in listeners { listener.remove() }
        listeners.removeAll()
        userId = nil
        contacts = []
        checklistItems = []
        favoriteIds = []
        isLoading = false
    }

    private func updateLoadingState() {
        isLoading = !(contactsLoaded && checklistLoaded && favoritesLoaded)
    }

    // New users get the 8 default checklist items once.
    // The flag "checklistSeeded" stops them coming back after the user deletes some.
    private func createDefaultChecklistIfNeeded(userDocument: DocumentReference) {
        userDocument.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                self.show(error)
                return
            }
            let alreadyCreated = snapshot?.data()?["checklistSeeded"] as? Bool ?? false
            if alreadyCreated { return }

            let batch = self.db.batch()   // a batch = several writes that succeed or fail together
            for item in ChecklistItem.defaultItems {
                let reference = userDocument.collection("checklistItems").document(item.id)
                batch.setData(item.dictionary, forDocument: reference)
            }
            batch.setData(["checklistSeeded": true], forDocument: userDocument, merge: true)
            batch.commit { error in
                if let error = error { self.show(error) }
            }
        }
    }

    // MARK: - Contacts (CRUD)

    // CREATE
    func addContact(_ contact: EmergencyContact) {
        guard let userId = userId else { return notLoggedIn() }
        db.collection("users").document(userId)
            .collection("contacts").document(contact.id)
            .setData(contact.dictionary) { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    // UPDATE (changes only the fields that can be edited)
    func updateContact(_ contact: EmergencyContact) {
        guard let userId = userId else { return notLoggedIn() }
        let changes: [String: Any] = [
            "name": contact.name,
            "phone": contact.phone,
            "relationship": contact.relationship
        ]
        db.collection("users").document(userId)
            .collection("contacts").document(contact.id)
            .updateData(changes) { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    // DELETE
    func deleteContact(_ contact: EmergencyContact) {
        guard let userId = userId else { return notLoggedIn() }
        db.collection("users").document(userId)
            .collection("contacts").document(contact.id)
            .delete { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    // MARK: - Checklist

    func addChecklistItem(title: String) {
        guard let userId = userId else { return notLoggedIn() }
        let item = ChecklistItem(title: title)
        db.collection("users").document(userId)
            .collection("checklistItems").document(item.id)
            .setData(item.dictionary) { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    func setItemCompleted(_ item: ChecklistItem, completed: Bool) {
        guard let userId = userId else { return notLoggedIn() }

        // Update the screen straight away (with animation); Firestore confirms a moment later.
        if let index = checklistItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.easeInOut(duration: 0.25)) {
                checklistItems[index].isCompleted = completed
            }
        }

        db.collection("users").document(userId)
            .collection("checklistItems").document(item.id)
            .updateData(["isCompleted": completed]) { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    func deleteChecklistItem(_ item: ChecklistItem) {
        guard let userId = userId else { return notLoggedIn() }
        db.collection("users").document(userId)
            .collection("checklistItems").document(item.id)
            .delete { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    // MARK: - Favourites

    func isFavorite(_ guideId: String) -> Bool {
        favoriteIds.contains(guideId)
    }

    func setFavorite(guideId: String, isFavorite: Bool) {
        guard let userId = userId else { return notLoggedIn() }

        // Update the heart immediately.
        if isFavorite {
            favoriteIds.insert(guideId)
        } else {
            favoriteIds.remove(guideId)
        }

        let reference = db.collection("users").document(userId)
            .collection("favorites").document(guideId)

        if isFavorite {
            let data: [String: Any] = ["guideId": guideId, "createdAt": Date().timeIntervalSince1970]
            reference.setData(data) { [weak self] error in
                if let error = error { self?.show(error) }
            }
        } else {
            reference.delete { [weak self] error in
                if let error = error { self?.show(error) }
            }
        }
    }

    // MARK: - Safe Status & Live Location Sharing

    func updateSafeStatus(isSafe: Bool, message: String = "") {
        guard let userId = userId else { return notLoggedIn() }
        let data: [String: Any] = [
            "isSafe": isSafe,
            "statusMessage": message,
            "updatedAt": Date().timeIntervalSince1970
        ]
        db.collection("users").document(userId)
            .collection("safetyStatus").document("current")
            .setData(data, merge: true) { [weak self] error in
                if let error = error { self?.show(error) }
            }
    }

    func updateLiveLocation(latitude: Double, longitude: Double) {
        guard let userId = userId else { return }
        let data: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "updatedAt": Date().timeIntervalSince1970
        ]
        db.collection("users").document(userId)
            .collection("liveLocation").document("current")
            .setData(data, merge: true)
    }

    func clearLiveLocation() {
        guard let userId = userId else { return }
        db.collection("users").document(userId)
            .collection("liveLocation").document("current")
            .delete()
    }

    // MARK: - Errors

    private func notLoggedIn() {
        errorMessage = "You must be logged in to do that."
    }

    private func show(_ error: Error) {
        let nsError = error as NSError
        // Firestore error codes: 7 = permission denied, 14 = server unavailable.
        if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
            errorMessage = "Permission denied. Make sure you are logged in and the Firestore security rules are published."
        } else if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 14 {
            errorMessage = "Cannot reach the server. Check your internet connection."
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
