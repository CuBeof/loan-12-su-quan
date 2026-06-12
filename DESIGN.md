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
