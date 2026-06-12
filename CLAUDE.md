# CLAUDE.md

Chỉ dẫn cho Claude Code khi làm việc trong repo này.

## Tổng quan

Game **match-3 RPG offline** theo lượt (người chơi vs AI) cho **Android**, làm bằng **Godot 4.6 / GDScript**. Tên dự án: Loạn 12 Sứ Quân.

- [SPEC.md](SPEC.md) — đặc tả gameplay, luật ghép, các màn hình. Là nguồn chân lý về thiết kế; khi spec và code lệch nhau, hỏi lại user. **Cơ chế ghép và viên đặc biệt theo chuẩn Candy Crush** — bảng luật đầy đủ trong mục "Cơ chế" của SPEC; mỗi dòng luật phải có unit test tương ứng.
- [PLAN.md](PLAN.md) — kế hoạch kỹ thuật, kiến trúc, lộ trình giai đoạn, ma trận viên đặc biệt.
- `game/` — project Godot chính (toàn bộ code mới đặt ở đây).
- `example/` — game match-3 mẫu hoàn chỉnh, **chỉ để tham khảo** cách làm tween/âm thanh/hiệu ứng. KHÔNG copy cấu hình của nó (nó dùng Forward+; dự án chính phải dùng renderer Mobile). Không sửa thư mục này.
- `.claude/skills/godot-master/` — skill thư viện chuyên gia Godot. Load skill này khi làm task Godot; đọc đúng reference theo Decision Matrix, không load thừa.

## Lệnh thường dùng

```bash
# Import asset + kiểm tra script lỗi (chạy sau khi thêm file mới)
godot --headless --path game --import

# Chạy unit test headless (runner tự viết, exit code 1 khi fail)
godot --headless --path game -s res://tests/run_tests.gd

# Smoke test: khởi động main scene 60 frame để bắt lỗi runtime
godot --headless --path game --quit-after 60

# Chạy game (khi có môi trường đồ họa)
godot --path game
```

Suite test mới thêm vào mảng `SUITES` trong `game/tests/run_tests.gd`, kế thừa `BoardTestBase` (`game/tests/test_base.gd`).

## Kiến trúc — ranh giới bắt buộc

Bốn tầng, signal đi LÊN, lời gọi hàm đi XUỐNG:

```
features/   (Presentation — scene, view, HUD; KHÔNG sở hữu state)
core/       (Logic — TurnManager, AI, luật ghép; thuần RefCounted)
data/       (Data — Resource definition + .tres; nguồn chân lý)
common/autoload/  (Infrastructure — EventBus, Audio, Save, Scene, Settings)
```

1. **`game/core/` thuần logic**: chỉ `RefCounted`/`Resource`, không kế thừa `Node`, không đụng SceneTree, không `res://` path, không texture/âm thanh. Lý do: unit test headless và AI phải mô phỏng nước đi trên bản sao lưới không cần render.
2. **Tọa độ lưới luôn `Vector2i`**, không bao giờ dùng `Vector2`/float cho ô cờ.
3. **View là máy chiếu**: `BoardView` nghe signal từ `BoardLogic` rồi phát animation; không tự suy luận luật. Logic chờ signal `animations_finished` từ view trước khi sang bước kế.
4. Kiểm tra match/thắng-thua chỉ chạy khi có nước đi — **không kiểm tra trong `_process`**.
5. `EventBus` (autoload) chỉ chứa sự kiện vòng đời toàn cục, **tối đa ~15 signal**. Giao tiếp trong một scene dùng signal trực tiếp. Không bao giờ truyền tham chiếu `Node` qua EventBus.
6. UI không gọi thẳng logic gameplay — UI phát signal, controller nghe. Tiền/đếm vật phẩm dùng `int`, không dùng `float`.

## Quy tắc tài nguyên (asset thêm sau)

Asset hình ảnh/âm thanh sẽ được thiết kế và gán sau, nên:

1. **Code logic không bao giờ chứa đường dẫn `res://` hay tên file asset.** Mọi nội dung (tile, tướng, quái, skill, item, màn chơi) định nghĩa bằng script `Resource` trong `game/data/` với slot `@export var texture: Texture2D`, `@export var ..._sfx: AudioStream`, và id dạng `StringName`.
2. **Luôn có fallback**: texture null → view vẽ placeholder bằng màu/hình trong definition; thiếu khóa âm thanh → im lặng + `push_warning`, không crash. Game phải chơi được 100% bằng placeholder.
3. Âm thanh phát theo khóa: `AudioManager.play_sfx(&"key")` tra `SoundBank` resource. 3 audio bus: `Master / Music / SFX` (khớp tab cài đặt âm thanh trong SPEC).
4. Gán asset thật = chỉnh file `.tres` trong `game/data/` và `SoundBank` — không sửa code. Khi thêm definition mới, luôn chừa sẵn slot asset.
5. Resource gắn vào instance cần state riêng (chỉ số quái…): `duplicate()` trong `_ready()` hoặc bật Local to Scene. Không sửa `.tres` trực tiếp lúc runtime.

## Ngôn ngữ & đa ngôn ngữ (i18n)

- **Comment code, tên biến, message lỗi/cảnh báo, nội dung game: tiếng Anh.** Tài liệu markdown (SPEC/PLAN/DESIGN) giữ tiếng Việt.
- **Không hardcode text hiển thị cho người chơi.** Mọi chuỗi UI đi qua khóa dịch: `tr(&"UI_TURN")`, khai báo trong `game/i18n/translations.csv` (cột `en` mặc định, `vi`). File `.translation` do import sinh ra, không commit.
- Resource definition lưu **khóa dịch** (`display_name_key: StringName`), không lưu chuỗi thô.
- Thêm ngôn ngữ mới = thêm cột vào CSV + thêm đường dẫn `.translation` vào `internationalization/locale/translations` trong project.godot.

## Quy ước code

- File/thư mục: `snake_case`. Tên node: `PascalCase`. Signal: quá khứ `snake_case` (`tiles_matched`). Thành viên private: tiền tố `_`.
- GDScript typed mọi nơi: `:=` khi suy ra được kiểu, khai báo kiểu tường minh, hàm luôn có kiểu trả về (`-> void`).
- Khóa Dictionary/so khớp hot-path dùng `StringName` (`&"attack"`), không dùng `String`.
- Node hay truy cập: `%UniqueName`; không dùng `get_node()` đường dẫn tuyệt đối.
- Tổ chức theo feature (mỗi màn hình/tính năng một thư mục gồm scene + script + resource của nó), không gom theo loại file.
- Mọi scene phải qua **F6 test**: chạy riêng lẻ không crash.
- Bugfix trong `core/` phải kèm unit test tái hiện lỗi.

## Quy tắc mobile (Android)

- Renderer **Mobile**; portrait; stretch `canvas_items` + `expand`; ETC2/ASTC bật.
- Input cảm ứng dùng `InputEventScreenTouch` / `InputEventScreenDrag` — không dùng sự kiện chuột. Vùng chạm tối thiểu ~44 px vật lý.
- UI dùng Container + anchor, không offset pixel tuyệt đối; chừa safe-area cho tai thỏ qua `DisplayServer.get_display_safe_area()`.
- Nút Back Android: `set_quit_on_go_back(false)` + xử lý `NOTIFICATION_WM_GO_BACK_REQUEST` để pop navigation stack.
- App nền: hạ `Engine.max_fps` khi `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- Lưu dữ liệu vào `user://`, không bao giờ ghi `res://`. Save qua Dictionary với `.get(key, default)` để tương thích save cũ.

## NEVER

- KHÔNG sửa `example/` hay `.claude/skills/`.
- KHÔNG để code trong `core/` phụ thuộc Node/SceneTree/asset.
- KHÔNG hardcode `res://` path hay tên animation trong logic.
- KHÔNG dùng `load()` trong vòng lặp/`_process`; dùng `preload` hoặc `ResourceLoader.load_threaded_request()`.
- KHÔNG dùng cú pháp signal Godot 3 (`connect("name", target, "method")`) — fail âm thầm trong Godot 4; dùng `signal_name.connect(callable)`.
- KHÔNG quên: `Tween` chết theo node tạo ra nó; kill tween trước khi `queue_free()` node đang tween.
- KHÔNG dùng Forward+ cho dự án này.
