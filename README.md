# Habit Endeavor

> 습관을 쌓고, 세계를 정복하라.

SwiftUI 기반 게이미피케이션 습관 트래커. 매일 습관을 완료하면 코인을 획득하고, 코인으로 세계 국가를 구매해 나만의 세계 지도를 완성합니다.

---

## 스크린샷

| 체크박스 | 기록 | 일정 | 세계 |
|:---:|:---:|:---:|:---:|
| 주간 습관 그리드 | 통계 & 차트 | 주간/월간 할일 | 국가 구매 |

---

## 주요 기능

### ✅ 체크박스 탭
- 주간 그리드로 습관 체크인
- 습관 이름 탭 → 이름·색상 편집 (EditHabitSheet)
- 롱프레스 → 실패 사유 기록
- 28일 히트맵 & 4주 달성 추이 차트
- 체크 시 햅틱 피드백 + 파티클 애니메이션

### 📊 기록 탭
- 총 성공 횟수 / 최장 연속기록 / 전체 달성률
- 습관별 고유 색상 파이차트
- 요일별 달성률 바차트 (그린/레드 의미 기반 + 70% 기준선)
- 실패 사유 인용구 스타일 로그
- 주간 리뷰 슬라이드 (5페이지)

### 📅 일정 탭
- **주간 뷰**: 요일별 할일 카드, 완료 진행 바, 주별 ← → 이동
- **월간 뷰**: 캘린더 그리드 (날짜별 할일 미리보기), 선택일 패널
- 할일별 시각 설정 (DatePicker)
- 길게 눌러 삭제 (context menu)

### 🌍 세계 탭 *(구체화 예정)*
- 코인으로 60개국 구매
- 세계 지도에서 정복 현황 시각화
- 국가 가격 티어: 투발루 1,000C ~ 미국 1,000,000C

### ⚙️ 설정 탭
- 주 시작 요일 (월/일)
- 리포트 알림 시간 설정
- 라이트/다크 모드

---

## 기술 스택

| 분류 | 기술 |
|---|---|
| UI | SwiftUI |
| 데이터 | SwiftData + CloudKit |
| 차트 | Swift Charts |
| 알림 | UserNotifications |
| 플랫폼 | iOS 17+ / iPadOS 17+ / macOS 14+ |
| 언어 | Swift 6 |

---

## 아키텍처

```
HabitEndeavor/
├── Models
│   ├── Habit.swift              # 습관 (이름, 색상, 순서)
│   ├── HabitRecord.swift        # 체크 기록 (날짜, 완료 여부, 코인 지급)
│   ├── ScheduleItem.swift       # 일정 할일 (날짜, 제목, 시각, 완료)
│   ├── PurchasedCountry.swift   # 구매한 국가
│   └── AppSettings.swift        # 앱 설정
│
├── Services
│   ├── CoinService.swift        # 코인 지급/회수 로직
│   ├── StreakService.swift       # 연속기록 계산 (computeAll — 단일 접근)
│   └── StatisticsManager.swift  # 통계 계산 서비스 레이어
│
├── Views
│   ├── CheckboxView.swift       # 체크박스 탭 (recordsByHabit 딕셔너리 최적화)
│   ├── RecordsView.swift        # 기록 탭 (@State 캐싱)
│   ├── ScheduleView.swift       # 일정 탭
│   ├── WorldView.swift          # 세계 탭 (구체화 예정)
│   └── SettingsView.swift       # 설정 탭
│
└── Sheets
    ├── AddHabitSheet.swift      # 습관 추가
    ├── EditHabitSheet.swift     # 습관 편집
    ├── WeeklyReviewSheet.swift  # 주간 리뷰
    └── FailureNoteSheet.swift   # 실패 사유 입력
```

---

## 코인 시스템

- 당일 체크 완료 → **+1,000 코인** 지급
- 당일 체크 취소 → 코인 회수 (과거 날짜 취소는 회수 없음)
- 코인 잔액 = 전체 지급 코인 − 국가 구매 비용

---

## 성능 최적화

- `recordsByHabit: [PersistentIdentifier: [HabitRecord]]` 딕셔너리 인덱스로 O(n²) → O(1) 조회
- `StatisticsManager` 통계 계산을 `@State` 캐싱 + `onChange` 트리거로 매 렌더 재계산 방지
- `StreakService.computeAll()` — `habit.records` 단 1회 접근으로 스트릭 3종 동시 계산
- `HabitMiniCard` — 28일 히트맵·스트릭을 dict 1회 빌드로 통합 처리
- `MonthGrid` — 셀마다 `allItems` 스캔 제거, body 진입 시 dict 1회 빌드

---

## 설치 및 실행

```bash
git clone https://github.com/Roy1210part2/HabitEndeavor.git
cd HabitEndeavor
open HabitEndevor.xcodeproj
```

Xcode 16+ / iOS 17 Simulator 또는 실기기에서 빌드·실행합니다.

> **CloudKit**: Apple Developer 포털에서 `iCloud.co.lyu.HabitEndeavor` 컨테이너를 생성하고 Signing & Capabilities에 iCloud + CloudKit을 추가하면 iCloud 동기화가 활성화됩니다. 설정하지 않으면 자동으로 로컬 저장소를 사용합니다.

---

## 로드맵

- [ ] CloudKit 동기화 검증
- [ ] 세계 지도 SVG 렌더링 고도화
- [ ] 퀘스트 시스템 구체화
- [ ] 위젯 (Lock Screen / Home Screen)
- [ ] Apple Watch 연동

---

## 라이선스

MIT License © 2026 Roy
