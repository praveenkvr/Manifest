//
//  CategoryPicker.swift
//  Manifest
//
//  Category chip row shared by Goal Capture (onboarding) and Add Goal (Home)
//  — includes "Custom" with an inline text field for the user's own label.
//

import SwiftUI

struct CategoryPicker: View {
    @Binding var category: GoalCategory
    @Binding var customLabel: String
    var language: String
    @FocusState private var isCustomFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GoalCategory.allCases, id: \.self) { option in
                        let isSelected = category == option
                        Text(option.label(language: language))
                            .font(.manrope(15, weight: .medium))
                            .foregroundStyle(isSelected ? .ink900 : .textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.accent50 : Color.appSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.slate300.opacity(0.4), lineWidth: 1))
                            .onTapGesture {
                                category = option
                                if option == .custom { isCustomFocused = true }
                            }
                    }
                }
            }

            if category == .custom {
                TextField("Name your own category", text: $customLabel)
                    .focused($isCustomFocused)
                    .font(.manrope(15))
                    .foregroundStyle(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.accent300, lineWidth: 1.5))
            }
        }
    }
}

#Preview {
    @Previewable @State var category: GoalCategory = .custom
    @Previewable @State var customLabel = ""
    return CategoryPicker(category: $category, customLabel: $customLabel, language: "en")
        .padding(24)
        .background(Color.appBackground)
}
