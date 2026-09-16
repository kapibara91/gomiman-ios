import SwiftUI

public struct GarbageListView: View {
    @Environment(GarbageViewModel.self) private var viewModel
    @State private var showingAddSheet = false
    @State private var showingPushSettings = false
    @State private var scheduleToDelete: GarbageCollectionModel? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.garbageModels.isEmpty {
                    Spacer()
                    emptyGarbageView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.garbageModels) { model in
                                GarbageScheduleCardView(
                                    model: model,
                                    onDelete: { scheduleToDelete = model }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }

                BannerAdPlaceholderView(adUnitId: AdConstants.getCollectionBannerUnitId())
                    .padding(.vertical, 4)
            }
            .background(Color.white)
            .navigationTitle("ゴミマン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.garbageModels.isEmpty {
                        Button("通知設定") {
                            showingPushSettings = true
                        }
                        .foregroundColor(.defaultTheme)
                        .font(.system(size: 15))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        showingAddSheet = true
                    }
                    .foregroundColor(.defaultTheme)
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                GarbageAddView()
            }
            .navigationDestination(isPresented: $showingPushSettings) {
                PushSettingView()
            }
            .confirmationDialog(
                "収集日の削除",
                isPresented: Binding(
                    get: { scheduleToDelete != nil },
                    set: { if !$0 { scheduleToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("削除する", role: .destructive) {
                    if let id = scheduleToDelete?.id {
                        viewModel.deleteGarbageCollection(id: id)
                    }
                    scheduleToDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    scheduleToDelete = nil
                }
            } message: {
                Text("この収集設定を削除しますか？")
            }
        }
    }

    private var emptyGarbageView: some View {
        VStack(spacing: 24) {
            Image("garbage_date_empty")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)

            Text("登録されている収集日はありません")
                .font(.system(size: 18))
                .foregroundColor(.defaultTheme)
        }
        .padding(.top, 40)
    }
}

// MARK: - Schedule Card View

private struct GarbageScheduleCardView: View {
    let model: GarbageCollectionModel
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DateUtils.formatScheduleSummary(model))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.defaultTheme)

                Spacer()

                Button(action: onDelete) {
                    Text("削除")
                        .font(.system(size: 14))
                        .foregroundColor(.defaultTheme)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                ForEach(model.garbageTypes, id: \.self) { typeId in
                    if let type = GarbageType.from(id: typeId) {
                        GarbageTypeBadgeView(title: type.shortName, size: 45, fontSize: 13)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.defaultTheme, lineWidth: 1)
        )
    }
}
