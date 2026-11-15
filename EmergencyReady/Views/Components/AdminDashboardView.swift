import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var data: EmergencyDataService
    @EnvironmentObject var auth: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddGuideSheet = false
    @State private var showingAddTipSheet = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Admin Banner
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Admin Control Center")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Logged in as: \(auth.userEmail)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.orange)
                }
                .padding()
                .background(Theme.navy)

                // Mode Picker
                Picker("Admin Mode", selection: $selectedTab) {
                    Text("Emergency Guides (\(data.guides.count))").tag(0)
                    Text("Safety Tips (\(data.tips.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    guidesManagementList
                } else {
                    tipsManagementList
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if selectedTab == 0 {
                            showingAddGuideSheet = true
                        } else {
                            showingAddTipSheet = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddGuideSheet) {
                AdminAddGuideView()
            }
            .sheet(isPresented: $showingAddTipSheet) {
                AdminAddTipView()
            }
        }
    }

    // MARK: - Guides Management
    private var guidesManagementList: some View {
        List {
            ForEach(data.guides) { guide in
                HStack(spacing: 12) {
                    IconBadge(
                        imageName: nil,
                        symbolName: guide.iconName,
                        color: data.color(forCategory: guide.categoryId),
                        size: 40
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(guide.title)
                            .font(.headline)
                            .foregroundColor(Theme.navy)
                        Text(data.category(withId: guide.categoryId)?.title ?? guide.categoryId)
                            .font(.caption.bold())
                            .foregroundColor(data.color(forCategory: guide.categoryId))
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let guide = data.guides[index]
                    data.deleteGuide(withId: guide.id)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Tips Management
    private var tipsManagementList: some View {
        List {
            ForEach(data.tips) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.iconName)
                        .foregroundColor(data.color(forCategory: tip.categoryId))
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.text)
                            .font(.subheadline)
                            .foregroundColor(Theme.navy)
                        Text(data.category(withId: tip.categoryId)?.title ?? tip.categoryId)
                            .font(.caption2.bold())
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let tip = data.tips[index]
                    data.deleteTip(withId: tip.id)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Add Guide Sheet
struct AdminAddGuideView: View {
    @EnvironmentObject var data: EmergencyDataService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategoryId = "fire"
    @State private var stepsText = ""
    @State private var sourceName = "Official Safety Advisory"
    @State private var sourceURL = "https://www.ready.gov"

    var body: some View {
        NavigationStack {
            Form {
                Section("Guide Details") {
                    TextField("Title (e.g. Chemical Spill)", text: $title)
                    TextField("Summary description", text: $description)

                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(data.categories) { cat in
                            Text(cat.title).tag(cat.id)
                        }
                    }
                }

                Section("Instructions (one per line)") {
                    TextEditor(text: $stepsText)
                        .frame(minHeight: 100)
                }

                Section("Official Source") {
                    TextField("Source Name", text: $sourceName)
                    TextField("Source URL", text: $sourceURL)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("Add Emergency Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let steps = stepsText
                            .components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        let newGuide = EmergencyGuide(
                            id: UUID().uuidString,
                            categoryId: selectedCategoryId,
                            title: title,
                            description: description,
                            iconName: "exclamationmark.triangle.fill",
                            imageName: "",
                            steps: steps.isEmpty ? ["Stay alert and follow official local broadcast orders."] : steps,
                            thingsToDo: ["Remain calm", "Call emergency services if required"],
                            thingsToAvoid: ["Do not panic", "Do not spread unverified rumors"],
                            keywords: [title.lowercased(), selectedCategoryId],
                            sourceName: sourceName,
                            sourceURL: sourceURL
                        )
                        data.addGuide(newGuide)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Tip Sheet
struct AdminAddTipView: View {
    @EnvironmentObject var data: EmergencyDataService
    @Environment(\.dismiss) private var dismiss

    @State private var tipText = ""
    @State private var selectedCategoryId = "fire"
    @State private var iconName = "lightbulb.fill"

    var body: some View {
        NavigationStack {
            Form {
                Section("Tip Content") {
                    TextField("Enter safety tip...", text: $tipText)

                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(data.categories) { cat in
                            Text(cat.title).tag(cat.id)
                        }
                    }
                }
            }
            .navigationTitle("Add Safety Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newTip = SafetyTip(
                            id: UUID().uuidString,
                            categoryId: selectedCategoryId,
                            text: tipText,
                            iconName: iconName
                        )
                        data.addTip(newTip)
                        dismiss()
                    }
                    .disabled(tipText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
