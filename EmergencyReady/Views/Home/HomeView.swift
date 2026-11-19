import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var data: EmergencyDataService
    @EnvironmentObject var disasterService: DisasterAlertService

    @Binding var selectedTab: Int

    @State private var randomTip: SafetyTip? = nil
    @State private var showLogoutConfirmation = false
    @State private var showAdminPanel = false
    @State private var showRegionSheet = false
    @State private var showProfileSheet = false

    private var dailyTip: SafetyTip? {
        if data.tips.isEmpty { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return data.tips[day % data.tips.count]
    }

    private var shownTip: SafetyTip? {
        randomTip ?? dailyTip
    }

    private var localAlerts: [DisasterAlert] {
        disasterService.activeAlerts(forRegion: auth.userRegion)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView

                VStack(alignment: .leading, spacing: 20) {
                    // 1. Regional Disaster Alert Banner (Offline-cached)
                    regionalAlertsSection

                    // 2. SOS Emergency Call Button
                    SOSButton(number: auth.emergencyNumber)

                    // 3. Search Bar
                    searchBar

                    // 4. Offline / Last Sync Status
                    syncStatusSection

                    // 5. Daily Safety Tip
                    tipSection

                    // 6. Emergency Categories Grid
                    categorySection
                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Log out of EmergencyReady?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) { auth.logout() }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showAdminPanel) {
            AdminDashboardView()
        }
        .sheet(isPresented: $showRegionSheet) {
            RegionSettingsSheet()
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello,")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Text(auth.displayName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Button {
                    showRegionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                        Text("Region: \(auth.userRegion)")
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption.bold())
                    .foregroundColor(Theme.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(6)
                }
                .padding(.top, 2)
            }
            Spacer()

            Menu {
                Text(auth.userEmail)

                Button {
                    showProfileSheet = true
                } label: {
                    Label("My Profile & Security", systemImage: "person.text.rectangle")
                }

                Button {
                    showRegionSheet = true
                } label: {
                    Label("Change Region / SOS Number", systemImage: "gearshape")
                }

                if auth.isAdmin {
                    Button {
                        showAdminPanel = true
                    } label: {
                        Label("Admin Disaster Manager", systemImage: "lock.shield.fill")
                    }
                }

                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                if !auth.profileImageBase64.isEmpty,
                   let data = Data(base64Encoded: auth.profileImageBase64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.orange, lineWidth: 1.5))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Account menu")
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.navy.ignoresSafeArea(edges: .top))
    }

    // MARK: - Regional Alerts
    private var regionalAlertsSection: some View {
        Group {
            if !localAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(Theme.red)
                        Text("ACTIVE REGIONAL WARNINGS")
                            .font(.caption.bold())
                            .foregroundColor(Theme.red)
                        Spacer()
                    }

                    ForEach(localAlerts) { alert in
                        RegionalAlertBanner(alert: alert) { _ in
                            selectedTab = 1
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search emergency procedures, keywords")
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(Theme.textSecondary)
            .padding(14)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search emergency instructions")
    }

    // MARK: - Sync Status
    private var syncStatusSection: some View {
        HStack(spacing: 6) {
            Image(systemName: disasterService.errorMessage != nil ? "wifi.slash" : "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)

            if let syncTime = disasterService.lastSyncTime {
                Text("Alerts synced: \(syncTime.formatted(date: .omitted, time: .shortened)) (Cached offline)")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            } else {
                Text("Offline mode active • Guides loaded from local storage")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Safety Tip
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Safety Tip")
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                Spacer()
                NavigationLink {
                    SafetyTipsView()
                } label: {
                    Text("All tips")
                        .font(.caption.bold())
                        .foregroundColor(Theme.orange)
                }
            }

            if let tip = shownTip {
                TipCard(
                    tip: tip,
                    categoryTitle: data.category(withId: tip.categoryId)?.title ?? "Safety",
                    color: data.color(forCategory: tip.categoryId)
                )
                .id(tip.id)
                .transition(.opacity)
            }

            Button {
                showRandomTip()
            } label: {
                Label("Randomize recommendation", systemImage: "shuffle")
                    .font(.caption.bold())
                    .foregroundColor(Theme.navy)
            }
        }
    }

    // MARK: - Categories Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Emergency Categories")
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                Spacer()
                Button {
                    selectedTab = 1
                } label: {
                    Text("See all guides")
                        .font(.caption.bold())
                        .foregroundColor(Theme.orange)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.categories) { category in
                        NavigationLink {
                            GuideListView(category: category)
                        } label: {
                            CategoryCard(category: category)
                                .frame(width: 165)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func showRandomTip() {
        if data.tips.isEmpty { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            randomTip = data.tips.randomElement()
        }
    }
}

// MARK: - Region & SOS Settings Sheet
struct RegionSettingsSheet: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRegion = ""
    @State private var customSOS = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Region") {
                    Picker("Selected Region", selection: $selectedRegion) {
                        ForEach(AppRegions.list, id: \.self) { region in
                            Text(region).tag(region)
                        }
                    }
                }

                Section("Emergency SOS Number") {
                    TextField("Emergency Dial Number", text: $customSOS)
                        .keyboardType(.phonePad)

                    HStack {
                        Button("Set 999 (National)") { customSOS = "999" }
                            .buttonStyle(.borderless)
                        Spacer()
                        Button("Set 1090 (Disaster)") { customSOS = "1090" }
                            .buttonStyle(.borderless)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Location & SOS Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        auth.updateRegion(selectedRegion)
                        auth.updateEmergencyNumber(customSOS.isEmpty ? "999" : customSOS)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                selectedRegion = auth.userRegion
                customSOS = auth.emergencyNumber
            }
        }
    }
}
