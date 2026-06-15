# Tổng quan
- Game offline match-3 RPG
- Dành cho điện thoại Android với nhiều kích thước màn hình
- Sử dụng công cụ godot 4.6 (latest)
- Nội dung game viết bằng tiếng Anh (mặc định); hỗ trợ đa ngôn ngữ qua hệ thống translation (khóa dịch → en/vi), không hardcode text hiển thị
- Thư mục `example` là một game match-3 cơ bản với đầy đủ hiệu ứng, âm thanh. Game hoàn toàn có thể chơi được. Tham khảo nếu cần.

# Cơ chế
- Bàn cờ kích thước tối đa 8x8, có thể thay đổi hình dạng và kích thước tùy vào màn chơi
- 5 loại tiles: tấn công, máu, tiền, năng lượng và kinh nghiệm.
- Người chơi và máy luân phiên di chuyển tile trên bàn cờ chung, ghép quân để chiếm lợi thế hoặc phá nước đi tiếp theo của đối phương
- Cơ chế ghép (cập nhật 2026-06-15):
  - **Ghép 3**: ăn 3 viên, không hiệu ứng thêm.
  - **Ghép 4 thẳng**: ăn 4 viên + **thêm 1 lượt đi**.
  - **Ghép 5 thẳng**: ăn 5 viên + **thêm 1 lượt đi** + **phá huỷ 3 viên bất kỳ trên bàn cờ** (hiệu ứng sét).
  - **Ghép chữ L/T**: ăn các viên + **phá huỷ 3 viên ngẫu nhiên xung quanh vị trí match** (bán kính 2, hiệu ứng sét). Không thêm lượt.
- **Viên cường hoá**: mỗi loại ngọc có phiên bản cường hoá, sinh ngẫu nhiên (khi refill/khởi tạo). Khi ăn, viên cường hoá tính **gấp đôi** giá trị viên thường (hiển thị viền sáng + sparkle).
- **Combo**: sau mỗi lần refill mà vẫn có match (cascade), combo tăng 1 (combo bắt đầu từ 1 cho match từ swap). **Giá trị của mỗi đợt ăn được nhân với combo** của đợt đó.
- **Giới hạn thêm lượt**: tối đa **+2 lượt** trong một lượt đi của người chơi — dù cascade vô tình tạo nhiều match-4/5 liên tiếp cũng chỉ cộng tối đa 2.
- Swap không tạo được match nào (nước đi hỏng) sẽ bị hoàn về vị trí cũ và bị tính là đối phương tấn công với sát thương tương đương 2 viên tấn công.
- **Giáp**: giảm sát thương phẳng mỗi đòn; một đòn khác 0 luôn gây tối thiểu 1 sát thương (không thể bất tử nhờ giáp). **Xuyên giáp** trừ trực tiếp vào giáp đối phương trước khi tính. Nguồn giáp (mỗi nguồn là một modifier có vòng đời riêng):
  - Chỉ số của nhân vật, thay đổi theo loại nhân vật và level (vĩnh viễn)
  - Trang bị như áo giáp (vĩnh viễn khi còn mặc)
  - Vật phẩm, duy trì qua nhiều trận
  - Kỹ năng, chỉ trong trận
  - Buff từ NPC, duy trì qua nhiều trận
  - Nội tại của mỗi vùng trên bản đồ (chỉ trong trận đánh ở vùng đó)
  - Sẽ phát triển thêm các nguồn khác sau này
- ghép tấn công sẽ tấn công trừ máu đối phương, máu về 0 sẽ thua, bị trừ một mạng, lượng máu mất sẽ duy trì qua trận đấu tiếp theo. Mạng sẽ hồi theo thời gian, ngẫu nhiên qua match-5 hoặc nạp tiền
  - **Hiệu ứng & thứ tự**: ngay khi ghép được viên tấn công, kiếm bay về phía đối thủ gây sát thương (có thể chí mạng — `crit_chance` %, `crit_damage` % sát thương); sát thương được áp dụng theo từng đợt ghép, TRƯỚC khi các hiệu ứng nổ/quét/biến đổi/refill của đợt đó diễn ra. Chí mạng hiện số damage to màu đỏ + rung màn hình.
- ghép máu sẽ hồi lại máu đã mất, một số tướng và quái vật có thể hồi vượt lượng tối đa và biến thành một dạng buff tùy nhân vật
- ghép năng lượng sẽ hồi năng lượng, dùng để sử dụng skill
- **Kỹ năng**: tốn năng lượng, mặc định dùng xong sẽ kết thúc lượt (có cờ giữ lượt cho kỹ năng đặc biệt). Hiệu ứng kỹ năng là data-driven, gồm các loại: sát thương trực tiếp (tương đương N viên tấn công), phá vùng bàn cờ ngẫu nhiên, trạng thái có thời hạn theo lượt (đóng băng — mất lượt; độc — mất máu mỗi lần swap; miễn nhiễm theo nguồn sát thương; tăng % sát thương phải nhận), và chỉnh bất kỳ chỉ số nào qua modifier. Số kỹ năng mỗi nhân vật có thể thay đổi; ví dụ hiện tại: người chơi 3 kỹ năng (Hỏa pháo 20 / Đóng băng 40 / Kịch độc 60), AI 1 kỹ năng (Da đá 20). Chỉ số trong ví dụ chưa cân bằng.
- Ghép vàng sẽ tích lũy vàng sau màn chơi nếu thắng trận, một số kẻ thù có thể ghép vàng để cướp vàng đang có của người chơi hoặc dùng để mua một số item đặc biệt chỉ quái vật mới dùng được trong màn chơi đó
- ghép kinh nghiệm sẽ tích lũy kinh nghiệm để lên cấp cho nhân vật sau màn chơi nếu thắng, một số kẻ thù cũng có thể dùng kinh nghiêmk để cường hoá kỹ năng hoặc chỉ số trong màn chơi đó
- Có cây kỹ năng dùng để mở khoá kỹ năng mới, dùng điểm kỹ năng để mở khoá, điểm kỹ năng nhận được khi nhân vật lên cấp
- Có cửa hàng để mua các vật phẩm trong game
- Có các địa điểm đặc biệt phục vụ các sự kiện trong game

# Màn hình:
## Màn hình chính khi mới vào game:
- Tiếp tục
- Chơi mới
- Cài đặt
- Thông tin
## Màn hình cài đặt
### Tab âm thanh
- Bật tắt âm thanh game, âm lượng
- Bật tắt hiệu ứng âm thanh, âm lượng
- Bật tắt nhạc nền, âm lượng

### Tab trải nghiệm người dùng
- Chứa danh sách các tùy chọn về tốc độ hiệu ứng, hint, chỉ dẫn ingame... (Triển khai dần trong quá trình phát triển)

### Tab về ngôn ngữ và liên kết tài khoản
- Triển khai trong các giai đoạn sau

## Màn hình bản đồ
Chứa các node thể hiện địa điểm trong game, người chơi chỉ có thể đi qua lại giữa 2 node đã được kết nối, một vài trường hợp các đường nối có thể bị chặn bởi các sự kiện trong game.

## Màn hình shop
Hàng 1: avatar người chơi - avatar shop keeper
Hàng 2: nút trở về - nút khác thiết kế sau
Danh mục sản phẩm, bấm vào sản phẩm hiển thị popup chi tiết

## Màn hình cây kỹ năng
Dạng cây với các nhánh, bấm vào kỹ năng hiển thị popup chi tiết

## Màn hình balo
Hàng đầu là avatar người chơi cùng các chỉ số của người chơi
Vật phẩm trong balo thể hiện ở dạng lưới, nhấn vào hiển thị popup chi tiết vật phẩm

## Màn hình chiến đấu
- Bảng match 3 ở giữa
- Bên trên là đối thủ với thanh máu, thanh mana với chỉ số hiện tại
- Một số đối thủ có thể có thanh khác như thanh vàng của tên cướp, đầy thì tên cướp bỏ chạy cùng với số vàng đi và bạn thua
- Kỹ năng, sẽ bị mờ đi khi chưa đủ năng lượng
- Bên dưới là người chơi với các thông tin tương tự với máy
- Đối thủ có thể hiển thị khung chat để hiển thị câu thoại trong trận
- Góc trên bên trái là nút rút lui, khi rút lui sẽ bị xử thua và trừ một mạng

# Người chơi 
- Khi bắt đầu người chơi có thể chọn một trong nhiều nhân vật, mỗi nhân vật sẽ có bộ chỉ số, kỹ năng và cây kỹ năng riêng

# Đối thủ
- Là AI do máy điều khiển chiến đấu với người chơi
- Có nhiều loại nhân vật với các chỉ số, kỹ năng, lời thoại, hành vi khác nhau. Các hành vi có thể là: tên cướp có máu thấp hơn các hệ khác, nhưng có khả năng cướp vàng từ người chơi, khi hắn cướp được một lượng vàng nhất định hoặc người chơi hết vàng sẽ bỏ trốn, đánh thắng hắn sẽ lấy lại được vàng, xu hướng ghép các đồng vàng, kỹ năng liên quan đến vàng.
- **Hành vi AI là data-driven** qua `AIProfile` (.tres): trọng số ưu tiên từng loại tile, độ khó (xác suất chọn nước tốt nhất vs ngẫu nhiên), xu hướng dùng skill. AI mô phỏng từng nước đi trên bản sao bàn cờ rồi chấm điểm theo profile. Thêm tính cách mới = thêm `.tres`, không sửa code. Hai tính cách demo hiện có: **ưu tiên tấn công** (sứ quân) và **ưu tiên hồi máu** (tên cướp — trọng số máu cao, càng ít máu càng ưu tiên ghép viên máu).

# Hệ thống tính điểm, thiết kế quái vật/boss và cân bằng
Sẽ thực hiện ở giai đoạn sau.
