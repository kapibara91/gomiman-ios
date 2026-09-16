import SwiftUI

public struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var submissionSucceeded: Bool = false

    private let syncService = CloudRunSyncService.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("ご意見・ご要望の送信")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.defaultTheme)

            ZStack(alignment: .topLeading) {
                if feedbackText.isEmpty {
                    Text("アプリへのご意見・ご要望やお気づきの点をお聞かせください。")
                        .font(.system(size: 15))
                        .foregroundColor(.customTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $feedbackText)
                    .font(.system(size: 15))
                    .foregroundColor(.defaultTheme)
                    .padding(8)
                    .frame(height: 160)
                    .scrollContentBackground(.hidden)
            }
            .background(Color.white)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.defaultTheme, lineWidth: 1)
            )

            Button(action: { submit() }) {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSubmitting ? "送信中..." : "送信")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? Color.customInactiveGray : Color.defaultTheme)
                .cornerRadius(6)
            }
            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .background(Color.white)
        .navigationTitle("フィードバック")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if submissionSucceeded {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func submit() {
        guard !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isSubmitting else { return }
        isSubmitting = true

        Task {
            let result = await syncService.submitFeedback(message: feedbackText)
            isSubmitting = false

            switch result {
            case .success:
                alertTitle = "送信完了"
                alertMessage = "フィードバックを送信しました。ご協力ありがとうございます。"
                submissionSucceeded = true
            case .failure:
                alertTitle = "送信失敗"
                alertMessage = "送信に失敗しました。通信環境をご確認の上、再度お試しください。"
                submissionSucceeded = false
            }
            showingAlert = true
        }
    }
}
