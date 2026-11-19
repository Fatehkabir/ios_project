import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseAuthService: ObservableObject {

    @Published var currentUser: User? = nil
    @Published var username: String = ""
    @Published var userRegion: String = "Dhaka"
    @Published var emergencyNumber: String = "999"
    @Published var profileImageBase64: String = ""
    @Published var isWorking: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    private var handle: AuthStateDidChangeListenerHandle?
    private var db: Firestore { Firestore.firestore() }

    init() {
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif

        // Load cached preferences for instant offline access
        self.username = UserDefaults.standard.string(forKey: "user_username") ?? ""
        self.userRegion = UserDefaults.standard.string(forKey: "user_selected_region") ?? "Dhaka"
        self.emergencyNumber = UserDefaults.standard.string(forKey: "user_emergency_number") ?? "999"
        self.profileImageBase64 = UserDefaults.standard.string(forKey: "user_profile_image") ?? ""

        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                if let uid = user?.uid {
                    self?.fetchUserProfile(uid: uid)
                }
            }
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isAuthenticated: Bool { currentUser != nil }
    var userId: String? { currentUser?.uid }
    var userEmail: String { currentUser?.email ?? "" }

    var displayName: String {
        if !username.trimmingCharacters(in: .whitespaces).isEmpty {
            return username
        }
        if let name = userEmail.split(separator: "@").first, !name.isEmpty {
            return String(name)
        }
        return "User"
    }

    // MARK: - Admin Role Check
    var isAdmin: Bool {
        let email = userEmail.lowercased().trimmingCharacters(in: .whitespaces)
        return email.contains("admin") || email.hasPrefix("admin@") || email == "admin@emergencyready.app"
    }

    // MARK: - Auth Actions

    func register(email: String, password: String, username: String, region: String, emergencyNumber: String) {
        isWorking = true
        errorMessage = nil
        successMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    self?.username = username
                    self?.saveUserProfile(uid: user.uid, username: username, region: region, emergencyNumber: emergencyNumber, photoBase64: "")
                }
            }
        }
    }

    func login(email: String, password: String) {
        isWorking = true
        errorMessage = nil
        successMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    self?.fetchUserProfile(uid: user.uid)
                }
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update Profile (Username & Profile Photo)

    func updateProfile(newUsername: String, photoBase64: String?, completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }

        isWorking = true
        errorMessage = nil
        successMessage = nil

        var updates: [String: Any] = [
            "username": newUsername
        ]

        if let photo = photoBase64 {
            updates["profileImage"] = photo
            self.profileImageBase64 = photo
            UserDefaults.standard.set(photo, forKey: "user_profile_image")
        }

        self.username = newUsername
        UserDefaults.standard.set(newUsername, forKey: "user_username")

        db.collection("users").document(uid).setData(updates, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self?.successMessage = "Profile updated successfully!"
                    completion(true)
                }
            }
        }
    }

    // MARK: - Change Password

    func changePassword(newPassword: String, completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }

        isWorking = true
        errorMessage = nil
        successMessage = nil

        user.updatePassword(to: newPassword) { [weak self] error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self?.successMessage = "Password changed successfully!"
                    completion(true)
                }
            }
        }
    }

    // MARK: - Settings

    func updateEmergencyNumber(_ number: String) {
        self.emergencyNumber = number
        UserDefaults.standard.set(number, forKey: "user_emergency_number")
        if let uid = userId {
            db.collection("users").document(uid).setData(["emergencyNumber": number], merge: true)
        }
    }

    func updateRegion(_ region: String) {
        self.userRegion = region
        UserDefaults.standard.set(region, forKey: "user_selected_region")
        if let uid = userId {
            db.collection("users").document(uid).setData(["region": region], merge: true)
        }
    }

    private func saveUserProfile(uid: String, username: String, region: String, emergencyNumber: String, photoBase64: String) {
        self.username = username
        self.userRegion = region
        self.emergencyNumber = emergencyNumber
        self.profileImageBase64 = photoBase64

        UserDefaults.standard.set(username, forKey: "user_username")
        UserDefaults.standard.set(region, forKey: "user_selected_region")
        UserDefaults.standard.set(emergencyNumber, forKey: "user_emergency_number")
        UserDefaults.standard.set(photoBase64, forKey: "user_profile_image")

        db.collection("users").document(uid).setData([
            "username": username,
            "region": region,
            "emergencyNumber": emergencyNumber,
            "profileImage": photoBase64,
            "email": currentUser?.email ?? "",
            "createdAt": Timestamp(date: Date())
        ], merge: true)
    }

    private func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                if let name = data["username"] as? String, !name.isEmpty {
                    self?.username = name
                    UserDefaults.standard.set(name, forKey: "user_username")
                }
                if let reg = data["region"] as? String, !reg.isEmpty {
                    self?.userRegion = reg
                    UserDefaults.standard.set(reg, forKey: "user_selected_region")
                }
                if let num = data["emergencyNumber"] as? String, !num.isEmpty {
                    self?.emergencyNumber = num
                    UserDefaults.standard.set(num, forKey: "user_emergency_number")
                }
                if let photo = data["profileImage"] as? String, !photo.isEmpty {
                    self?.profileImageBase64 = photo
                    UserDefaults.standard.set(photo, forKey: "user_profile_image")
                }
            }
        }
    }
}
