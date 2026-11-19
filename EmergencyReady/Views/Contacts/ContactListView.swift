import SwiftUI

struct ContactListView: View {
    @EnvironmentObject var firestore: FirestoreService

    @State private var showingAddSheet = false
    @State private var contactToEdit: EmergencyContact? = nil

    var body: some View {
        List {
            // National Official Helplines (Instant 999 & 1090)
            Section {
                ForEach(EmergencyNumbers.nationalList) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.iconName)
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Theme.orange)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(Theme.navy)
                            Text(item.description)
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Spacer()

                        Button {
                            callNumber(item.number)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                Text(item.number)
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("National Emergency Helplines")
            }

            // Personal Emergency Contacts (Family, Doctors, Neighbors)
            Section {
                if firestore.contacts.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No personal contacts added yet")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        Text("Add trusted relatives, neighbors, or doctors to call quickly during an emergency.")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(firestore.contacts) { contact in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.navy)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(contact.name)
                                        .font(.headline)
                                        .foregroundColor(Theme.navy)
                                    if !contact.relationship.isEmpty {
                                        Text("(\(contact.relationship))")
                                            .font(.caption)
                                            .foregroundColor(Theme.orange)
                                    }
                                }
                                Text(contact.phone)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            // Direct Call Button
                            Button {
                                callNumber(contact.phone)
                            } label: {
                                Image(systemName: "phone.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Theme.green)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Call \(contact.name)")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            contactToEdit = contact
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            firestore.deleteContact(id: firestore.contacts[index].id)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("My Emergency Contacts (\(firestore.contacts.count))")
                    Spacer()
                    Text("Tap to edit • Swipe to delete")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .navigationTitle("Emergency Contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Theme.orange)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ContactFormView(contactToEdit: nil)
        }
        .sheet(item: $contactToEdit) { contact in
            ContactFormView(contactToEdit: contact)
        }
    }

    private func callNumber(_ raw: String) {
        let clean = raw.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(clean)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                print("Direct calling simulated: tel://\(clean)")
            }
        }
    }
}
