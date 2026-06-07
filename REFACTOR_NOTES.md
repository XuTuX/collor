# REFACTOR_NOTES (게임 구조 리팩토링 작업 노트)

현재 컬러 퍼즐 7 게임의 소스 코드를 기능별로 세밀하게 격리하여 구조적 안정성과 확장성을 대폭 높였습니다. 기능의 변경 없이 100% 동일하게 동작하며, 앞으로 새로운 캐릭터, 조커(도우미), 족보(규칙), 스테이지 기믹을 손쉽게 추가할 수 있는 구조입니다.

---

## 1. 전체 파일 구조 (Directory Tree)

```text
collor/
├── conf.lua                       # Love2D 윈도우 창 크기 및 기본 구성
├── main.lua                       # 루트 진입점 (src/main.lua로 브릿징 및 상대 경로 탐색 추가)
├── REFACTOR_NOTES.md              # [본 파일] 리팩토링 상세 명세서
│
├── assets/
│   └── fonts/                     # 나눔고딕 글꼴 리소스 (.ttf)
│
└── src/
    ├── main.lua                   # 씬 매니저와 Love2D 콜백을 바인딩하는 최소한의 글루(glue) 레이어
    │
    ├── core/                      # 게임 엔진 코어 시스템
    │   ├── constants.lua          # 픽셀 좌표 및 색상 팔레트 상수 (구 config.lua 대체)
    │   ├── game.lua               # 전역 데이터 상태 소유자 및 게임 주기 총괄 컨트롤러 (구 game.lua의 상태 파트)
    │   ├── save_manager.lua       # 세이브/로드 파일 핸들러 (확장용 스텁)
    │   └── state_machine.lua      # 씬(화면) 상태 전환용 유한 상태 머신 (FSM)
    │
    ├── states/                    # 화면(씬) 상태별 라이프사이클 처리기
    │   ├── menu_state.lua         # 타이틀 / 메인 메뉴 화면
    │   ├── gameplay_state.lua     # 인게임 카드 덱 조작 및 드래그 화면 (플레이어 주 루프)
    │   ├── result_state.lua       # 스코어 집계 연출 및 라운드 결과 정산 카드 화면
    │   └── settings_state.lua     # 컬러 상점 강화 및 다음 관문 도전 맵 화면
    │
    ├── gameplay/                  # puzzle 카드 게임 핵심 로직 규칙
    │   ├── board.lua              # 무대 위의 7개 카드 슬롯 조작
    │   ├── tile.lua               # 패(Hand)와 주머니(Deck) 카드 데이터 구조 및 선택/토글
    │   ├── turn_manager.lua       # 신규 라운드 셋업, 드로우, 바꾸기(Discard) 횟수 차감 제어
    │   ├── pattern_checker.lua    # Runs, Mirror, Step 족보 감지 알고리즘 (구 detect.lua 알고리즘 파트)
    │   └── rule_engine.lua        # 규칙 강화 레벨 적용 및 Ante 3 보스 디버프 기믹 계산
    │
    ├── systems/                   # 독립 구동되는 기능별 제어 서브시스템
    │   ├── audio_system.lua       # 절차적 파동 합성 기반 오디오 연출기 (구 sound.lua 대체)
    │   ├── effect_system.lua      # 파티클 폭발 및 떠오르는 득점 텍스트 연출 관리자
    │   ├── animation_system.lua   # 슬롯 튀기 효과, 진입 배너, 비행 애니메이션 연출 타이머 관리자
    │   ├── score_system.lua       # 발라트로 스타일 득점 시퀀스 스텝 업데이트 관리자
    │   └── joker_system.lua       # 도우미 조커 획득 한도 체크 및 득점 조건 판정기
    │
    ├── entities/                  # 렌더링 가능한 게임 내 인스턴스 표현체
    │   ├── character.lua          # 둥글둥글하고 눈동자 굴러가는 색친구 드로우 함수
    │   ├── joker.lua              # 상점 카드 내부의 입체 조커 아이콘 드로우 함수
    │   └── modifier.lua           # 보스 기믹 텍스트 디스크립션 관리
    │
    ├── ui/                        # 공통 재사용 UI 및 레이아웃 위젯
    │   ├── panel.lua              # 테두리 하이라이트 및 드롭 섀도우 박스 컨테이너
    │   ├── button.lua             # 액션 버튼, 알약 배지(Pill), 콤보 카드
    │   ├── card_slot.lua          # 보드 빈 슬롯 배경 및 주머니 카드 겹침 그래킵
    │   ├── drag_handler.lua       # 마우스 위치 추종 오버 카드 감지 및 드래그 정렬
    │   └── hud.lua                # 좌측 스탯 정보판, 족보 가이드표, 주머니 전체 모달 overlay
    │
    └── utils/                     # 공통 도구 성격의 경량 함수
        ├── math.lua               # easeBack, easeElastic 등 보간 공식 헬퍼
        ├── random.lua             # love.math.random 래퍼 및 Fisher-Yates 셔플 구현
        ├── tween.lua              # 프레임 레이트 보정 부드러운 수렴(smoothTo) 보간기
        └── debug.lua              # 디버그 보드셋업 및 테스트 시나리오 시뮬레이터
```

---

## 2. 변경 파일 목록 및 역할 분담 설명

| 분류 | 생성 및 수정된 파일 | 원본 레거시 대응 | 주요 역할 및 특징 |
| :--- | :--- | :--- | :--- |
| **코어** | `core/constants.lua` | `config.lua` | 게임 화면 넓이, 패널 좌표값, HSL 색상 팔레트 정보 보관 |
| | `core/game.lua` | `game.lua` (일부) | 전역 상태 데이터 소유, 하위 시스템 틱 호출 및 알림 토스트 제어 |
| | `core/state_machine.lua` | - | 화면 상태를 전환하여 타이틀, 게임, 상점으로 컨트롤을 넘겨줌 |
| | `core/save_manager.lua` | - | 세이브 파일 로드 및 세이브 처리 확장 스텁 |
| **상태** | `states/menu_state.lua` | `screens.lua` (일부) | 타이틀(메뉴) 화면 그리기 및 새 게임 버튼 입력 처리 |
| | `states/gameplay_state.lua` | `screens.lua` / `main.lua` | 패 정렬, 드래그 처리, 실행 및 바꾸기 버튼 검출, 게임오버 연출 |
| | `states/result_state.lua` | `screens.lua` (scoring) | 득점 틱 애니메이션 수치 Tally 및 코인 보상 카드 출력 |
| | `states/settings_state.lua` | `screens.lua` (shop) | 상점 3개 아이템 구매, 관문 진행 맵 출력, 다음 관문 시작 제어 |
| **게임** | `gameplay/board.lua` | `game.lua` (G.board) | 7개 슬롯 데이터 관리 및 상태 클리어 |
| | `gameplay/tile.lua` | `game.lua` (G.hand) | 덱/주머니 셔플, 카드 드로우, 드래그 인덱스 검출, 순서 재정렬 |
| | `gameplay/turn_manager.lua` | `game.lua` (G.discard) | 바꾸기 동작, 비행 애니메이션 트리거, 새로운 라운드 기본값 셋업 |
| | `gameplay/pattern_checker.lua` | `detect.lua` (evaluate) | Runs 감지, Mirror 대칭성 확인, Step 계단형 족보 탐색 알고리즘 |
| | `gameplay/rule_engine.lua` | `game.lua` (scoreBoard) | 족보 강화 레벨 별 칩/배수 투영 및 보스 스테이지 3 디버프 체크 |
| **시스템** | `systems/audio_system.lua` | `sound.lua` | 사인파, 삼각파, 화음, 노이즈를 런타임 합성하여 재생하는 경량 오디오 |
| | `systems/effect_system.lua` | `draw.lua` (particles) | 동적 스폰되는 골드/콤보 파티클 및 텍스트 파티클 승천 처리 |
| | `systems/animation_system.lua` | `game.lua` (anim) | 슬롯 튀기 효과, 라운드 배너, 실행 비행 등 렌더링 프레임 연출 |
| | `systems/score_system.lua` | `game.lua` (G.sc) | 순차적인 득점 집계(카드 -> 다채로움 -> 족보 -> 조커 -> 합산) 갱신 |
| | `systems/joker_system.lua` | `game.lua` (joker) | 상점에서 조커 획득 가능성 검증 및 득점 단계 조커 체크 계산 |
| **엔티티** | `entities/character.lua` | `draw.lua` (character) | HSL 색상, 마우스 트래킹 눈동자, 콤보 링 테두리를 지닌 색친구 드로우 |
| | `entities/joker.lua` | `screens.lua` (icons) | 상점에 노출되는 도우미/강화 아이템의 입체적인 벡터 아이콘 드로우 |
| | `entities/modifier.lua` | `screens.lua` (gimmick) | Ante 3 보스 디버프 기믹 텍스트 번역 및 설명 제공 |
| **UI** | `ui/panel.lua` | `ui.lua` (UI.panel) | 그림자 효과와 입체 빔이 적용된 기본 마스터 패널 드로우 |
| | `ui/button.lua` | `ui.lua` (UI.button) | 미세 테두리와 하이라이트가 들어간 공통 버튼, 알약 배지, 칩 배지 |
| | `ui/card_slot.lua` | `draw.lua` (R.board) | 빈 슬롯 십자선 배경 플레이스홀더 및 남은 주머니 카드 스택 드로우 |
| | `ui/drag_handler.lua` | `main.lua` (drag) | 마우스 드래그 오버랩 카드 계산 및 정렬/토글 분기 |
| | `ui/hud.lua` | `screens.lua` / `ui.lua` | 폰트 로드, 좌측 정보 HUD, 우측 가이드표, 주머니 상세 오버레이 렌더링 |
| **유틸** | `utils/math.lua` | `ui.lua` (ease) | 이징 보간 공식 및 선형 보간 함수 |
| | `utils/random.lua` | `game.lua` (shuffle) | love.math.random 래퍼 및 공통 배열 셔플 알고리즘 |
| | `utils/tween.lua` | `game.lua` (lerp) | 프레임 독립적인 부드러운 수렴(smoothTo) 보간 공식 래퍼 |
| | `utils/debug.lua` | `main.lua` (comments) | 족보 테스트를 위해 보드를 즉시 구성해 주는 디버깅 모듈 |

---

## 3. 리팩토링 개선점 요약

1. **완벽한 UI와 게임 규칙 분리**:
   - 화면 렌더링 및 텍스트 폰트 조작은 `ui/` 폴더 및 `states/` 폴더 내에 완벽하게 갇혀 있으며, `gameplay/` 내 규칙 엔진은 렌더링 모듈이나 윈도우 환경에 대한 의존성이 0%입니다.
2. **코드 중복의 대폭 제거**:
   - `screens.lua`와 `game.lua` 양쪽에 분산 배치되어 미세한 수치 차이가 나거나 중복되어 있던 Ante 별 목표 점수 계산 공식(`getTargetScoreForStage`)을 `data/balance.lua`의 `getTargetScore` 함수 하나로 완전 통합했습니다.
   - 각 상태나 파일마다 산발적으로 흩어져 사용되던 테이블 셔플 루프를 `utils/random.shuffle` 하나로 단일화했습니다.
   - 프레임 보간 공식(`Tween.smoothTo`)을 규격화하여 X좌표 갱신 및 스무스 득점 갱신 부분의 복잡성을 대폭 덜어냈습니다.
3. **가독성 향상과 파일 크기 제약 준수**:
   - 기존에 **1,000줄이 넘어** 스크롤조차 부담스럽던 `screens.lua`와 800줄 이상이었던 `game.lua`를 쪼개어, **단 한 개의 파일도 300줄을 초과하지 않는** 극강의 가독성을 구현했습니다.
4. **한글 폰트 의존성 단일화**:
   - 각 모듈이 개별적으로 폰트 로더를 불러와 복제하는 대신 `ui/hud.lua`에서 폰트를 로드하고 타 UI 위젯들이 이를 안전하게 가져다 쓸 수 있도록 의존성을 묶었습니다.

---

## 4. 제거 및 정리된 레거시 파일들

새 구조로 이관이 완료되어 최상위 디렉토리에서 안전하게 삭제 완료한 파일들입니다.
* `config.lua` (-> `src/core/constants.lua` 및 `src/data/` 로 분리 이관 완료)
* `detect.lua` (-> `src/gameplay/pattern_checker.lua` 로 이관 완료)
* `game.lua` (-> `src/core/game.lua` 및 `src/gameplay/`, `src/systems/` 로 쪼개어 이관 완료)
* `screens.lua` (-> `src/states/` 및 `src/ui/hud.lua` 로 이관 완료)
* `draw.lua` (-> `src/entities/character.lua` 및 `src/ui/card_slot.lua` 로 이관 완료)
* `sound.lua` (-> `src/systems/audio_system.lua` 로 이관 완료)
* `ui.lua` (-> `src/ui/button.lua`, `src/ui/panel.lua`, `src/utils/math.lua` 로 이관 완료)

---

## 5. 실행 및 검증 가이드

* **실행 방식**: 기존과 완전하게 동일하게 루트 폴더에서 `love .`를 입력하여 실행합니다.
* 루트의 `main.lua`가 `package.path` 설정을 통해 `src/` 디렉토리를 로드 경로에 추가해 주므로 모듈간 `require`가 매우 자연스럽게 연결됩니다.

---

## 6. 향후 확장 안내 (Expansion Points)

* **새로운 색친구 캐릭터 추가 시**:
  - `src/data/characters.lua`에 이름, 기본 색상값, 다크 컬러값, 기본 점수(base), 덱 포함 개수(count)를 추가하면 게임 시작 덱에 자동으로 적용됩니다.
* **새로운 도우미 조커 추가 시**:
  - `src/data/jokers.lua`에 새 조커 템플릿 정보를 추가하고, `src/systems/joker_system.lua`의 `evaluate` 함수 내에 효과 트리거 조건과 칩/배수 계산 로직을 분기로 추가하면 상점에서 즉시 등장하고 계산에 반영됩니다.
* **새로운 족보 규칙 추가 시**:
  - `src/gameplay/pattern_checker.lua`에 새로운 족보 검출 로직(예: 스트레이트, 퐁 등)을 등록하고 `src/data/patterns.lua`에 초기 강화 스탯을 배치하면 즉시 게임 점수판에 적용됩니다.
