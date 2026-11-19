import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var disasterService: DisasterAlertService
    @EnvironmentObject var auth: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss

    @State private var showingCreateSheet = false
    @State private var alertToEdit: DisasterAlert? = nil

    var body: some View {
        NavigationStack {
            List {
                // Admin Banner
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.title2)
                                .foregroundColor(Theme.orange)
                            Text("Disaster Alert Manager")
                                .font(.headline)
                                .foregroundColor(Theme.navy)
                        }
                        Text("Logged in as Administrator: \(auth.userEmail)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text("Alerts published here are broadcast to users in the selected region and cached offline on their devices.")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.vertical, 4)
                }

                // Active Disasters Section
                Section(header: Text("Broadcasted Alerts (\(disasterService.alerts.count))")) {
                    if disasterService.alerts.isEmpty {
                        Text("No active disaster alerts. Tap '+ Create Alert' to issue a regional advisory.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(disasterService.alerts) { alert in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(alert.region.uppercased())
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.navy.opacity(0.1))
                                        .cornerRadius(4)
                                        .foregroundColor(Theme.navy)

                                    Text(alert.severity.uppercased())
                                        .font(.caption2.bold())
                                        .foregroundColor(alert.severity.lowercased() == "extreme" || alert.severity.lowercased() == "severe" ? Theme.red : Theme.orange)

                                    Spacer()

                                    // Active / Inactive status
                                    Button {
                                        disasterService.toggleAlertStatus(alert)
                                    } label: {
                                        Text(alert.isActive ? "ACTIVE" : "PAUSED")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(alert.isActive ? Theme.green.opacity(0.15) : Color.gray.opacity(0.2))
                                            .foregroundColor(alert.isActive ? Theme.green : Color.gray)
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(alert.title)
                                    .font(.headline)
                                    .foregroundColor(Theme.navy)

                                if !alert.description.isEmpty {
                                    Text(alert.description)
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                        .lineLimit(2)
                                }

                                HStack {
                                    Text("Expires: \(alert.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    Button("Edit") {
                                        alertToEdit = alert
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let alert = disasterService.alerts[index]
                                disasterService.deleteAlert(id: alert.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Alert")
                        }
                        .fontWeight(.bold)
                        .foregroundColor(Theme.orange)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                AdminCreateAlertView(alertToEdit: nil)
            }
            .sheet(item: $alertToEdit) { alert in
                AdminCreateAlertView(alertToEdit: alert)
            }
        }
    }
}

// MARK: - Create / Edit Disaster Alert Sheet
struct AdminCreateAlertView: View {
    @EnvironmentObject var disasterService: DisasterAlertService
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var data: EmergencyDataService
    @Environment(\.dismiss) private var dismiss

    let alertToEdit: DisasterAlert?

    @State private var title = ""
    @State private var description = ""
    @State private var selectedRegion = "Dhaka"
    @State private var selectedCategory = "flood"
    @State private var selectedSeverity = "Severe"
    @State private var isActive = true
    @State private var expirationHours = 48

    var isEditing: Bool { alertToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Alert Information") {
                    TextField("Alert Title (e.g. Flash Flood Warning)", text: $title)
                    TextField("Public advisory & instructions", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Target Region") {
                    Picker("Target Region", selection: $selectedRegion) {
                        ForEach(AppRegions.list, id: \.self) { reg in
                            Text(reg).tag(reg)
                        }
                    }
                }

                Section("Emergency Category & Severity") {
                    Picker("Linked Emergency", selection: $selectedCategory) {
                        ForEach(data.categories) { cat in
                            Text(cat.title).tag(cat.id)
                        }
                    }

                    Picker("Severity Level", selection: $selectedSeverity) {
                        Text("Minor").tag("Minor")
                        Text("Moderate").tag("Moderate")
                        Text("Severe").tag("Severe")
                        Text("Extreme").tag("Extreme")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Alert Status & Expiration") {
                    Toggle("Active Broadcast", isOn: $isActive)

                    Stepper(value: $expirationHours, in: 6...168, step: 6) {
                        Text("Expires in: \(expirationHours) hours")
                    }
                }

                if isEditing, let alert = alertToEdit {
                    Section {
                        Button(role: .destructive) {
                            disasterService.deleteAlert(id: alert.id)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Alert", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Disaster Alert" : "New Disaster Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Broadcast") {
                        saveAlert()
                    }
                    .fontWeight(.bold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let alert = alertToEdit {
                    title = alert.title
                    description = alert.description
                    selectedRegion = alert.region
                    selectedCategory = alert.categoryId
                    selectedSeverity = alert.severity
                    isActive = alert.isActive
                    let diff = Int(alert.expiresAt.timeIntervalSince(Date()) / 3600)
                    expirationHours = max(6, diff)
                }
            }
        }
    }

    private func saveAlert() {
        let expiresAt = Date().addingTimeInterval(Double(expirationHours * 3600))

        if let existing = alertToEdit {
            var updated = existing
            updated.title = title
            updated.description = description
            updated.region = selectedRegion
            updated.categoryId = selectedCategory
            updated.severity = selectedSeverity
            updated.isActive = isActive
            updated.expiresAt = expiresAt
            disasterService.updateAlert(updated)
        } else {
            let newAlert = DisasterAlert(
                id: UUID().uuidString,
                title: title,
                description: description,
                region: selectedRegion,
                categoryId: selectedCategory,
                severity: selectedSeverity,
                isActive: isActive,
                createdAt: Date(),
                expiresAt: expiresAt,
                createdBy: auth.userEmail
            )
            disasterService.createAlert(newAlert)
        }
        dismiss()
    }
}
