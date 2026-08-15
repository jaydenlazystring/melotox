import SwiftUI

struct AppSelectionView: View {
    @ObservedObject var viewModel: AppSelectionViewModel
    /// When set, shows a button that previews the block/intervention flow
    /// (useful in Simulator where real Screen Time restrictions can't run).
    var onPreviewBlock: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Select Apps")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Choose which apps require a mindful pause")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .padding(.vertical, 20)

                // MARK: - App List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "A78BFA"))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.availableApps) { app in
                                AppRow(app: app) {
                                    viewModel.toggleApp(token: app.token)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // MARK: - Error
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                // MARK: - Actions
                VStack(spacing: 10) {
                    if let onPreviewBlock {
                        MelotoxButton(title: "Preview Block Screen", action: onPreviewBlock, style: .secondary)
                    }
                    MelotoxButton(title: "Save", action: viewModel.saveSelection, style: .primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            viewModel.loadApps()
        }
    }
}

// MARK: - App Row

private struct AppRow: View {
    let app: SelectableApp
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "app.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: "A78BFA"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "1A1A2E"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(app.name)
                .font(.body)
                .foregroundStyle(.white)

            Spacer()

            Toggle("", isOn: Binding(
                get: { app.isSelected },
                set: { _ in onToggle() }
            ))
            .tint(Color(hex: "7C3AED"))
            .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}

#Preview {
    AppSelectionView(
        viewModel: {
            let vm = AppSelectionViewModel(
                selectRestrictedAppsUseCase: SelectRestrictedAppsUseCase(
                    restrictionRepository: PreviewRestrictionRepo()
                ),
                restrictionRepository: PreviewRestrictionRepo()
            )
            vm.availableApps = [
                SelectableApp(token: "com.instagram", name: "Instagram", isSelected: true),
                SelectableApp(token: "com.twitter", name: "X (Twitter)", isSelected: false),
                SelectableApp(token: "com.tiktok", name: "TikTok", isSelected: true),
            ]
            return vm
        }()
    )
}

private struct PreviewRestrictionRepo: RestrictionRepository {
    func saveProfile(_ profile: AppRestrictionProfile) async throws {}
    func loadProfile() async throws -> AppRestrictionProfile? { nil }
    func applyRestrictions(for tokens: [String]) async throws {}
    func removeRestrictions() async throws {}
}
