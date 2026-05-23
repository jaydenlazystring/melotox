import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    var onBack: () -> Void

    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.body)
                        .foregroundStyle(Color(hex: "A78BFA"))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Avatar
                        VStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color(hex: "7C3AED"))

                            Text(viewModel.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text(viewModel.email)
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(.top, 24)

                        // MARK: - Info Cards
                        VStack(spacing: 0) {
                            profileRow(
                                icon: "person.fill",
                                label: "Account",
                                value: viewModel.providerName
                            )
                            Divider().background(Color.white.opacity(0.1))
                            profileRow(
                                icon: "calendar",
                                label: "Joined",
                                value: viewModel.joinedDate
                            )
                        }
                        .background(Color(hex: "1A1A2E"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        // MARK: - Logout
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundStyle(.red.opacity(0.8))
                                Text("Sign Out")
                                    .foregroundStyle(.red.opacity(0.8))
                                Spacer()
                            }
                            .font(.body)
                            .fontWeight(.medium)
                            .padding(16)
                            .background(Color(hex: "1A1A2E"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)

                        // MARK: - App Version
                        Text("Melotox v1.0.0")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.3))
                            .padding(.top, 20)
                    }
                }
            }
        }
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("You'll need to sign in again.")
        }
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color(hex: "A78BFA"))
                .frame(width: 28)

            Text(label)
                .font(.body)
                .foregroundStyle(.white)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
