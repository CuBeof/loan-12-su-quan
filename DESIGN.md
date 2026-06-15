# Thiết kế & Cốt truyện — Loạn 12 Sứ Quân (bản nháp đang thảo luận)

Tài liệu lưu các ý tưởng thiết kế đang bàn. Chưa phải quyết định cuối — các mục "Câu hỏi mở" cần chốt với chủ dự án trước khi sản xuất asset.

## Định hướng tổng thể

- Game 2D, **không pixel art**, hơi hướng lịch sử Việt Nam.
- Bối cảnh: **loạn 12 sứ quân (944–968)** — sau khi Ngô Quyền mất, đất nước chia 12 vùng cát cứ, kết thúc khi Đinh Bộ Lĩnh thống nhất, lập Đại Cồ Việt.

## Trục sáng tạo: "Cờ lau tập trận"

Lấy huyền tích Đinh Bộ Lĩnh thuở nhỏ lấy bông lau làm cờ, cưỡi trâu bày trận làm khung tường thuật:

- Mỗi trận match-3 = một ván **"tập trận" trên sa bàn bày binh**. Người chơi không ghép viên trừu tượng mà đang "điều binh khiển tướng".
- Gợi ý mở đầu game bằng cảnh tuổi thơ cờ lau (tutorial = tập trận với lũ trẻ chăn trâu).

## 12 sứ quân = 12 boss + bản đồ chiến dịch

Màn hình bản đồ node (đã có trong SPEC) = bản đồ Bắc Bộ thế kỷ 10, mỗi node là lãnh địa một sứ quân. Người chơi đi từng vùng, **đánh dẹp hoặc chiêu hàng**, tiến tới thống nhất. Mỗi sứ quân ánh xạ vào một hồ sơ hành vi AI:

| Sứ quân | Đặc điểm lịch sử | Hành vi AI gợi ý |
| :--- | :--- | :--- |
| Phạm Bạch Hổ | Tướng dũng mãnh ("Bạch Hổ") | Hung hãn, ưu tiên tile **tấn công** |
| Đỗ Cảnh Thạc | Giỏi phòng thủ, đào hào đắp lũy | Thủ chắc, ưu tiên tile **máu** |
| Nguyễn Khoan (nhóm họ Nguyễn) | Cát cứ vùng trù phú | Tham lam, gom **vàng** |
| Trần Lãm (Trần Minh Công) | Sử thật: nuôi và hậu thuẫn Đinh Bộ Lĩnh | Ứng viên **đồng minh/sư phụ** thay vì boss |
| (8 sứ quân còn lại) | — | Thiết kế dần trong giai đoạn boss design |

Kẻ địch thường giữa các node: **giặc cỏ/thảo khấu** — khớp cơ chế "tên cướp cướp vàng rồi bỏ chạy" trong SPEC.

## 5 loại tile theo motif Việt

| Tile | Biểu tượng đề xuất | Ghi chú |
| :--- | :--- | :--- |
| Tấn công | Giáo/mác hoặc đao | Vũ khí thời kỳ này |
| Máu | Lá thuốc nam / bó mạ non | |
| Vàng | Đồng tiền cổ lỗ vuông | |
| Năng lượng | **Trống đồng Đông Sơn** | "Trống trận" thúc quân → dùng skill |
| Kinh nghiệm | **Bông lau / cờ lau** | Gắn thẳng tích Đinh Bộ Lĩnh |

Viên cường hóa đặt tên theo binh pháp: viên quét = "kỵ binh xung trận", viên nổ = "hỏa công", viên biến đổi = "trống lệnh / cờ hiệu".

## Phong cách mỹ thuật

Ba hướng đã bàn:

1. **Phỏng tranh Đông Hồ** — nét viền đậm, màu phẳng. Ưu: rất Việt Nam, nhẹ cho mobile, đọc tốt màn hình nhỏ. Nhược: tông dân gian hơi "hiền" cho cảnh chiến trận.
2. **Sơn mài / bán tả thực** — màu sâu, dát vàng, sử thi. Ưu: hoành tráng. Nhược: tốn công vẽ, nặng.
3. **Vector/flat hiện đại + họa tiết Việt** (sóng nước, mây, hoa văn trống đồng). Ưu: dễ sản xuất, dễ scale. Nhược: dễ chung chung.

**Đề xuất hiện tại: "Đông Hồ-modern" (lai 1+3)** — tinh thần dân gian Đông Hồ, dựng vector sạch, nhẹ và đồng bộ đa màn hình.

**Lưu ý xác thực:** thế kỷ 10 rất ít tư liệu hình ảnh trực tiếp. Trang phục/giáp trụ sẽ là "phóng tác có nền tảng" (dựa văn hóa Đông Sơn + suy đoán), ghi rõ trong style guide, không tự nhận tái dựng chính xác.

## Câu hỏi mở (cần chốt)

1. **Nhân vật người chơi**: nhân vật lịch sử quanh Đinh Bộ Lĩnh (Nguyễn Bặc, Đinh Điền, Lê Hoàn — mỗi người một lối đánh) hay hư cấu để tự do thiết kế kỹ năng?
2. **Tông màu**: sử thi nghiêm trang hay dân gian tươi sáng phiêu lưu?
3. **Mức độ bám sử**: bám sát (đúng tên, đúng vùng 12 sứ quân) hay phóng tác tự do (thêm thần thoại Long/Lân/Quy/Phụng, quái vật dân gian)?

## Cơ chế match-3: theo Candy Crush (ĐÃ CHỐT)

Đã chốt với chủ dự án (2026-06-12): cơ chế ghép và viên đặc biệt bám theo Candy Crush, cộng các luật riêng từ SPEC. **Bảng luật chính thức nằm trong SPEC.md (nguồn chân lý)** — bảng dưới đây chỉ ghi chú nguồn gốc từng luật:

| Tình huống | Hành vi (đã cài đặt) | Nguồn |
| :--- | :--- | :--- |
| Ghép 4 ngang / dọc | Viên quét dọc / ngang (ngược hướng ghép) | Candy Crush |
| Ghép L/T | Viên nổ; **nổ 3×3 hai lần** — nổ khi kích hoạt, sống sót, rơi xuống rồi nổ tiếp tại vị trí đáp | Candy Crush + SPEC (nổ trễ) |
| Ghép 5 thẳng | Viên biến đổi (color bomb) | Candy Crush + SPEC |
| Biến đổi + viên thường | Ăn toàn bộ viên cùng loại | Candy Crush + SPEC |
| Biến đổi + quét | Mọi viên cùng loại → viên quét hướng ngẫu nhiên, kích hoạt hết | Candy Crush + SPEC |
| Biến đổi + nổ | Mọi viên cùng loại → viên nổ, kích hoạt hết (nổ kép từng viên) | **SPEC** (Candy Crush gốc khác: zap 1 màu 2 đợt) |
| Biến đổi + biến đổi | Xóa toàn bàn cờ | Candy Crush |
| Biến đổi trúng blast gián tiếp | Tự kích hoạt: ăn toàn bộ một loại **ngẫu nhiên** | Candy Crush |
| Nổ + nổ | Nổ 5×5 **hai đợt** (đợt 2 sau khi viên mới rơi) + **thêm lượt** | Candy Crush + SPEC (thêm lượt) |
| Nổ + quét | Chữ thập lớn: 3 hàng + 3 cột | Candy Crush |
| Quét + quét | Chữ thập: 1 hàng + 1 cột | Candy Crush |
| Thêm lượt | Hàng/cột thẳng > 3 viên (L/T 3+3 không tính), và nổ + nổ | SPEC |
| Hệ số "chỉ số ×x" (ghép 5, nổ + nổ) | Chưa áp dụng — chờ lớp chiến đấu (Giai đoạn 2) | SPEC |

---

# Prompt sinh asset 2D (Claude Design)

Bộ prompt để sinh **asset 2D (không pixel art)** bằng công cụ tạo ảnh và gán vào
các slot `@export` trong `game/data/*.tres` — **không sửa code logic** (theo
`CLAUDE.md`). Motif tile bám đúng **bảng "5 loại tile theo motif Việt"** ở trên;
phong cách bám đề xuất **"Đông Hồ-modern"**. Game vẫn chơi được 100% bằng
placeholder khi chưa gán asset.

Mã màu hex lấy thẳng từ `.tres` để art khớp màu placeholder và HUD (orb tài
nguyên, flash...). Giữ đúng màu giúp toàn bộ giao diện đồng nhất.

## 0) Style guide chung — DÁN KÈM MỌI PROMPT

```
STYLE: Hand-drawn 2D game art blending the spirit of Vietnamese Đông Hồ
folk woodblock prints with clean modern vector rendering. Bold confident
outlines, mostly flat colors with subtle soft shading, Đông Sơn bronze-drum
and lotus/wave ornament. Set in 10th-century Vietnam during the Anarchy of
the Twelve Warlords (Loạn 12 Sứ Quân, 944–968, Đinh Bộ Lĩnh era). Period
details: leather/lamellar armor, conical nón, áo giao lĩnh cross-collar
robes, bronze weapons. Lightweight and crisp for small mobile screens.
NOT pixel art, NOT anime, NOT 3D render, no photoreal, no modern objects,
no text, no watermark, no border frame. Centered subject, transparent
background (PNG with alpha).
```

> Biến thể tùy chọn: đổi câu đầu thành *"…in the style of Vietnamese lacquer
> painting (sơn mài) with gold-leaf accents…"* nếu muốn tông sử thi, hoành tráng
> hơn thay vì dân gian.
>
> Lưu ý xác thực (theo mục Phong cách mỹ thuật): thế kỷ 10 rất ít tư liệu hình
> ảnh — trang phục/giáp trụ là "phóng tác có nền tảng" (văn hóa Đông Sơn + suy
> đoán), không tự nhận tái dựng chính xác.

## 1) Tile ngọc (5 loại + bản cường hóa)

**Spec:** canvas **vuông 512×512**, nền trong suốt, **1 biểu tượng duy nhất,
silhouette đậm, ở giữa**, đọc rõ ở kích thước nhỏ. Mỗi loại **khác hình dáng**
(không chỉ khác màu — để người mù màu vẫn phân biệt). Slot: `texture` trong
`game/data/tiles/*.tres`.

```
[STYLE block] + Subject: a single match-3 game gem icon shaped like a
rounded folk-art token, dominant color {COLOR}, with a {MOTIF} emblem
at its center in clean bold outline. Strong readable silhouette, soft
inner glow. 512x512, transparent bg.
```

| Tile | Tên (vi) | {COLOR} hex | {MOTIF} (theo bảng motif đã chốt) |
|---|---|---|---|
| Attack | Tấn công | `#D94536` đỏ son | a bronze Vietnamese spear/saber (giáo, mác hoặc đao) |
| Health | Máu | `#4DB85C` lục ngọc | a sprig of medicinal herb / fresh rice seedlings (lá thuốc nam, bó mạ non) |
| Gold | Vàng | `#F2C233` vàng kim | a square-holed ancient coin (đồng tiền cổ lỗ vuông) |
| Energy | Năng lượng | `#458CE6` lam | the face of a Đông Sơn bronze drum radiating light (mặt trống đồng) |
| Experience | Kinh nghiệm | `#A166D6` tím | a reed flag / reed plume (cờ lau, bông lau — tích Đinh Bộ Lĩnh) |

**Bản cường hóa — 1 template cho cả 5 viên:** chạy lại prompt viên gốc rồi nối:

```
ENHANCED VARIANT: same gem and emblem, but empowered — wrapped in an
ornate gold-leaf filigree rim, brighter radiant aura, four small sparkle
glints at the corners, richer saturation. Reads as a rare upgrade.
```

> Code hiện vẽ viền/sparkle phủ lên texture gốc. Muốn texture riêng cho bản
> cường hóa thì thêm slot `enhanced_texture` vào `TileDefinition`.

## 2) Chân dung nhân vật (3 combatant hiện có)

**Spec:** canvas **dọc 768×1024** (hoặc vuông 1024 cho khung tròn HUD), bán
thân, nền trong suốt/mờ tối giản, sáng từ trên. Slot: `portrait` trong
`game/data/combatants/*.tres`. (Map đúng `hero/bandit/warlord` đang dùng.)

**Hero — Anh hùng** (`#4D80D9` lam, chính nghĩa):
```
[STYLE block] + Subject: half-body portrait of a young righteous Vietnamese
hero, inspired by the boy-general Đinh Bộ Lĩnh who drilled troops with reed
flags (cờ lau tập trận). Blue-toned áo giao lĩnh robe over light leather
armor, top-knot hair, calm determined gaze, holding a reed-flag spear.
Heroic, noble, warm key light.
```

**Bandit — Tên cướp** (`#994040` đỏ thẫm, máu thấp, cướp vàng):
```
[STYLE block] + Subject: half-body portrait of a lean cunning Vietnamese
highway bandit. Ragged dark-red sash and worn tunic, conical nón pulled
low shadowing a sly grin, a curved dagger at the hip, a bulging sack of
stolen square-holed coins over one shoulder. Shifty, agile, roguish.
```

**Warlord — Sứ quân** (`#734D8C` tím, giáp dày, hung hãn):
```
[STYLE block] + Subject: half-body portrait of an imposing 10th-century
Vietnamese warlord, one of the Twelve Warlords. Purple-and-black war robe
over heavy bronze lamellar armor, fur-trimmed pauldrons, stern commanding
scowl, gripping a long đao saber, a war banner behind. Powerful,
intimidating, cold rim light.
```

## 3) Icon kỹ năng (5)

**Spec:** canvas **vuông 256×256**, biểu tượng đậm, nền trong suốt, hào quang
màu theo hệ. Slot: `icon` trong `game/data/skills/*.tres`.

**Fire Bomb — Hỏa pháo** (sát thương + phá vùng 2×2):
```
[STYLE block] + Subject: skill icon of a thrown ceramic fire-pot grenade
(hỏa cầu) bursting into orange-red flame and sparks. 256x256, transparent bg.
```

**Freeze — Đóng băng** (đóng băng địch 4 lượt):
```
[STYLE block] + Subject: skill icon of a sharp blue-white ice crystal cluster
with frost shards radiating outward, cold pale-cyan glow. 256x256, transparent bg.
```

**Poison — Kịch độc** (trúng độc mỗi lần swap):
```
[STYLE block] + Subject: skill icon of a green poison gourd-vial uncorked,
toxic emerald smoke and a coiled snake motif, sickly green glow. 256x256,
transparent bg.
```

**Stone Skin — Da đá** (miễn nhiễm đòn tấn công, +50% sát thương khác):
```
[STYLE block] + Subject: skill icon of a clenched fist sheathed in cracked
grey stone plating, earthy brown-grey tones, heavy silhouette. 256x256,
transparent bg.
```

**War Cry — Tiếng thét xung trận** (+2 sát thương mỗi viên đến hết trận):
```
[STYLE block] + Subject: skill icon of a roaring warrior's open-mouth profile
with concentric sound-wave rings and a small red-gold war banner, crimson-gold
glow. 256x256, transparent bg.
```

## 4) Icon vật phẩm (2)

**Spec:** canvas **vuông 256×256**, vật thể đơn, nền trong suốt. Slot: `icon`
trong `game/data/items/*.tres`.

**Armor Vest — Áo giáp** (`#808CA6`, +5 giáp):
```
[STYLE block] + Subject: item icon of a 10th-century Vietnamese leather
lamellar armor vest with bronze studs and lacquered plates, steel-grey
tones, front-on. 256x256, transparent bg.
```

**Ginseng — Nhân sâm** (`#D9B373`, hồi 50 máu):
```
[STYLE block] + Subject: item icon of a gnarled wild ginseng root with fine
tendrils and a few green leaves, warm tan-gold earthy tones, faint healing
glow. 256x256, transparent bg.
```

## 5) Mẹo đồng nhất & lắp vào game

- **Nhất quán:** tạo viên **Attack** trước làm ảnh mẫu phong cách, các asset sau
  dùng cùng **seed** + *reference/style image*. Luôn giữ nguyên block STYLE.
- **Nền trong suốt:** yêu cầu PNG alpha; nếu trả nền đặc, thêm `isolated on plain
  flat background for easy cutout`.
- **Tránh chữ:** giữ `no text` (chữ hiển thị do hệ i18n lo).
- **Xuất:** renderer Mobile + ETC2/ASTC → PNG bội số 2 (256/512/1024).

### Bảng tra nhanh (asset ↔ file `.tres` ↔ slot)

| Nhóm | File `.tres` | Slot |
|---|---|---|
| Tile (5) | `game/data/tiles/{attack,health,gold,energy,exp}.tres` | `texture` |
| Nhân vật (3) | `game/data/combatants/{hero,bandit,warlord}.tres` | `portrait` |
| Kỹ năng (5) | `game/data/skills/{fire_bomb,freeze,poison,stone_skin,war_cry}.tres` | `icon` |
| Vật phẩm (2) | `game/data/items/{armor_vest,ginseng}.tres` | `icon` |
