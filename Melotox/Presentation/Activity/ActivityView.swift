import SwiftUI

struct ActivityView: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Activity")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Color(hex: "A78BFA"))
                        Spacer()
                    } else {
                        // MARK: - Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ], spacing: 14) {
                            StatCard(
                                icon: "lock.open.fill",
                                label: "Today's Unlocks",
                                value: "\(viewModel.stats.todayUnlocks)",
                                color: Color(hex: "7C3AED")
                            )

                            StatCard(
                                icon: "flame.fill",
                                label: "Streak",
                                value: "\(viewModel.stats.currentStreak) day\(viewModel.stats.currentStreak == 1 ? "" : "s")",
                                color: Color(hex: "F59E0B")
                            )

                            StatCard(
                                icon: "checkmark.circle.fill",
                                label: "Total Sessions",
                                value: "\(viewModel.stats.totalSessions)",
                                color: Color(hex: "10B981")
                            )

                            StatCard(
                                icon: "hand.raised.fill",
                                label: "Declined",
                                value: "\(viewModel.stats.totalDeclined)",
                                color: Color(hex: "A78BFA")
                            )
                        }

                        // MARK: - Summary
                        if viewModel.stats.totalSessions == 0 && viewModel.stats.totalDeclined == 0 {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color(hex: "7C3AED").opacity(0.3))

                                Text("No activity yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.4))

                                Text("Complete your first mindful pause to see stats here")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.3))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        }
                    }

                    Spacer(minLength: 100) // space for tab bar
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            viewModel.loadStats()
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "1A1A2E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
