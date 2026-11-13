import Foundation
import FirebaseAuth

// Handles registration, login and logout with Firebase Authentication.
class FirebaseAuthService: ObservableObject {
    // nil means "nobody is logged in". RootView watches this value.
    @Published var currentUser: User? = nil
    @Published var isWorking = false            // true while a request is running
    @Published var errorMessage: String? = nil

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Firebase tells us whenever the login state changes (login, logout, app restart).
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    deinit {
        if let handle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // Convenience: the unique id used as the Firestore document name for this user.
    var userId: String? { currentUser?.uid }
    var userEmail: String { currentUser?.email ?? "" }

    // MARK: - Register
    func register(email: String, password: String) {
        errorMessage = nil
        isWorking = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = FirebaseAuthService.friendlyMessage(for: error)
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        errorMessage = nil
        isWorking = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isWorking = false
                if let error = error {
                    self?.errorMessage = FirebaseAuthService.friendlyMessage(for: error)
                }
            }
        }
    }

    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Could not log out. Please try again."
        }
    }

    // Turns Firebase's technical errors into messages a normal user understands.
    // We compare against Firebase's numeric error codes. These numbers are stable
    // across Firebase SDK versions (the enum names changed between versions).
    static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case 17008:                 // invalid email
            return "That email address is not valid."
        case 17007:                 // email already in use
            return "An account with this email already exists."
        case 17026:                 // weak password
            return "Password is too weak. Use at least 6 characters."
        case 17009, 17004, 17011:   // wrong password / invalid credential / user not found
            return "Incorrect email or password."
        case 17020:                 // network error
            return "Network error. Check your internet connection."
        case 17010:                 // too many requests
            return "Too many attempts. Please wait and try again."
        default:
            return error.localizedDescription
        }
    }
}
