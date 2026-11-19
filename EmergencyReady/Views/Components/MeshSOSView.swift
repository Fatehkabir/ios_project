import SwiftUI

struct MeshSOSView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var meshService: MeshSOSService

    @State private var selectedStatus = "Trapped / Need Rescue"
    @State private var emergencyNote = ""
    @State private var showBroadcastConfig = false

    private let statusOptions = [
        "Trapped / Need Rescue",
        "Medical Emergency / Injured",
        "Safe but Stranded",
        "Need Drinking Water / Food",
        "Looking for Family Members"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card explaining offline mesh
                    meshExplanationCard

                    // SOS Beacon Broadcast Section
                    broadcastSection

                    // Nearby Detected SOS Beacons Section
                    nearbyBeaconsSection
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Offline SOS Mesh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Auto start scanning when entering the screen
                if !meshService.isScanning {
                    meshService.startScanning()
                }
            }
        }
    }

    // MARK: - Explanation Card
    private var meshExplanationCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 32))
                .foregroundColor(Theme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Peer-to-Peer Disaster Mesh")
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                Text("Broadcasts & scans for emergency signals via direct Wi-Fi and Bluetooth. Operates 100% without internet or cellular reception.")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Broadcast Section
    private var broadcastSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My SOS Beacon")
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                Spacer()
                if meshService.isAdvertising {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.danger)
                            .frame(width: 8, height: 8)
                        Text("Broadcasting")
                            .font(.caption.bold())
                            .foregroundColor(Theme.danger)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.danger.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            if meshService.isAdvertising, let beacon = meshService.myActiveBeacon {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.danger)
                        Text(beacon.emergencyStatus)
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.danger)
                    }
                    Text("Name: \(beacon.senderName) • \(beacon.region)")
                        .font(.footnote)
                        .foregroundColor(Theme.navy)

                    if !beacon.note.isEmpty {
                        Text("\"\(beacon.note)\"")
                            .font(.caption.italic())
                            .foregroundColor(Theme.textSecondary)
                    }

                    Button(action: {
                        meshService.stopBroadcasting()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Broadcasting Signal")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.danger)
                        .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Theme.danger.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.danger.opacity(0.3), lineWidth: 1))
            } else {
                VStack(spacing: 12) {
                    Text("Select your current emergency condition to broadcast to nearby rescuers:")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Emergency Status", selection: $selectedStatus) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.background)
                    .cornerRadius(8)

                    TextField("Optional short note (e.g. 2nd floor, 3 people)", text: $emergencyNote)
                        .font(.subheadline)
                        .padding(10)
                        .background(Theme.background)
                        .cornerRadius(8)

                    Button(action: {
                        meshService.startBroadcasting(
                            senderName: auth.displayName.isEmpty ? auth.username : auth.displayName,
                            region: auth.userRegion,
                            status: selectedStatus,
                            note: emergencyNote
                        )
                    }) {
                        HStack {
                            Image(systemName: "radiowaves.right")
                            Text("Start Broadcasting Emergency Beacon")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.danger)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
    }

    // MARK: - Nearby Beacons Section
    private var nearbyBeaconsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Nearby Detected Beacons")
                    .font(.headline)
                    .foregroundColor(Theme.navy)

                Spacer()

                Button(action: {
                    if meshService.isScanning {
                        meshService.stopScanning()
                    } else {
                        meshService.startScanning()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: meshService.isScanning ? "arrow.clockwise" : "play.fill")
                        Text(meshService.isScanning ? "Scanning..." : "Scan")
                    }
                    .font(.caption.bold())
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.primary.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            if meshService.detectedBeacons.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                    Text(meshService.isScanning ? "Listening for nearby offline emergency signals..." : "Scanner is paused.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Text("Devices within direct Wi-Fi/Bluetooth range (~30m-50m) broadcasting SOS will appear here automatically.")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.white)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(meshService.detectedBeacons) { beacon in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(Theme.danger)
                                Text(beacon.emergencyStatus)
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.danger)

                                Spacer()

                                Text(beacon.timeAgoString)
                                    .font(.caption2)
                                    .foregroundColor(Theme.textSecondary)
                            }

                            HStack {
                                Text("From: \(beacon.senderName)")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.navy)

                                Spacer()

                                Text("Region: \(beacon.region)")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }

                            if !beacon.note.isEmpty {
                                Text("\"\(beacon.note)\"")
                                    .font(.caption.italic())
                                    .foregroundColor(Theme.navy)
                                    .padding(8)
                                    .background(Theme.background)
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
    }
}
