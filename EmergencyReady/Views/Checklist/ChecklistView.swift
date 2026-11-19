import SwiftUI

struct ChecklistView: View {
    @EnvironmentObject var checklistService: ChecklistService

    @State private var showingAddItemAlert = false
    @State private var newItemTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            // Preparedness Progress Bar Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Preparedness Progress")
                            .font(.headline)
                            .foregroundColor(Theme.navy)
                        Text("\(checklistService.completedCount) of \(checklistService.items.count) supplies ready")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(checklistService.progressFraction * 100))%")
                        .font(.title2.bold())
                        .foregroundColor(checklistService.progressFraction == 1.0 ? Theme.green : Theme.orange)
                }

                ProgressView(value: checklistService.progressFraction)
                    .tint(checklistService.progressFraction == 1.0 ? Theme.green : Theme.orange)

                Text("Saved locally on device • Always available offline")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding()

            // Checklist Items
            List {
                Section(header: Text("Emergency Survival Kit")) {
                    ForEach(checklistService.items) { item in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                checklistService.toggleItem(item)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(item.isCompleted ? Theme.green : Theme.textSecondary)

                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundColor(item.isCompleted ? Theme.textSecondary : Theme.navy)
                                    .strikethrough(item.isCompleted, color: Theme.textSecondary)

                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: checklistService.deleteItem)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Prep Checklist")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newItemTitle = ""
                    showingAddItemAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Item")
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Theme.orange)
                }
            }
        }
        .alert("Add Checklist Item", isPresented: $showingAddItemAlert) {
            TextField("e.g. Extra blanket", text: $newItemTitle)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                checklistService.addItem(title: newItemTitle)
            }
        } message: {
            Text("Add a custom emergency supply to your checklist.")
        }
    }
}
