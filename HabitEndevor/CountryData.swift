import Foundation

struct Country: Identifiable, Hashable {
    let id: String          // ISO 3166-1 alpha-2
    let name: String
    let price: Int
    let flag: String
    let continent: Continent
    let coordinate: Coordinate

    struct Coordinate: Hashable {
        let lat: Double  // 위도 (-90 ~ 90)
        let lon: Double  // 경도 (-180 ~ 180)
    }

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
    Country(id: "KR", name: "대한민국",       price:   100_000, flag: "🇰🇷", continent: .asia,         coordinate: .init(lat: 36.5,  lon: 127.8)),
    Country(id: "JP", name: "일본",           price:   250_000, flag: "🇯🇵", continent: .asia,         coordinate: .init(lat: 36.2,  lon: 138.3)),
    Country(id: "CN", name: "중국",           price:   800_000, flag: "🇨🇳", continent: .asia,         coordinate: .init(lat: 35.9,  lon: 104.2)),
    Country(id: "IN", name: "인도",           price:   500_000, flag: "🇮🇳", continent: .asia,         coordinate: .init(lat: 20.6,  lon:  78.9)),
    Country(id: "TH", name: "태국",           price:    30_000, flag: "🇹🇭", continent: .asia,         coordinate: .init(lat: 15.9,  lon: 100.9)),
    Country(id: "VN", name: "베트남",         price:    20_000, flag: "🇻🇳", continent: .asia,         coordinate: .init(lat: 14.1,  lon: 108.3)),
    Country(id: "SG", name: "싱가포르",       price:    80_000, flag: "🇸🇬", continent: .asia,         coordinate: .init(lat:  1.4,  lon: 103.8)),
    Country(id: "MY", name: "말레이시아",     price:    25_000, flag: "🇲🇾", continent: .asia,         coordinate: .init(lat:  4.2,  lon: 108.0)),
    Country(id: "ID", name: "인도네시아",     price:    60_000, flag: "🇮🇩", continent: .asia,         coordinate: .init(lat: -0.8,  lon: 113.9)),
    Country(id: "PH", name: "필리핀",         price:    20_000, flag: "🇵🇭", continent: .asia,         coordinate: .init(lat: 12.9,  lon: 121.8)),
    Country(id: "MN", name: "몽골",           price:     5_000, flag: "🇲🇳", continent: .asia,         coordinate: .init(lat: 46.9,  lon: 103.8)),
    Country(id: "NP", name: "네팔",           price:     3_000, flag: "🇳🇵", continent: .asia,         coordinate: .init(lat: 28.4,  lon:  84.1)),
    Country(id: "BT", name: "부탄",           price:     2_000, flag: "🇧🇹", continent: .asia,         coordinate: .init(lat: 27.5,  lon:  90.4)),
    Country(id: "MV", name: "몰디브",         price:     3_500, flag: "🇲🇻", continent: .asia,         coordinate: .init(lat:  3.2,  lon:  73.2)),
    Country(id: "SA", name: "사우디아라비아", price:   300_000, flag: "🇸🇦", continent: .asia,         coordinate: .init(lat: 23.9,  lon:  45.1)),
    Country(id: "AE", name: "아랍에미리트",   price:   150_000, flag: "🇦🇪", continent: .asia,         coordinate: .init(lat: 23.4,  lon:  53.8)),
    Country(id: "IL", name: "이스라엘",       price:    90_000, flag: "🇮🇱", continent: .asia,         coordinate: .init(lat: 31.0,  lon:  34.9)),
    Country(id: "TR", name: "튀르키예",       price:    70_000, flag: "🇹🇷", continent: .asia,         coordinate: .init(lat: 38.4,  lon:  35.2)),

    // MARK: - 유럽
    Country(id: "DE", name: "독일",           price:   600_000, flag: "🇩🇪", continent: .europe,       coordinate: .init(lat: 51.2,  lon:  10.4)),
    Country(id: "FR", name: "프랑스",         price:   450_000, flag: "🇫🇷", continent: .europe,       coordinate: .init(lat: 46.2,  lon:   2.2)),
    Country(id: "GB", name: "영국",           price:   500_000, flag: "🇬🇧", continent: .europe,       coordinate: .init(lat: 55.4,  lon:  -3.4)),
    Country(id: "IT", name: "이탈리아",       price:   350_000, flag: "🇮🇹", continent: .europe,       coordinate: .init(lat: 42.8,  lon:  12.8)),
    Country(id: "ES", name: "스페인",         price:   280_000, flag: "🇪🇸", continent: .europe,       coordinate: .init(lat: 40.5,  lon:  -3.7)),
    Country(id: "NL", name: "네덜란드",       price:   300_000, flag: "🇳🇱", continent: .europe,       coordinate: .init(lat: 52.1,  lon:   5.3)),
    Country(id: "CH", name: "스위스",         price:   400_000, flag: "🇨🇭", continent: .europe,       coordinate: .init(lat: 46.8,  lon:   8.2)),
    Country(id: "SE", name: "스웨덴",         price:   200_000, flag: "🇸🇪", continent: .europe,       coordinate: .init(lat: 60.1,  lon:  18.6)),
    Country(id: "NO", name: "노르웨이",       price:   220_000, flag: "🇳🇴", continent: .europe,       coordinate: .init(lat: 65.5,  lon:  17.0)),
    Country(id: "IS", name: "아이슬란드",     price:     5_000, flag: "🇮🇸", continent: .europe,       coordinate: .init(lat: 64.6,  lon: -18.0)),
    Country(id: "LU", name: "룩셈부르크",     price:    50_000, flag: "🇱🇺", continent: .europe,       coordinate: .init(lat: 49.8,  lon:   6.1)),
    Country(id: "MC", name: "모나코",         price:    10_000, flag: "🇲🇨", continent: .europe,       coordinate: .init(lat: 43.7,  lon:   7.4)),
    Country(id: "SM", name: "산마리노",       price:     1_500, flag: "🇸🇲", continent: .europe,       coordinate: .init(lat: 43.9,  lon:  12.5)),
    Country(id: "VA", name: "바티칸",         price:       500, flag: "🇻🇦", continent: .europe,       coordinate: .init(lat: 41.9,  lon:  12.5)),
    Country(id: "LI", name: "리히텐슈타인",   price:     2_000, flag: "🇱🇮", continent: .europe,       coordinate: .init(lat: 47.2,  lon:   9.6)),

    // MARK: - 북아메리카
    Country(id: "US", name: "미국",           price: 1_000_000, flag: "🇺🇸", continent: .northAmerica, coordinate: .init(lat: 37.1,  lon: -95.7)),
    Country(id: "CA", name: "캐나다",         price:   400_000, flag: "🇨🇦", continent: .northAmerica, coordinate: .init(lat: 56.1,  lon:-106.3)),
    Country(id: "MX", name: "멕시코",         price:    80_000, flag: "🇲🇽", continent: .northAmerica, coordinate: .init(lat: 23.6,  lon:-102.6)),
    Country(id: "CU", name: "쿠바",           price:     5_000, flag: "🇨🇺", continent: .northAmerica, coordinate: .init(lat: 21.5,  lon: -79.5)),
    Country(id: "JM", name: "자메이카",       price:     3_000, flag: "🇯🇲", continent: .northAmerica, coordinate: .init(lat: 18.1,  lon: -77.3)),

    // MARK: - 남아메리카
    Country(id: "BR", name: "브라질",         price:   300_000, flag: "🇧🇷", continent: .southAmerica, coordinate: .init(lat:-14.2,  lon: -51.9)),
    Country(id: "AR", name: "아르헨티나",     price:    80_000, flag: "🇦🇷", continent: .southAmerica, coordinate: .init(lat:-38.4,  lon: -63.6)),
    Country(id: "CL", name: "칠레",           price:    60_000, flag: "🇨🇱", continent: .southAmerica, coordinate: .init(lat:-35.7,  lon: -71.5)),
    Country(id: "CO", name: "콜롬비아",       price:    50_000, flag: "🇨🇴", continent: .southAmerica, coordinate: .init(lat:  4.6,  lon: -74.1)),
    Country(id: "PE", name: "페루",           price:    40_000, flag: "🇵🇪", continent: .southAmerica, coordinate: .init(lat: -9.2,  lon: -75.0)),
    Country(id: "BO", name: "볼리비아",       price:    15_000, flag: "🇧🇴", continent: .southAmerica, coordinate: .init(lat:-16.3,  lon: -63.6)),

    // MARK: - 아프리카
    Country(id: "NG", name: "나이지리아",             price:  60_000, flag: "🇳🇬", continent: .africa,   coordinate: .init(lat:  9.1,  lon:   8.7)),
    Country(id: "ZA", name: "남아프리카공화국",       price:  80_000, flag: "🇿🇦", continent: .africa,   coordinate: .init(lat:-30.6,  lon:  22.9)),
    Country(id: "EG", name: "이집트",                 price:  50_000, flag: "🇪🇬", continent: .africa,   coordinate: .init(lat: 26.8,  lon:  30.8)),
    Country(id: "KE", name: "케냐",                   price:  15_000, flag: "🇰🇪", continent: .africa,   coordinate: .init(lat:  0.0,  lon:  37.9)),
    Country(id: "ET", name: "에티오피아",             price:  10_000, flag: "🇪🇹", continent: .africa,   coordinate: .init(lat:  9.1,  lon:  40.5)),
    Country(id: "GH", name: "가나",                   price:  12_000, flag: "🇬🇭", continent: .africa,   coordinate: .init(lat:  7.9,  lon:  -1.0)),
    Country(id: "SC", name: "세이셸",                 price:   2_000, flag: "🇸🇨", continent: .africa,   coordinate: .init(lat: -4.7,  lon:  55.5)),

    // MARK: - 오세아니아
    Country(id: "AU", name: "호주",           price:   350_000, flag: "🇦🇺", continent: .oceania,      coordinate: .init(lat:-25.3,  lon: 133.8)),
    Country(id: "NZ", name: "뉴질랜드",       price:   100_000, flag: "🇳🇿", continent: .oceania,      coordinate: .init(lat:-40.9,  lon: 174.9)),
    Country(id: "FJ", name: "피지",           price:     3_000, flag: "🇫🇯", continent: .oceania,      coordinate: .init(lat:-17.7,  lon: 178.0)),
    Country(id: "TV", name: "투발루",         price:     1_000, flag: "🇹🇻", continent: .oceania,      coordinate: .init(lat: -7.5,  lon: 178.7)),
    Country(id: "PW", name: "팔라우",         price:     1_500, flag: "🇵🇼", continent: .oceania,      coordinate: .init(lat:  7.5,  lon: 134.6)),
    Country(id: "NR", name: "나우루",         price:       800, flag: "🇳🇷", continent: .oceania,      coordinate: .init(lat: -0.5,  lon: 166.9)),
]
