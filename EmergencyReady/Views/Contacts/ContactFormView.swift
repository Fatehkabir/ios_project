import SwiftUI

// One form used for BOTH "Add contact" and "Edit contact".
// contactToEdit == nil  -> add mode.   contactToEdit != nil -> edit mode.
struct ContactFormView: View {
    @EnvironmentObject var firestore: FirestoreService

    let contactToEdit: EmergencyContact?

    // Binding to the parent's showForm. Setting it to false closes this sheet.
    @Binding var isPresented: Bool

    @State private var name: String
    @State private var phone: String
    @State private var relationship: String
    @State private var didTrySave = false   // errors only appear after the first Save tap

    private let relationshipSuggestions = [
        "Family", "Friend", "Doctor", "Neighbour", "Colleague", "Police", "Ambulance", "Fire Service"
    ]

    // Fill the fields with the existing contact's values (or empty strings when adding).
    init(contactToEdit: EmergencyContact?, isPresented: Binding<Bool>) {
        self.contactToEdit = contactToEdit
        self._isPresented = isPresented
        _name = State(initialValue: contactToEdit?.name ?? "")
        _phone = State(initialValue: contactToEdit?.phone ?? "")
        _relationship = State(initialValue: contactToEdit?.relationship ?? "")
    }

    // MARK: - Validation messages (nil = field is fine)

    private var nameError: String? {
        guard didTrySave else { return nil }
        return name.trimmingCharacters(in: .whitespaces).isEmpty ? "Please enter a name." : nil
    }

    private var phoneError: String? {
        guard didTrySave else { return nil }
        return Validation.isValidPhone(phone) ? nil : "Enter a valid phone number (3-15 digits, may start with +)."
    }

    private var relationshipError: String? {
        guard didTrySave else { return nil }
        return relationship.trimmingCharacters(in: .whitespaces).isEmpty ? "Please enter a relationship or contact type." : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    if let nameError = nameError {
                        Text(nameError).foregroundColor(Theme.red)
                    }
                }

                Section {
                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Phone")
                } footer: {
                    if let phoneError = phoneError {
                        Text(phoneError).foregroundColor(Theme.red)
                    }
                }

                Section {
                    TextField("e.g. Family, Doctor", text: $relationship)
                        .textInputAutocapitalization(.words)

                    // Quick-pick buttons: tapping one fills the text field above.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(relationshipSuggestions, id: \.self) { suggestion in
                                Button {
                                    relationship = suggestion
                                } label: {
                                    Text(suggestion)
                                        .font(.footnote.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .foregroundColor(relationship == suggestion ? .white : Theme.navy)
                                        .background(relationship == suggestion ? Theme.orange : Color.gray.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                } header: {
                    Text("Relationship / Type")
                } footer: {
                    if let relationshipError = relationshipError {
                        Text(relationshipError).foregroundColor(Theme.red)
                    }
                }
            }
            .navigationTitle(contactToEdit == nil ? "Add Contact" : "Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        didTrySave = true

        // Stop here if anything is wrong: the red messages are now visible.
        if nameError != nil || phoneError != nil || relationshipError != nil { return }

        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let cleanPhone = phone.trimmingCharacters(in: .whitespaces)
        let cleanRelationship = relationship.trimmingCharacters(in: .whitespaces)

        if var existing = contactToEdit {
            // UPDATE an existing contact
            existing.name = cleanName
            existing.phone = cleanPhone
            existing.relationship = cleanRelationship
            firestore.updateContact(existing)
        } else {
            // CREATE a new contact
            let newContact = EmergencyContact(name: cleanName,
                                              phone: cleanPhone,
                                              relationship: cleanRelationship)
            firestore.addContact(newContact)
        }
        isPresented = false   // close the sheet
    }
}
