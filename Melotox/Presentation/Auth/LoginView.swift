import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // MARK: - Logo Area
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "A78BFA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("MELOTOX")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .tracking(4)

                    Text("Your digital detox companion")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Spacer()

                // MARK: - Auth Buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { _ in
                        // Request handled by ASAuthorizationController
                    } onCompletion: { _ in
                        viewModel.signInWithApple()
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Sign in with Google
                    Button(action: viewModel.signInWithGoogle) {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)

                            Text("Sign in with Google")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color(hex: "0D0D0D"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)

                // MARK: - Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // MARK: - Loading
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "A78BFA"))
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }
}

#Preview {
    LoginView(
        viewModel: LoginViewModel(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(
                authRepository: PreviewAuthRepository()
            ),
            signInWithAppleUseCase: SignInWithAppleUseCase(
                authRepository: PreviewAuthRepository()
            )
        )
    )
}

// MARK: - Preview Helper

private struct PreviewAuthRepository: AuthRepository {
    func signInWithGoogle() async throws -> User {
        User(id: UUID().uuidString, provider: .google, email: "test@test.com", displayName: "Test", username: "test", createdAt: Date())
    }

    func signInWithApple() async throws -> User {
        User(id: UUID().uuidString, provider: .apple, email: "test@test.com", displayName: "Test", username: "test", createdAt: Date())
    }

    func restoreSession() async throws -> User? { nil }
    func signOut() async throws {}
}
