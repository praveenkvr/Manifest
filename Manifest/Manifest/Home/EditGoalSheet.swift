//
//  EditGoalSheet.swift
//  Manifest
//
//  Edit or delete an existing goal — reached from GoalDetailView's "Edit" button.
//

import SwiftUI

struct EditGoalSheet: View {
    @Bindable var goal: Goal
    var language: String
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFocused: Bool
    @State private var text: String
    @State private var category: GoalCategory
    @State private var customCategoryLabel: String
    @State private var showDeleteConfirm = false

    init(goal: Goal, language: String, onDelete: @escaping () -> Void) {
        self.goal = goal
        self.language = language
        self.onDelete = onDelete
        _text = State(initialValue: goal.text)
        _category = State(initialValue: goal.category)
        _customCategoryLabel = State(initialValue: goal.customCategoryLabel ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Edit manifestation")
                    .font(.newsreader(29))
                    .foregroundStyle(.textPrimary)

                TextEditor(text: $text)
                    .focused($isTextFocused)
                    .font(.newsreader(20))
                    .foregroundStyle(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(height: 120)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                CategoryPicker(category: $category, customLabel: $customCategoryLabel, language: language)

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete manifestation")
                        .font(.manropeBold(15))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                PrimaryButton(title: "Save changes", isEnabled: isValid) {
                    goal.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    goal.category = category
                    goal.customCategoryLabel = category == .custom
                        ? customCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    dismiss()
                }
            }
            .padding(24)
            .background(Color.appBackground.ignoresSafeArea())
            .contentShape(Rectangle())
            .onTapGesture { isTextFocused = false }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete this manifestation?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private var isValid: Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if category == .custom {
            return !customCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
}

#Preview {
    EditGoalSheet(goal: Goal(text: "Launch my ceramics studio", category: .career), language: "en") {}
}
