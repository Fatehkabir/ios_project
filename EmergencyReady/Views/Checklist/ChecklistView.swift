import SwiftUI

// Emergency supplies checklist saved in Firestore.
struct ChecklistView: View {
    @EnvironmentObject var firestore: FirestoreService

    @State private var newItemTitle = ""
    @FocusState private var isTextFieldFocused: Bool

    // Values calculated from the array every time the screen redraws.
    private var totalCount: Int { firestore.checklistItems.count }
    private var completedCount: Int { firestore.checklistItems.filter { $0.isCompleted }.count }
    private var remainingCount: Int { totalCount - completedCount }
    private var progress: Double { totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount) }

    private var canAddItem: Bool {
        !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if firestore.isLoading && firestore.checklistItems.isEmpty {
                LoadingView(text: "Loading checklist...")
                Spacer()
            } else {
                summaryCard
                addItemRow

                if firestore.checklistItems.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "checklist",
                                       title: "Your checklist is empty",
                                       message: "Add the supplies you want to keep ready at home.")
                    }
                } else {
                    itemList
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Preparedness Checklist")
    }

    // MARK: - Pieces

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(Int(progress * 100))% prepared")
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                Spacer()
                Text("\(completedCount) done  •  \(remainingCount) remaining")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            // Progress bar: value goes from 0.0 to 1.0.
            ProgressView(value: progress)
                .tint(Theme.green)
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .padding(16)
        .cardStyle()
        .padding([.horizontal, .top])
    }

    private var addItemRow: some View {
        HStack(spacing: 10) {
            TextField("Add your own item", text: $newItemTitle)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit { addItem() }
                .padding(12)
                .background(Theme.card)
                .cornerRadius(12)

            Button {
                addItem()
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(canAddItem ? Theme.orange : Color.gray.opacity(0.4))
                    .clipShape(Circle())
            }
            .disabled(!canAddItem)
            .accessibilityLabel("Add checklist item")
        }
        .padding()
    }

    private var itemList: some View {
        List {
            // ForEach over the array: one row per checklist item.
            ForEach(firestore.checklistItems) { item in
                Button {
                    firestore.setItemCompleted(item, completed: !item.isCompleted)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(item.isCompleted ? Theme.green : Theme.textSecondary)
                            .scaleEffect(item.isCompleted ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: item.isCompleted)

                        Text(item.title)
                            .strikethrough(item.isCompleted)
                            .foregroundColor(item.isCompleted ? Theme.textSecondary : Theme.navy)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.title), \(item.isCompleted ? "completed" : "not completed")")
            }
            .onDelete(perform: deleteItems)   // swipe left to delete
        }
        .scrollContentBackground(.hidden)
        // Animation: rows slide in/out smoothly when items are added or removed.
        .animation(.default, value: firestore.checklistItems)
    }

    // MARK: - Actions

    private func addItem() {
        let title = newItemTitle.trimmingCharacters(in: .whitespaces)
        if title.isEmpty { return }
        firestore.addChecklistItem(title: String(title.prefix(100)))
        newItemTitle = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            firestore.deleteChecklistItem(firestore.checklistItems[index])
        }
    }
}
