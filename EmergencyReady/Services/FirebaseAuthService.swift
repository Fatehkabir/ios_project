import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseAuthService: ObservableObject {

    @Published var currentUser: User? = nil
    @Published var userRegion: String = "Dhaka"
    @Published var emergencyNumber: String = "999"
    @Published var isWorking: Bool = false
    @Published var errorMessage: String? = nil

    private var handle: AuthStateDidChangeListenerHandle?
    private var db: Firestore { Firestore.firestore() }

    init() {
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif

        // Load cached preferences
        self.userRegion = UserDefaults.standard.string(forKey: "user_selected_region") ?? "Dhaka"
        self.emergencyNumber = UserDefaults.standard.string(forKey: "user_emergency_number") ?? "999"

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

    // MARK: - Admin Role Check
    var isAdmin: Bool {
        let email = userEmail.lowercased().trimmingCharacters(in: .whitespaces)
        return email.contains("admin") || email.hasPrefix("admin@") || email == "admin@emergencyready.app"
    }

    // MARK: - Auth Actions

    func register(email: String, password: String, region: String, emergencyNumber: String) {
        isWorking = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    self?.saveUserProfile(uid: user.uid, region: region, emergencyNumber: emergencyNumber)
                }
            }
        }
    }

    func login(email: String, password: String) {
        isWorking = true
        errorMessage = nil

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

    // MARK: - User Profile in Firestore & Local Preferences

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

    private func saveUserProfile(uid: String, region: String, emergencyNumber: String) {
        self.userRegion = region
        self.emergencyNumber = emergencyNumber
        UserDefaults.standard.set(region, forKey: "user_selected_region")
        UserDefaults.standard.set(emergencyNumber, forKey: "user_emergency_number")

        db.collection("users").document(uid).setData([
            "region": region,
            "emergencyNumber": emergencyNumber,
            "email": currentUser?.email ?? "",
            "createdAt": Timestamp(date: Date())
        ], merge: true)
    }

    private func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                if let reg = data["region"] as? String, !reg.isEmpty {
                    self?.userRegion = reg
                    UserDefaults.standard.set(reg, forKey: "user_selected_region")
                }
                if let num = data["emergencyNumber"] as? String, !num.isEmpty {
                    self?.emergencyNumber = num
                    UserDefaults.standard.set(num, forKey: "user_emergency_number")
                }
            }
        }
    }
}
