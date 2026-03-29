import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var onManageApps: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Greeting
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

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "7C3AED"))
                    }
                    .padding(.top, 20)

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

                    // MARK: - Status Toggle Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Protection Status")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(viewModel.isRestrictionActive ? "Active" : "Inactive")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        viewModel.isRestrictionActive
                                            ? Color(hex: "A78BFA")
                                            : Color.white.opacity(0.4)
                                    )
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { viewModel.isRestrictionActive },
                                set: { _ in viewModel.toggleRestriction() }
                            ))
                            .tint(Color(hex: "7C3AED"))
                            .labelsHidden()
                        }
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
        onManageApps: {}
    )
}

// MARK: - Preview Helper

private struct PreviewRestrictionRepository: RestrictionRepository {
    func saveProfile(_ profile: AppRestrictionProfile) async throws {}
    func loadProfile() async throws -> AppRestrictionProfile? { nil }
    func applyRestrictions(for tokens: [String]) async throws {}
    func removeRestrictions() async throws {}
}
