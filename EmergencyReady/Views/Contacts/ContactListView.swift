import SwiftUI

// Emergency contacts: view, add, edit (tap a row), delete (swipe), call.
struct ContactListView: View {
    @EnvironmentObject var firestore: FirestoreService
    @Environment(\.openURL) private var openURL

    @State private var showForm = false
    @State private var contactToEdit: EmergencyContact? = nil   // nil = adding a new contact
    @State private var showCallError = false

    var body: some View {
        Group {
            if firestore.isLoading && firestore.contacts.isEmpty {
                LoadingView(text: "Loading contacts...")
            } else if firestore.contacts.isEmpty {
                ScrollView {
                    EmptyStateView(icon: "person.crop.circle.badge.plus",
                                   title: "No emergency contacts yet",
                                   message: "Add family, friends or doctors you may need to reach quickly.",
                                   actionTitle: "Add Contact") {
                        openForm(editing: nil)
                    }
                }
            } else {
                List {
                    ForEach(firestore.contacts) { contact in
                        contactRow(contact)
                    }
                    .onDelete(perform: deleteContacts)   // swipe left to delete
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Emergency Contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    openForm(editing: nil)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.orange)
                }
                .accessibilityLabel("Add contact")
            }
        }
        // $showForm is a Binding: the form can close itself by setting it to false.
        .sheet(isPresented: $showForm) {
            ContactFormView(contactToEdit: contactToEdit, isPresented: $showForm)
        }
        .alert("Cannot place call", isPresented: $showCallError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device cannot make phone calls. The iOS Simulator cannot call, so please test on a real iPhone.")
        }
    }

    // MARK: - Row

    private func contactRow(_ contact: EmergencyContact) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                Text(contact.relationship)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.orange)
                Text(contact.phone)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                openForm(editing: contact)   // tap the text to edit
            }

            // The call button. .borderless keeps it separate from the row's tap.
            Button {
                call(contact)
            } label: {
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Theme.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Call \(contact.name)")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func openForm(editing contact: EmergencyContact?) {
        contactToEdit = contact
        showForm = true
    }

    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            firestore.deleteContact(firestore.contacts[index])
        }
    }

    // Opens the phone app using the "tel://" URL scheme.
    private func call(_ contact: EmergencyContact) {
        let number = Validation.cleanedPhone(contact.phone)
        guard let url = URL(string: "tel://\(number)") else {
            showCallError = true
            return
        }
        openURL(url) { accepted in
            if !accepted { showCallError = true }
        }
    }
}
