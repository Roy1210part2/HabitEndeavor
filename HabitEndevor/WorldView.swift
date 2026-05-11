import SwiftUI
import SwiftData

// TODO: 세계 지도 & 국가 구매 시스템 — 나중에 구체화 예정 (현재 비활성화)

struct WorldView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundStyle(Color.secondary)
            Text("세계 지도")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            Text("준비 중이에요")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("세계")
    }
}

/*
import SwiftUI
import SwiftData

struct WorldView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var allRecords: [HabitRecord]
    @Query private var purchases: [PurchasedCountry]
    @Query private var habits: [Habit]
    @Query private var completedQuests: [CompletedQuest]

    @State private var selectedContinent: Country.Continent? = nil
    @State private var purchaseTarget: Country? = nil
    @State private var searchText = ""
    @State private var showFullMap = false

    private var questCoins: Int { completedQuests.reduce(0) { $0 + $1.coinsAwarded } }

    private var balance: Int {
        CoinService.balance(records: allRecords, purchases: purchases, questCoins: questCoins)
    }

    private var ownedCodes: Set<String> {
        Set(purchases.map(\.countryCode))
    }

    private var displayedCountries: [Country] {
        allCountries
            .filter { selectedContinent == nil || $0.continent == selectedContinent }
            .filter { searchText.isEmpty || $0.name.localizedStandardContains(searchText) }
            .sorted { lhs, rhs in
                let lOwned = ownedCodes.contains(lhs.id)
                let rOwned = ownedCodes.contains(rhs.id)
                if lOwned != rOwned { return lOwned }   // 구매한 국가 위로
                return lhs.price < rhs.price
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 2D 세계지도 (구매 국가 영토 시각화)
                ZStack(alignment: .topTrailing) {
                    WorldMap2DView(ownedCodes: ownedCodes)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)

                    // 전체화면 버튼
                    Button { showFullMap = true } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }
                .sheet(isPresented: $showFullMap) {
                    NavigationStack {
                        WorldMap2DView(ownedCodes: ownedCodes)
                            .ignoresSafeArea()
                            .navigationTitle("세계 지도")
                            #if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("닫기") { showFullMap = false }
                                }
                            }
                    }
                    #if os(iOS)
                    .presentationDetents([.large])
                    #endif
                }

                coinBalanceCard
                progressCard
                continentFilter
                countryList
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("세계")
        .searchable(text: $searchText, prompt: "국가 검색")
        .sheet(item: $purchaseTarget) { country in
            CountryPurchaseSheet(
                country: country,
                balance: balance,
                isOwned: ownedCodes.contains(country.id),
                onPurchase: { purchase(country: country) }
            )
        }
    }

    // MARK: - 코인 잔액 카드

    private var coinBalanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("보유 코인")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text("\(balance.formatted()) C")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("총 획득")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text("\(totalEarned.formatted()) C")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .cardBackground()
    }

    // MARK: - 정복 진행도 카드 (내 아이디어: 전체 진행상황 한눈에)

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("세계 정복 현황")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(ownedCodes.count) / \(allCountries.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary)
                        .frame(
                            width: geo.size.width * CGFloat(ownedCodes.count) / CGFloat(max(allCountries.count, 1)),
                            height: 8
                        )
                        .animation(.spring(), value: ownedCodes.count)
                }
            }
            .frame(height: 8)

            // 대륙별 구매 개수
            HStack(spacing: 4) {
                ForEach(Country.Continent.allCases, id: \.self) { continent in
                    let ownedInContinent = allCountries
                        .filter { $0.continent == continent && ownedCodes.contains($0.id) }
                        .count
                    let totalInContinent = allCountries.filter { $0.continent == continent }.count

                    if ownedInContinent > 0 {
                        Text("\(continentEmoji(continent))\(ownedInContinent)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    let _ = totalInContinent  // suppress warning
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    // MARK: - 대륙 필터

    private var continentFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "전체", selected: selectedContinent == nil) {
                    selectedContinent = nil
                }
                ForEach(Country.Continent.allCases, id: \.self) { continent in
                    filterChip(
                        label: "\(continentEmoji(continent)) \(continent.rawValue)",
                        selected: selectedContinent == continent
                    ) {
                        selectedContinent = selectedContinent == continent ? nil : continent
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(selected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.primary : Color.primary.opacity(0.08))
                // Color.primary 배경 위에서 반전색 사용
                .foregroundStyle(selected
                    ? (colorScheme == .dark ? Color.black : Color.white)
                    : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 국가 리스트

    private var countryList: some View {
        VStack(spacing: 0) {
            ForEach(displayedCountries) { country in
                CountryRow(
                    country: country,
                    isOwned: ownedCodes.contains(country.id),
                    canAfford: balance >= country.price
                )
                .contentShape(Rectangle())
                .onTapGesture { purchaseTarget = country }

                if country.id != displayedCountries.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .cardBackground()
    }

    // MARK: - Helpers

    private var totalEarned: Int {
        allRecords.filter { $0.coinPaidAt != nil }.count * 1000
    }

    private func purchase(country: Country) {
        let record = PurchasedCountry(countryCode: country.id, pricePaid: country.price)
        modelContext.insert(record)
    }

    private func continentEmoji(_ continent: Country.Continent) -> String {
        switch continent {
        case .asia:         return "🌏"
        case .europe:       return "🌍"
        case .northAmerica: return "🌎"
        case .southAmerica: return "🌎"
        case .africa:       return "🌍"
        case .oceania:      return "🌏"
        }
    }
}

// MARK: - Country Row

struct CountryRow: View {
    let country: Country
    let isOwned: Bool
    let canAfford: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(country.continent.rawValue)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            if isOwned {
                Text("정복")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            } else {
                Text("\(country.price.formatted()) C")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(canAfford ? Color.primary : Color.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .opacity(isOwned ? 0.5 : 1.0)
    }
}

// MARK: - Purchase Sheet

struct CountryPurchaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let country: Country
    let balance: Int
    let isOwned: Bool
    let onPurchase: () -> Void

    private var canAfford: Bool { balance >= country.price }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(country.flag)
                    .font(.system(size: 72))

                VStack(spacing: 6) {
                    Text(country.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(country.continent.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("가격")
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("\(country.price.formatted()) C")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("보유 코인")
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("\(balance.formatted()) C")
                            .fontWeight(.semibold)
                            .foregroundStyle(canAfford ? Color.primary : Color.red)
                    }
                    if !isOwned && canAfford {
                        HStack {
                            Text("구매 후 잔액")
                                .foregroundStyle(Color.secondary)
                            Spacer()
                            Text("\((balance - country.price).formatted()) C")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                if isOwned {
                    Label("이미 정복한 국가", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button {
                        onPurchase()
                        dismiss()
                    } label: {
                        Text("정복하기 (\(country.price.formatted()) C)")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canAfford ? Color.primary : Color.secondary.opacity(0.3))
                            .foregroundStyle(canAfford
                        ? (colorScheme == .dark ? Color.black : Color.white)
                        : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!canAfford)

                    if !canAfford {
                        Text("코인이 \((country.price - balance).formatted())C 부족해요")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(24)
            .navigationTitle("국가 구매")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

#Preview {
    NavigationStack { WorldView() }
        .modelContainer(for: [HabitRecord.self, PurchasedCountry.self, Habit.self], inMemory: true)
}
*/
