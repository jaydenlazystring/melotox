import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var onManageApps: () -> Void
    var onProfileTap: () -> Void

    @State private var showDisableAlert = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Greeting + Profile
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(viewModel.userName)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Stay mindful today")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.5))
                        }

                        Spacer()

                        Button(action: onProfileTap) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color(hex: "7C3AED"))
                        }
                    }
                    .padding(.top, 20)

                    // MARK: - Protection Status (TOP)
                    HStack(spacing: 14) {
                        Image(systemName: viewModel.isRestrictionActive ? "shield.checkered" : "shield.slash")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.isRestrictionActive
                                    ? Color(hex: "A78BFA")
                                    : Color.white.opacity(0.3)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Protection")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text(viewModel.isRestrictionActive ? "Active" : "Off")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    viewModel.isRestrictionActive
                                        ? Color(hex: "A78BFA")
                                        : Color.red.opacity(0.7)
                                )
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { viewModel.isRestrictionActive },
                            set: { newValue in
                                if !newValue {
                                    showDisableAlert = true
                                } else {
                                    viewModel.toggleRestriction()
                                }
                            }
                        ))
                        .tint(Color(hex: "7C3AED"))
                        .labelsHidden()
                    }
                    .padding(16)
                    .background(
                        viewModel.isRestrictionActive
                            ? Color(hex: "1A1A2E")
                            : Color(hex: "2A1515")
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                viewModel.isRestrictionActive
                                    ? Color(hex: "7C3AED").opacity(0.3)
                                    : Color.red.opacity(0.2),
                                lineWidth: 1
                            )
                    )

                    // MARK: - Restricted Apps Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "A78BFA"))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restricted Apps")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text("\(viewModel.restrictedAppsCount) apps managed")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }

                            Spacer()

                            Text("\(viewModel.restrictedAppsCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "C4B5FD"))
                        }

                        MelotoxButton(title: "Manage Apps", action: onManageApps, style: .secondary)
                    }
                    .padding(20)
                    .background(Color(hex: "1A1A2E"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // MARK: - Error
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .alert("Turn off protection?", isPresented: $showDisableAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Turn Off", role: .destructive) {
                viewModel.toggleRestriction()
            }
        } message: {
            Text("Your restricted apps won't require a mindful pause until you turn it back on.")
        }
    }
}

#Preview {
    HomeView(
        viewModel: {
            let vm = HomeViewModel(
                restrictionRepository: PreviewRestrictionRepository()
            )
            vm.userName = "Jayden"
            vm.restrictedAppsCount = 5
            vm.isRestrictionActive = true
            return vm
        }(),
        onManageApps: {},
        onProfileTap: {}
    )
}

private struct PreviewRestrictionRepository: RestrictionRepository {
    func saveProfile(_ profile: AppRestrictionProfile) async throws {}
    func loadProfile() async throws -> AppRestrictionProfile? { nil }
    func applyRestrictions(for tokens: [String]) async throws {}
    func removeRestrictions() async throws {}
}
