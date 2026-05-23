import SwiftUI

struct AboutView: View {
    var onBack: () -> Void

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
                    VStack(spacing: 32) {
                        // MARK: - Logo & Tagline
                        VStack(spacing: 14) {
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
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .tracking(3)

                            Text("A mindful pause before you scroll")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.5))
                                .italic()
                        }
                        .padding(.top, 24)

                        // MARK: - What is Melotox
                        storyCard(
                            title: "What is Melotox?",
                            body: "\"Melody\" + \"Detox\" \u{2014} a digital detox through melody. Instead of blocking apps, Melotox transforms the moment of impulse into a short, immersive experience."
                        )

                        // MARK: - Why Melotox
                        storyCard(
                            title: "Why Melotox?",
                            body: "We don't \"block\" apps \u{2014} we create a moment to \"pause.\" The 1-minute rhythm interaction isn't a punishment. It's a bridge to a more conscious choice."
                        )

                        // MARK: - Links
                        VStack(spacing: 0) {
                            linkRow(icon: "lock.shield", label: "Privacy Policy", url: "https://melotox.com/privacy")
                            Divider().background(Color.white.opacity(0.1))
                            linkRow(icon: "doc.text", label: "Terms of Service", url: "https://melotox.com/terms")
                            Divider().background(Color.white.opacity(0.1))
                            linkRow(icon: "envelope", label: "Contact Us", url: "mailto:hello@melotox.com")
                        }
                        .background(Color(hex: "1A1A2E"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // MARK: - Footer
                        VStack(spacing: 6) {
                            Text("v1.0.0")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.3))

                            Text("Made in Seoul")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.25))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Story Card

    private func storyCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(hex: "A78BFA"))

            Text(body)
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.7))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "1A1A2E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Link Row

    private func linkRow(icon: String, label: String, url: String) -> some View {
        Button {
            if let linkURL = URL(string: url) {
                UIApplication.shared.open(linkURL)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color(hex: "A78BFA"))
                    .frame(width: 28)

                Text(label)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
