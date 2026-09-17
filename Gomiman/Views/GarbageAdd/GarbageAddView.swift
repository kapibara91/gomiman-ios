import SwiftUI

public struct GarbageAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GarbageViewModel.self) private var viewModel

    @State private var weekStatus: Int = GarbageCollectionModel.weekStatusEveryWeek
    @State private var selectedWeeks: Set<Int> = []
    @State private var selectedDays: Set<Int> = []
    @State private var selectedTypes: Set<Int> = []

    @State private var validationError: String? = nil
    @State private var showingAlert = false
    @State private var isSaving = false

    public init() {}

    private let daysMeta: [(id: Int, kanji: String, en: String)] = [
        (1, "月", "Mon"),
        (2, "火", "Tue"),
        (3, "水", "Wed"),
        (4, "木", "Thu"),
        (5, "金", "Fri"),
        (6, "土", "Sat"),
        (7, "日", "Sun")
    ]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Section 1: 収集日
                    Text("収集日")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.defaultTheme)

                    // Frequency selector
                    HStack(spacing: 12) {
                        SelectablePillView(
                            title: "毎週",
                            isSelected: weekStatus == GarbageCollectionModel.weekStatusEveryWeek,
                            width: 76,
                            height: 36
                        ) {
                            weekStatus = GarbageCollectionModel.weekStatusEveryWeek
                        }

                        SelectablePillView(
                            title: "隔週",
                            isSelected: weekStatus == GarbageCollectionModel.weekStatusBiweekly,
                            width: 76,
                            height: 36
                        ) {
                            weekStatus = GarbageCollectionModel.weekStatusBiweekly
                        }
                    }

                    // Bi-weekly weeks selection
                    if weekStatus == GarbageCollectionModel.weekStatusBiweekly {
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { weekNum in
                                let isSelected = selectedWeeks.contains(weekNum)
                                SelectablePillView(
                                    title: "第\(weekNum)週",
                                    isSelected: isSelected,
                                    height: 32,
                                    fontSize: 13
                                ) {
                                    if isSelected {
                                        selectedWeeks.remove(weekNum)
                                    } else {
                                        selectedWeeks.insert(weekNum)
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Days of week
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(daysMeta.prefix(4), id: \.id) { item in
                                let isSelected = selectedDays.contains(item.id)
                                SelectablePillView(
                                    title: item.kanji,
                                    subtitle: item.en,
                                    isSelected: isSelected,
                                    height: 48,
                                    fontSize: 16
                                ) {
                                    toggleDay(item.id)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(daysMeta.dropFirst(4), id: \.id) { item in
                                let isSelected = selectedDays.contains(item.id)
                                SelectablePillView(
                                    title: item.kanji,
                                    subtitle: item.en,
                                    isSelected: isSelected,
                                    height: 48,
                                    fontSize: 16
                                ) {
                                    toggleDay(item.id)
                                }
                            }
                            Spacer()
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // MARK: - Section 2: ゴミの種類
                    Text("ゴミの種類")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.defaultTheme)

                    VStack(spacing: 12) {
                        let allTypes = GarbageType.allTypes
                        let rows = [
                            Array(allTypes.prefix(3)),
                            Array(allTypes.dropFirst(3).prefix(3)),
                            Array(allTypes.dropFirst(6))
                        ]

                        ForEach(0..<rows.count, id: \.self) { rowIndex in
                            HStack(spacing: 10) {
                                ForEach(rows[rowIndex]) { garbageType in
                                    let isSelected = selectedTypes.contains(garbageType.id)
                                    SelectablePillView(
                                        title: garbageType.shortName,
                                        isSelected: isSelected,
                                        width: 95,
                                        height: 38,
                                        fontSize: 15
                                    ) {
                                        if isSelected {
                                            selectedTypes.remove(garbageType.id)
                                        } else {
                                            selectedTypes.insert(garbageType.id)
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.white)
            .navigationTitle("収集日の追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(isSaving ? .defaultTheme.opacity(0.5) : .defaultTheme)
                    .font(.system(size: 15))
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { save() }) {
                        if isSaving {
                            ProgressView()
                                .tint(.defaultTheme)
                        } else {
                            Text("保存")
                                .foregroundColor(.defaultTheme)
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("入力内容の確認", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationError ?? "")
            }
        }
    }

    private func toggleDay(_ id: Int) {
        if selectedDays.contains(id) {
            selectedDays.remove(id)
        } else {
            selectedDays.insert(id)
        }
    }

    private func save() {
        if isSaving { return }
        if weekStatus == GarbageCollectionModel.weekStatusBiweekly && selectedWeeks.isEmpty {
            validationError = "週を選択してください"
            showingAlert = true
            return
        }
        if selectedDays.isEmpty {
            validationError = "曜日を選択してください"
            showingAlert = true
            return
        }
        if selectedTypes.isEmpty {
            validationError = "ゴミの種類を選択してください"
            showingAlert = true
            return
        }

        isSaving = true
        let model = GarbageCollectionModel(
            weekStatus: weekStatus,
            weeks: selectedWeeks.sorted(),
            garbageTypes: selectedTypes.sorted(),
            days: selectedDays.sorted()
        )

        viewModel.addGarbageCollection(model)
        dismiss()
    }
}
