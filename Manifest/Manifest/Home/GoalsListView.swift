//
//  GoalsListView.swift
//  Manifest
//
//  The "Goals" tab — every goal, active and fulfilled, in one place.
//  (Home's list is just the active shortlist; this is the full manager.)
//  Swipe left on any row to delete — tap into a goal for Edit.
//

import SwiftUI
import SwiftData

struct GoalsListView: View {
    var settings: AppSettings

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @State private var showAddGoal = false
    @State private var showPaywall = false

    private var isSubscribed: Bool { EntitlementStore.shared.isSubscribed }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    HStack {
                        Text("Goals").font(.newsreader(30)).foregroundStyle(.textPrimary)
                        Spacer()
                        Button {
                            if isSubscribed { showAddGoal = true } else { showPaywall = true }
                        } label: {
                            Image(systemName: isSubscribed ? "plus" : "sparkles")
                                .foregroundStyle(isSubscribed ? .accent500 : .gold500)
                        }
                    }
                    .padding(.top, 44)

                    if goals.isEmpty {
                        VStack(spacing: 10) {
                            LumenMascot(mood: .calm)
                            Text("No manifestations yet").font(.manrope(15)).foregroundStyle(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                ForEach(goals) { goal in
                    NavigationLink {
                        GoalDetailView(goal: goal, settings: settings)
                    } label: {
                        GoalRow(goal: goal, isLocked: goal.isPaused || !isSubscribed)
                            .opacity(goal.isFulfilled ? 0.6 : 1)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Analytics.track("goal_deleted", ["source": "goalsList"])
                            modelContext.delete(goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden)
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(settings: settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(settings: settings, source: "goalsList") { showPaywall = false }
        }
    }
}

#Preview {
    GoalsListView(settings: AppSettings())
        .modelContainer(for: Goal.self, inMemory: true)
}
