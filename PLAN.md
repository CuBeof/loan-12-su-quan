# Kế hoạch phát triển — Loạn 12 Sứ Quân (Match-3 RPG)

Tài liệu này là kế hoạch kỹ thuật, bám theo [SPEC.md](SPEC.md). Game match-3 RPG offline, theo lượt đấu với AI, chạy trên Android nhiều kích thước màn hình, dùng Godot 4.6.

## 1. Quyết định nền tảng

| Hạng mục | Quyết định | Lý do |
| :--- | :--- | :--- |
| Engine | Godot 4.6, GDScript typed (`:=`, kiểu tường minh) | Theo SPEC; typed GDScript nhanh hơn và bắt lỗi sớm |
| Renderer | **Mobile** (không dùng Forward+) | Forward+ không tối ưu cho GPU di động. Lưu ý: `example/` dùng Forward+ — KHÔNG sao chép cấu hình này |
| Hướng màn hình | Portrait (dọc) | Bố cục màn chiến đấu: đối thủ trên — bàn cờ giữa — người chơi dưới |
| Stretch | `canvas_items` + aspect `expand` | Thích ứng nhiều tỉ lệ màn hình Android, kết hợp safe-area cho tai thỏ |
| Texture | ETC2/ASTC compression bật sẵn | Bắt buộc cho VRAM di động |
| Vị trí project | Thư mục `game/` ở gốc repo | Tách khỏi `example/`, SPEC, skills |
| Test | gdUnit4 (hoặc GUT), chạy `godot --headless` | Logic bàn cờ tách khỏi node nên test được không cần render |

## 2. Cấu trúc thư mục (feature-based)

```
game/
  project.godot
  common/
    autoload/          # event_bus.gd, scene_manager.gd, audio_manager.gd,
                       # save_manager.gd, settings_manager.gd, game_state.gd
    theme/             # Theme resource dùng chung toàn UI
    utils/
  core/                # LOGIC THUẦN — RefCounted, không Node, không res:// path
    board/             # board_logic.gd, match_finder.gd, special_resolver.gd,
                       # gravity_refill.gd, move_generator.gd, board_rng.gd
    battle/            # turn_manager.gd, battle_state.gd, effect_resolver.gd
    ai/                # ai_controller.gd, move_scorer.gd
  data/                # Script Resource (định nghĩa) + file .tres (nội dung)
    tiles/             # tile_definition.gd + attack.tres, health.tres, ...
    characters/        # character_definition.gd + .tres từng tướng
    enemies/           # enemy_definition.gd (chỉ số + hồ sơ hành vi AI + thoại)
    skills/            # skill_definition.gd, skill_tree_definition.gd
    items/             # item_definition.gd
    levels/            # level_definition.gd (hình dạng bàn cờ, đối thủ, sự kiện)
    map/               # map_definition.gd (đồ thị node bản đồ)
  features/            # PRESENTATION — mỗi màn hình/tính năng một thư mục
    board_view/        # board_view.tscn, tile_view.tscn, hiệu ứng ghép
    battle_screen/
    main_menu/
    settings/
    map_screen/
    shop/
    skill_tree/
    inventory/
  assets/
    placeholders/      # texture/âm thanh tạm sinh sẵn
    textures/  audio/  fonts/   # asset thật thêm sau
  tests/               # unit test cho core/
```

## 3. Kiến trúc 4 tầng & quyền sở hữu dữ liệu

Signal đi LÊN, lời gọi hàm đi XUỐNG. Tầng Presentation không bao giờ sửa dữ liệu trực tiếp.

| Tầng | Thành phần | Sở hữu gì |
| :--- | :--- | :--- |
| Presentation | `features/` — board_view, HUD, các màn hình | Không sở hữu state; chỉ nghe signal và render |
| Logic | `core/` — TurnManager (state machine), AIController, EffectResolver | Điều phối lượt, luật ghép, hiệu ứng |
| Data | `data/` — Resource `.tres`; `BattleState`; `PlayerProfile` | BoardLogic sở hữu lưới; BattleState sở hữu HP/năng lượng/vàng/exp trong trận; PlayerProfile sở hữu tiến trình lâu dài (cấp, mạng, vàng, kỹ năng, balo) |
| Infrastructure | `common/autoload/` | EventBus (< 15 sự kiện vòng đời), Audio, Save, Scene, Settings |

Nguyên tắc then chốt:

- **`core/` thuần logic**: `BoardLogic` là `RefCounted`, lưới là `Dictionary[Vector2i, TileState]` (hoặc mảng 2D), tọa độ luôn `Vector2i`. Không node, không texture, không âm thanh. Nhờ đó: (1) unit test headless được, (2) **AI mô phỏng nước đi trên bản sao lưới mà không cần render** — bắt buộc vì AI phải lượng giá hàng chục nước mỗi lượt.
- **BoardView chỉ là máy chiếu**: nghe các signal của BoardLogic (`tiles_swapped`, `tiles_matched`, `tile_spawned`, `special_created`, `board_settled`…) và phát animation/tween tương ứng. TurnManager chờ BoardView báo `animations_finished` rồi mới sang bước kế.
- Kiểm tra match/điều kiện thắng chỉ chạy **khi có nước đi**, không chạy trong `_process`.
- Input cảm ứng dùng `InputEventScreenTouch`/`InputEventScreenDrag` (không dùng sự kiện chuột), hitbox ô cờ rộng rãi, swipe-to-swap.

### Ma trận viên đặc biệt

Luật đã chốt theo **chuẩn Candy Crush** — bảng chi tiết nằm trong [SPEC.md](SPEC.md) mục "Cơ chế" (nguồn chân lý); [DESIGN.md](DESIGN.md) ghi chú nguồn gốc từng luật. Mỗi dòng luật có unit test tương ứng trong `game/tests/`.

Hiệu ứng theo loại tile: tấn công (trừ máu địch), máu (hồi máu, một số nhân vật overheal thành buff), năng lượng (dùng skill), vàng (tích sau trận nếu thắng; địch có thể cướp/tiêu), kinh nghiệm (lên cấp sau trận; địch có thể dùng cường hóa trong trận).

## 4. Chiến lược tài nguyên — gán asset về sau

Yêu cầu: dự án phải chạy được bằng placeholder ngay từ đầu, và việc gán asset thật sau này **chỉ là sửa file `.tres` trong Inspector, không sửa code**.

1. **Mọi nội dung là Resource**: `TileDefinition`, `CharacterDefinition`, `EnemyDefinition`… có các slot `@export var texture: Texture2D`, `@export var match_sfx: AudioStream`, `@export var color: Color` (màu fallback). Code logic chỉ biết `StringName` id, không bao giờ chứa đường dẫn `res://`.
2. **Fallback placeholder**: khi `texture == null`, TileView tự vẽ hình khối + màu từ definition (dùng `PlaceholderTexture2D` hoặc `_draw`). Game luôn chơi được trước khi có asset.
3. **Âm thanh theo khóa**: `AudioManager.play_sfx(&"tile_match")` tra trong một `SoundBank` resource (`Dictionary[StringName, AudioStream]`). Thiếu khóa thì im lặng + cảnh báo, không crash. 3 bus: `Master / Music / SFX` khớp với tab cài đặt âm thanh.
4. **Một điểm gán duy nhất**: toàn bộ slot asset nằm trong `game/data/**.tres` và `SoundBank`. Designer chỉ cần mở các file này để gắn asset.
5. Resource gắn vào instance riêng (chỉ số quái…) phải `duplicate()` hoặc bật Local to Scene — tránh bug share chung resource (lỗi #1 của Godot 4).

## 5. Lộ trình theo giai đoạn

### Giai đoạn 0 — Khung dự án
Tạo `game/` với project.godot (Mobile renderer, portrait, stretch, ETC2/ASTC), cây thư mục, autoload rỗng, theme, `.gitignore`, framework test chạy headless, placeholder cho 5 loại tile.
**Nghiệm thu**: project mở được bằng Godot 4.6, test mẫu pass qua `godot --headless`.

### Giai đoạn 1 — Lõi match-3 (quan trọng nhất)
`BoardLogic` + `MatchFinder` + `GravityRefill` + `SpecialResolver`: swap, phát hiện ghép 3/4/5/L/T, rơi & sinh viên mới (RNG có seed, shuffle bag), toàn bộ ma trận viên đặc biệt ở mục 3, hình dạng bàn cờ tùy màn (ô khuyết, tối đa 8×8). `BoardView` + touch input + tween. Phát hiện hết nước đi → xáo trộn.
**Nghiệm thu**: bảng luật đặc biệt có unit test phủ từng dòng; chơi tay được trên cửa sổ portrait.

### Giai đoạn 2 — Lớp chiến đấu theo lượt
`TurnManager` (state machine: PlayerTurn → Resolving → CheckExtraTurn → EnemyTurn…), `BattleState` (HP/năng lượng/vàng/exp hai phía), `EffectResolver` ánh xạ kết quả ghép → hiệu ứng chiến đấu, thêm lượt khi ghép > 3, thắng/thua, máu mất duy trì qua trận, hệ thống mạng (hồi theo thời gian/match-5), nút rút lui (xử thua, trừ mạng). HUD trận đấu với thanh máu/mana hai phía.
**Nghiệm thu**: đấu được một trận hoàn chỉnh người vs "AI ngẫu nhiên" tạm.

### Giai đoạn 3 — AI đối thủ
`MoveGenerator` liệt kê nước hợp lệ trên bản sao lưới; `MoveScorer` chấm điểm theo **hồ sơ hành vi data-driven** trong `EnemyDefinition` (trọng số ưu tiên loại tile, độ tham viên đặc biệt, mức chặn nước của người chơi, độ khó). Hành vi đặc thù: tên cướp ưu tiên vàng, bỏ chạy khi thanh vàng đầy; quái dùng exp/vàng trong trận. Khung chat thoại trong trận.
**Nghiệm thu**: ≥ 2 hồ sơ AI khác biệt rõ; AI ra quyết định < 100 ms.

### Giai đoạn 4 — Hệ thống RPG meta
Chọn nhân vật (nhiều tướng, bộ chỉ số/kỹ năng riêng), kinh nghiệm & lên cấp, điểm kỹ năng, kỹ năng dùng năng lượng trong trận, cây kỹ năng, balo & vật phẩm, vàng & cửa hàng, rơi đồ từ match-5.
**Nghiệm thu**: vòng lặp thắng trận → nhận exp/vàng → lên cấp → mở kỹ năng → mua đồ chạy thông suốt.

### Giai đoạn 5 — Màn hình & điều hướng
Màn hình chính (Tiếp tục/Chơi mới/Cài đặt/Thông tin), cài đặt (tab âm thanh: 3 cặp bật-tắt + âm lượng; tab UX mở rộng dần), bản đồ (đồ thị node, đường nối có thể bị chặn bởi sự kiện), shop, cây kỹ năng, balo theo đúng layout trong SPEC. `SceneManager` chuyển cảnh threaded; nút Back Android pop theo navigation stack.
**Nghiệm thu**: đi được trọn flow menu → bản đồ → trận đấu → kết quả → bản đồ trên nhiều tỉ lệ màn hình.

### Giai đoạn 6 — Lưu trữ
`SaveManager` ghi `user://` (không bao giờ ghi `res://`), serialize qua Dictionary với `.get(key, default)` để save cũ không hỏng khi thêm trường, autosave sau trận/giao dịch, lưu cài đặt riêng. "Tiếp tục" khôi phục đúng vị trí trên bản đồ.
**Nghiệm thu**: tắt app giữa chừng, mở lại tiếp tục đúng tiến trình.

### Giai đoạn 7 — Hoàn thiện & xuất bản Android
Juice (tween, particle, rung haptic, hint nước đi), safe-area tai thỏ, giảm FPS khi app nền, export preset Android (keystore, quyền tối thiểu), profiling trên máy tầm trung (script < 4 ms/frame, draw call < 100), icon/splash.
**Nghiệm thu**: APK chạy mượt 60 FPS trên máy Android tầm trung thật.

### Giai đoạn sau (đúng SPEC, chưa làm)
Hệ thống tính điểm, thiết kế quái/boss & cân bằng; đa ngôn ngữ; liên kết tài khoản; nạp tiền (hồi mạng); địa điểm sự kiện đặc biệt.

## 6. Kiểm thử

- Unit test cho `core/`: bảng luật đặc biệt (mỗi dòng mục 3 ít nhất một test), gravity/refill, phát hiện hết nước, RNG seed tái lập được, EffectResolver, MoveScorer.
- Test mô phỏng: AI vs AI N trận chạy headless để dò crash/deadlock luật.
- Quy tắc: mọi bugfix trong `core/` kèm test tái hiện.

## 7. Rủi ro chính

| Rủi ro | Giảm thiểu |
| :--- | :--- |
| Tổ hợp viên đặc biệt nhiều cạnh hiếm (nổ kích nổ dây chuyền, biến đổi chồng nhau) | Resolver xử lý theo **hàng đợi sự kiện** tuần tự, không đệ quy trực tiếp; bảng luật có test |
| AI quá mạnh/quá yếu gây ức chế | Trọng số khó nằm trong data `.tres`, chỉnh không cần sửa code; mô phỏng AI vs AI để đo |
| Asset về sau lệch kích thước/format | Quy ước kích thước chuẩn trong CLAUDE.md; placeholder cùng kích thước chuẩn ngay từ đầu |
| Hiệu năng máy yếu | Renderer Mobile, đo profiling từ Giai đoạn 1, pool tile view thay vì instantiate liên tục |
