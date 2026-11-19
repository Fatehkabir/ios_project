import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var data: EmergencyDataService
    @EnvironmentObject var disasterService: DisasterAlertService

    @Binding var selectedTab: Int

    @State private var randomTip: SafetyTip? = nil
    @State private var showLogoutConfirmation = false
    @State private var showAdminPanel = false
    @State private var showProfileSheet = false
    @State private var showMeshSOSSheet = false
    @State private var selectedRegionFilter = "All"

    private var dailyTip: SafetyTip? {
        if data.tips.isEmpty { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return data.tips[day % data.tips.count]
    }

    private var shownTip: SafetyTip? {
        randomTip ?? dailyTip
    }

    // Filter alerts by selected filter pill or show user's region & national
    private var filteredAlerts: [DisasterAlert] {
        if selectedRegionFilter == "All" {
            return disasterService.alerts.filter { !$0.isExpired }
        } else if selectedRegionFilter == "My Region" {
            return disasterService.activeAlerts(forRegion: auth.userRegion)
        } else {
            return disasterService.alerts.filter {
                !$0.isExpired && ($0.region.lowercased() == selectedRegionFilter.lowercased() || $0.region.lowercased() == "all" || $0.region.lowercased() == "national")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView

                VStack(alignment: .leading, spacing: 20) {
                    // 1. Regional Disaster Alert Banner & Explorer
                    regionalAlertsSection

                    // 2. SOS Emergency Call Button
                    SOSButton(number: auth.emergencyNumber)

                    // 2b. Offline Peer-to-Peer SOS Mesh Banner
                    meshSOSBanner

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
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
        .sheet(isPresented: $showMeshSOSSheet) {
            MeshSOSView()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello,")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Text(auth.displayName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Registered Region: \(auth.userRegion)")
                }
                .font(.caption2)
                .foregroundColor(Theme.orange)
            }
            Spacer()

            Menu {
                Text(auth.userEmail)

                Button {
                    showProfileSheet = true
                } label: {
                    Label("My Profile & Security", systemImage: "person.text.rectangle")
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
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.orange, lineWidth: 1.5))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 38))
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

    // MARK: - Regional Alerts & Region Filter Bar
    private var regionalAlertsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(Theme.red)
                Text("DISASTER ADVISORY RADAR")
                    .font(.caption.bold())
                    .foregroundColor(Theme.red)
                Spacer()
            }

            // Region Filter Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterPill(title: "My Region (\(auth.userRegion))", tag: "My Region")
                    filterPill(title: "All Regions", tag: "All")

                    ForEach(AppRegions.list, id: \.self) { reg in
                        if reg != auth.userRegion {
                            filterPill(title: reg, tag: reg)
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if filteredAlerts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(Theme.green)
                    Text("No active disaster advisories in \(selectedRegionFilter == "My Region" ? auth.userRegion : selectedRegionFilter).")
                        .font(.caption)
                        .foregroundColor(Theme.navy)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                ForEach(filteredAlerts) { alert in
                    RegionalAlertBanner(alert: alert) { _ in
                        selectedTab = 1
                    }
                }
            }
        }
    }

    private func filterPill(title: String, tag: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedRegionFilter = tag
            }
        } label: {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedRegionFilter == tag ? Theme.navy : Color.white)
                .foregroundColor(selectedRegionFilter == tag ? .white : Theme.navy)
                .cornerRadius(20)
                .overlay(
                    Capsule()
                        .stroke(selectedRegionFilter == tag ? Theme.navy : Theme.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Offline SOS Mesh Banner
    private var meshSOSBanner: some View {
        Button {
            showMeshSOSSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.danger.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.danger)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Offline Peer-to-Peer SOS Mesh")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.navy)
                        Spacer()
                        Text("NO CELL TOWER")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.orange.opacity(0.15))
                            .foregroundColor(Theme.orange)
                            .cornerRadius(4)
                    }

                    Text("Broadcast & scan for distress signals via direct Wi-Fi/Bluetooth")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.danger.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
