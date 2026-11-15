import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var data: EmergencyDataService
    @EnvironmentObject var auth: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddGuideSheet = false
    @State private var showingAddTipSheet = false
    @State private var editingGuide: EmergencyGuide? = nil
    @State private var editingTip: SafetyTip? = nil
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
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddGuideSheet) {
                AdminEditGuideView(guideToEdit: nil)
            }
            .sheet(item: $editingGuide) { guide in
                AdminEditGuideView(guideToEdit: guide)
            }
            .sheet(isPresented: $showingAddTipSheet) {
                AdminEditTipView(tipToEdit: nil)
            }
            .sheet(item: $editingTip) { tip in
                AdminEditTipView(tipToEdit: tip)
            }
        }
    }

    // MARK: - Guides Management List
    private var guidesManagementList: some View {
        List {
            Section(header: Text("Tap a guide to Edit • Swipe left to Delete").font(.caption)) {
                ForEach(data.guides) { guide in
                    Button {
                        editingGuide = guide
                    } label: {
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
                            Image(systemName: "pencil.circle")
                                .font(.title3)
                                .foregroundColor(Theme.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let guide = data.guides[index]
                        data.deleteGuide(withId: guide.id)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Tips Management List
    private var tipsManagementList: some View {
        List {
            Section(header: Text("Tap a tip to Edit • Swipe left to Delete").font(.caption)) {
                ForEach(data.tips) { tip in
                    Button {
                        editingTip = tip
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: tip.iconName)
                                .foregroundColor(data.color(forCategory: tip.categoryId))
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.text)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.navy)
                                    .multilineTextAlignment(.leading)
                                Text(data.category(withId: tip.categoryId)?.title ?? tip.categoryId)
                                    .font(.caption.bold())
                                    .foregroundColor(data.color(forCategory: tip.categoryId))
                            }
                            Spacer()
                            Image(systemName: "pencil.circle")
                                .font(.title3)
                                .foregroundColor(Theme.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let tip = data.tips[index]
                        data.deleteTip(withId: tip.id)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Add / Edit Guide Sheet
struct AdminEditGuideView: View {
    @EnvironmentObject var data: EmergencyDataService
    @Environment(\.dismiss) private var dismiss

    let guideToEdit: EmergencyGuide?

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategoryId = "fire"
    @State private var stepsText = ""
    @State private var thingsToDoText = ""
    @State private var thingsToAvoidText = ""
    @State private var sourceName = "Official Safety Advisory"
    @State private var sourceURL = "https://www.ready.gov"

    var isEditing: Bool { guideToEdit != nil }

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

                Section("Action Steps (one per line)") {
                    TextEditor(text: $stepsText)
                        .frame(minHeight: 90)
                }

                Section("What to Do (one per line)") {
                    TextEditor(text: $thingsToDoText)
                        .frame(minHeight: 70)
                }

                Section("What to Avoid (one per line)") {
                    TextEditor(text: $thingsToAvoidText)
                        .frame(minHeight: 70)
                }

                Section("Official Source") {
                    TextField("Source Name", text: $sourceName)
                    TextField("Source URL", text: $sourceURL)
                        .keyboardType(.URL)
                }

                if isEditing, let g = guideToEdit {
                    Section {
                        Button(role: .destructive) {
                            data.deleteGuide(withId: g.id)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Guide", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Guide" : "Add Emergency Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGuide()
                    }
                    .fontWeight(.bold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let guide = guideToEdit {
                    title = guide.title
                    description = guide.description
                    selectedCategoryId = guide.categoryId
                    stepsText = guide.steps.joined(separator: "\n")
                    thingsToDoText = guide.thingsToDo.joined(separator: "\n")
                    thingsToAvoidText = guide.thingsToAvoid.joined(separator: "\n")
                    sourceName = guide.sourceName
                    sourceURL = guide.sourceURL
                }
            }
        }
    }

    private func saveGuide() {
        let steps = stepsText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let dos = thingsToDoText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let donts = thingsToAvoidText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let guideId = guideToEdit?.id ?? UUID().uuidString

        let guide = EmergencyGuide(
            id: guideId,
            categoryId: selectedCategoryId,
            title: title,
            description: description,
            iconName: guideToEdit?.iconName ?? "exclamationmark.triangle.fill",
            imageName: guideToEdit?.imageName ?? "",
            steps: steps.isEmpty ? ["Stay alert and follow official local broadcast orders."] : steps,
            thingsToDo: dos.isEmpty ? ["Remain calm", "Call emergency services if required"] : dos,
            thingsToAvoid: donts.isEmpty ? ["Do not panic", "Do not spread rumors"] : donts,
            keywords: [title.lowercased(), selectedCategoryId],
            sourceName: sourceName.isEmpty ? "Official Safety Advisory" : sourceName,
            sourceURL: sourceURL.isEmpty ? "https://www.ready.gov" : sourceURL
        )

        if isEditing {
            data.updateGuide(guide)
        } else {
            data.addGuide(guide)
        }
        dismiss()
    }
}

// MARK: - Add / Edit Tip Sheet
struct AdminEditTipView: View {
    @EnvironmentObject var data: EmergencyDataService
    @Environment(\.dismiss) private var dismiss

    let tipToEdit: SafetyTip?

    @State private var tipText = ""
    @State private var selectedCategoryId = "fire"
    @State private var iconName = "lightbulb.fill"

    var isEditing: Bool { tipToEdit != nil }

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

                if isEditing, let t = tipToEdit {
                    Section {
                        Button(role: .destructive) {
                            data.deleteTip(withId: t.id)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Tip", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Safety Tip" : "Add Safety Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTip()
                    }
                    .fontWeight(.bold)
                    .disabled(tipText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let tip = tipToEdit {
                    tipText = tip.text
                    selectedCategoryId = tip.categoryId
                    iconName = tip.iconName
                }
            }
        }
    }

    private func saveTip() {
        let tipId = tipToEdit?.id ?? UUID().uuidString
        let tip = SafetyTip(
            id: tipId,
            categoryId: selectedCategoryId,
            text: tipText,
            iconName: iconName
        )
        if isEditing {
            data.updateTip(tip)
        } else {
            data.addTip(tip)
        }
        dismiss()
    }
}
