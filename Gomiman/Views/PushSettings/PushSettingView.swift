import SwiftUI

public struct PushSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GarbageViewModel.self) private var viewModel

    @State private var collectionDayBefore: Bool = true
    @State private var selectedTimeDayBefore: Int = 1
    @State private var collectionDayAfter: Bool = false
    @State private var selectedTimeDayAfter: Int = 0

    private let timesBefore = ["19:00", "20:00", "21:00", "22:00", "23:00"]
    private let timesAfter = ["05:00", "06:00", "07:00", "08:00", "09:00"]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section 1: 前日通知
                VStack(spacing: 16) {
                    HStack {
                        Text("収集日の前日通知")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.defaultTheme)

                        Spacer()

                        Toggle("", isOn: $collectionDayBefore)
                            .labelsHidden()
                            .tint(.defaultTheme)
                    }

                    if collectionDayBefore {
                        HStack(spacing: 8) {
                            ForEach(0..<timesBefore.count, id: \.self) { index in
                                SelectablePillView(
                                    title: timesBefore[index],
                                    isSelected: selectedTimeDayBefore == index,
                                    height: 36,
                                    fontSize: 13
                                ) {
                                    selectedTimeDayBefore = index
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Divider()
                    .background(Color.customDivider)

                // Section 2: 当日通知
                VStack(spacing: 16) {
                    HStack {
                        Text("収集日の当日通知")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.defaultTheme)

                        Spacer()

                        Toggle("", isOn: $collectionDayAfter)
                            .labelsHidden()
                            .tint(.defaultTheme)
                    }

                    if collectionDayAfter {
                        HStack(spacing: 8) {
                            ForEach(0..<timesAfter.count, id: \.self) { index in
                                SelectablePillView(
                                    title: timesAfter[index],
                                    isSelected: selectedTimeDayAfter == index,
                                    height: 36,
                                    fontSize: 13
                                ) {
                                    selectedTimeDayAfter = index
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.white)
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .foregroundColor(.defaultTheme)
                .font(.system(size: 15, weight: .bold))
            }
        }
        .task {
            let setting = viewModel.pushSetting
            collectionDayBefore = setting.collectionDayBefore
            selectedTimeDayBefore = setting.selectedTimeDayBefore
            collectionDayAfter = setting.collectionDayAfter
            selectedTimeDayAfter = setting.selectedTimeDayAfter

            // Explicitly request push permission and register for remote notifications ONLY on entering this screen
            _ = await FCMManager.shared.requestPushPermissionAndRegister()
        }
    }

    private func save() {
        let updated = PushSettingModel(
            collectionDayBefore: collectionDayBefore,
            selectedTimeDayBefore: selectedTimeDayBefore,
            collectionDayAfter: collectionDayAfter,
            selectedTimeDayAfter: selectedTimeDayAfter
        )
        viewModel.updatePushSetting(updated)
        dismiss()
    }
}
