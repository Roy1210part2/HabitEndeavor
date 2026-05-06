import Foundation

struct Country: Identifiable, Hashable {
    let id: String          // ISO 3166-1 alpha-2
    let name: String
    let price: Int
    let flag: String
    let continent: Continent

    enum Continent: String, CaseIterable {
        case asia        = "아시아"
        case europe      = "유럽"
        case northAmerica = "북아메리카"
        case southAmerica = "남아메리카"
        case africa      = "아프리카"
        case oceania     = "오세아니아"
    }
}

let allCountries: [Country] = [
    // MARK: - 아시아
    Country(id: "KR", name: "대한민국",       price:   100_000, flag: "🇰🇷", continent: .asia),
    Country(id: "JP", name: "일본",           price:   250_000, flag: "🇯🇵", continent: .asia),
    Country(id: "CN", name: "중국",           price:   800_000, flag: "🇨🇳", continent: .asia),
    Country(id: "IN", name: "인도",           price:   500_000, flag: "🇮🇳", continent: .asia),
    Country(id: "TH", name: "태국",           price:    30_000, flag: "🇹🇭", continent: .asia),
    Country(id: "VN", name: "베트남",         price:    20_000, flag: "🇻🇳", continent: .asia),
    Country(id: "SG", name: "싱가포르",       price:    80_000, flag: "🇸🇬", continent: .asia),
    Country(id: "MY", name: "말레이시아",     price:    25_000, flag: "🇲🇾", continent: .asia),
    Country(id: "ID", name: "인도네시아",     price:    60_000, flag: "🇮🇩", continent: .asia),
    Country(id: "PH", name: "필리핀",         price:    20_000, flag: "🇵🇭", continent: .asia),
    Country(id: "MN", name: "몽골",           price:     5_000, flag: "🇲🇳", continent: .asia),
    Country(id: "NP", name: "네팔",           price:     3_000, flag: "🇳🇵", continent: .asia),
    Country(id: "BT", name: "부탄",           price:     2_000, flag: "🇧🇹", continent: .asia),
    Country(id: "MV", name: "몰디브",         price:     3_500, flag: "🇲🇻", continent: .asia),
    Country(id: "SA", name: "사우디아라비아", price:   300_000, flag: "🇸🇦", continent: .asia),
    Country(id: "AE", name: "아랍에미리트",   price:   150_000, flag: "🇦🇪", continent: .asia),
    Country(id: "IL", name: "이스라엘",       price:    90_000, flag: "🇮🇱", continent: .asia),
    Country(id: "TR", name: "튀르키예",       price:    70_000, flag: "🇹🇷", continent: .asia),

    // MARK: - 유럽
    Country(id: "DE", name: "독일",           price:   600_000, flag: "🇩🇪", continent: .europe),
    Country(id: "FR", name: "프랑스",         price:   450_000, flag: "🇫🇷", continent: .europe),
    Country(id: "GB", name: "영국",           price:   500_000, flag: "🇬🇧", continent: .europe),
    Country(id: "IT", name: "이탈리아",       price:   350_000, flag: "🇮🇹", continent: .europe),
    Country(id: "ES", name: "스페인",         price:   280_000, flag: "🇪🇸", continent: .europe),
    Country(id: "NL", name: "네덜란드",       price:   300_000, flag: "🇳🇱", continent: .europe),
    Country(id: "CH", name: "스위스",         price:   400_000, flag: "🇨🇭", continent: .europe),
    Country(id: "SE", name: "스웨덴",         price:   200_000, flag: "🇸🇪", continent: .europe),
    Country(id: "NO", name: "노르웨이",       price:   220_000, flag: "🇳🇴", continent: .europe),
    Country(id: "IS", name: "아이슬란드",     price:     5_000, flag: "🇮🇸", continent: .europe),
    Country(id: "LU", name: "룩셈부르크",     price:    50_000, flag: "🇱🇺", continent: .europe),
    Country(id: "MC", name: "모나코",         price:    10_000, flag: "🇲🇨", continent: .europe),
    Country(id: "SM", name: "산마리노",       price:     1_500, flag: "🇸🇲", continent: .europe),
    Country(id: "VA", name: "바티칸",         price:       500, flag: "🇻🇦", continent: .europe),
    Country(id: "LI", name: "리히텐슈타인",   price:     2_000, flag: "🇱🇮", continent: .europe),

    // MARK: - 북아메리카
    Country(id: "US", name: "미국",           price: 1_000_000, flag: "🇺🇸", continent: .northAmerica),
    Country(id: "CA", name: "캐나다",         price:   400_000, flag: "🇨🇦", continent: .northAmerica),
    Country(id: "MX", name: "멕시코",         price:    80_000, flag: "🇲🇽", continent: .northAmerica),
    Country(id: "CU", name: "쿠바",           price:     5_000, flag: "🇨🇺", continent: .northAmerica),
    Country(id: "JM", name: "자메이카",       price:     3_000, flag: "🇯🇲", continent: .northAmerica),

    // MARK: - 남아메리카
    Country(id: "BR", name: "브라질",         price:   300_000, flag: "🇧🇷", continent: .southAmerica),
    Country(id: "AR", name: "아르헨티나",     price:    80_000, flag: "🇦🇷", continent: .southAmerica),
    Country(id: "CL", name: "칠레",           price:    60_000, flag: "🇨🇱", continent: .southAmerica),
    Country(id: "CO", name: "콜롬비아",       price:    50_000, flag: "🇨🇴", continent: .southAmerica),
    Country(id: "PE", name: "페루",           price:    40_000, flag: "🇵🇪", continent: .southAmerica),
    Country(id: "BO", name: "볼리비아",       price:    15_000, flag: "🇧🇴", continent: .southAmerica),

    // MARK: - 아프리카
    Country(id: "NG", name: "나이지리아",             price:  60_000, flag: "🇳🇬", continent: .africa),
    Country(id: "ZA", name: "남아프리카공화국",       price:  80_000, flag: "🇿🇦", continent: .africa),
    Country(id: "EG", name: "이집트",                 price:  50_000, flag: "🇪🇬", continent: .africa),
    Country(id: "KE", name: "케냐",                   price:  15_000, flag: "🇰🇪", continent: .africa),
    Country(id: "ET", name: "에티오피아",             price:  10_000, flag: "🇪🇹", continent: .africa),
    Country(id: "GH", name: "가나",                   price:  12_000, flag: "🇬🇭", continent: .africa),
    Country(id: "SC", name: "세이셸",                 price:   2_000, flag: "🇸🇨", continent: .africa),

    // MARK: - 오세아니아
    Country(id: "AU", name: "호주",           price:   350_000, flag: "🇦🇺", continent: .oceania),
    Country(id: "NZ", name: "뉴질랜드",       price:   100_000, flag: "🇳🇿", continent: .oceania),
    Country(id: "FJ", name: "피지",           price:     3_000, flag: "🇫🇯", continent: .oceania),
    Country(id: "TV", name: "투발루",         price:     1_000, flag: "🇹🇻", continent: .oceania),
    Country(id: "PW", name: "팔라우",         price:     1_500, flag: "🇵🇼", continent: .oceania),
    Country(id: "NR", name: "나우루",         price:       800, flag: "🇳🇷", continent: .oceania),
]
