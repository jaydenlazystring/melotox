import SwiftUI

struct UsernameSetupView: View {
    @ObservedObject var viewModel: UsernameSetupViewModel

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "at.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "A78BFA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Choose your username")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("This is how others will find you on Melotox.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.horizontal, 32)
                }

                // MARK: - Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("@")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: "A78BFA"))

                        TextField("", text: $viewModel.username, prompt: Text("username").foregroundColor(.white.opacity(0.3)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundStyle(.white)
                            .font(.title3)

                        statusIcon
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(hex: "1A1A2E"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: 1.5)
                    )

                    statusMessage
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 32)

                Spacer()

                // MARK: - Continue
                MelotoxButton(title: viewModel.isSubmitting ? "Setting up…" : "Continue", action: viewModel.submit, style: .primary)
                    .disabled(!viewModel.canSubmit)
                    .opacity(viewModel.canSubmit ? 1.0 : 0.5)
                    .padding(.horizontal, 32)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                }

                Spacer().frame(height: 20)
            }
        }
    }

    // MARK: - Status UI

    @ViewBuilder
    private var statusIcon: some View {
        switch viewModel.state {
        case .checking:
            ProgressView()
                .tint(Color(hex: "A78BFA"))
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .invalid, .taken:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.8))
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.state {
        case .available:
            Text("Available")
                .font(.caption)
                .foregroundStyle(.green)
        case .invalid(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red.opacity(0.8))
        case .taken:
            Text("That username is taken")
                .font(.caption)
                .foregroundStyle(.red.opacity(0.8))
        case .checking, .idle:
            Text("Letters, numbers and _ · \(UsernameValidator.minLength)–\(UsernameValidator.maxLength) chars")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.35))
        }
    }

    private var borderColor: Color {
        switch viewModel.state {
        case .available: return .green.opacity(0.6)
        case .invalid, .taken: return .red.opacity(0.5)
        default: return Color(hex: "7C3AED").opacity(0.3)
        }
    }
}
