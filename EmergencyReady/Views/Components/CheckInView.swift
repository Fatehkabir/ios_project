import SwiftUI
import CoreLocation

struct CheckInView: View {
    @EnvironmentObject var firestore: FirestoreService
    @ObservedObject var locationService = LocationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isMarkedSafe = false
    @State private var statusNote = "I am safe and currently in a secure location."
    @State private var showSuccessMessage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Badge
                    VStack(spacing: 12) {
                        Image(systemName: isMarkedSafe ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 64))
                            .foregroundColor(isMarkedSafe ? Theme.green : Theme.orange)

                        Text(isMarkedSafe ? "Marked as Safe" : "Safety Check-in")
                            .font(.title2.bold())
                            .foregroundColor(Theme.navy)

                        Text("Notify your emergency contacts of your safety status and optionally stream your location in real time.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 10)

                    // Note Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Status Message")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.navy)

                        TextField("Enter note for contacts", text: $statusNote)
                            .padding(12)
                            .background(Theme.background)
                            .cornerRadius(12)

                        Button {
                            markSafe()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("I'm Safe — Update Status")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                    .cardStyle()

                    // Live Location Sharing Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Live Location Sharing")
                                    .font(.headline)
                                    .foregroundColor(Theme.navy)
                                Text("Continuously streams your GPS location to Firestore for your trusted contacts to see.")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { locationService.isSharingLiveLocation },
                                set: { sharing in
                                    if sharing {
                                        locationService.startLiveSharing { loc in
                                            firestore.updateLiveLocation(
                                                latitude: loc.coordinate.latitude,
                                                longitude: loc.coordinate.longitude
                                            )
                                        }
                                    } else {
                                        locationService.stopLiveSharing()
                                        firestore.clearLiveLocation()
                                    }
                                }
                            ))
                            .labelsHidden()
                        }

                        if locationService.isSharingLiveLocation {
                            HStack {
                                Circle()
                                    .fill(Theme.green)
                                    .frame(width: 8, height: 8)
                                Text("Active — updating location automatically")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    if showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Your safety status has been broadcast.")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundColor(Theme.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.green.opacity(0.12))
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("I'm Safe Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func markSafe() {
        isMarkedSafe = true
        firestore.updateSafeStatus(isSafe: true, message: statusNote)
        withAnimation {
            showSuccessMessage = true
        }
    }
}
