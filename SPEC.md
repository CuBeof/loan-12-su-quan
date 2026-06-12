# Tổng quan
- Game offline match-3 RPG
- Dành cho điện thoại Android với nhiều kích thước màn hình
- Sử dụng công cụ godot 4.6 (latest)
- Thư mục `example` là một game match-3 cơ bản với đầy đủ hiệu ứng, âm thanh. Game hoàn toàn có thể chơi được. Tham khảo nếu cần.

# Cơ chế
- Bàn cờ kích thước tối đa 8x8, có thể thay đổi hình dạng và kích thước tùy vào màn chơi
- 5 loại tiles: tấn công, máu, tiền, năng lượng và kinh nghiệm.
- Người chơi và máy luân phiên di chuyển tile trên bàn cờ chung, ghép quân để chiếm lợi thế hoặc phá nước đi tiếp theo của đối phương
- Nếu nhân vật hoặc đối phương ghép được nhiều hơn 3 viên cùng một hàng thì sẽ được thêm lượt đi.
- Ghép 4 sẽ ăn 4 viên đó và tạo viên cường hoá (viên quét) cùng loại xoá hàng ngang hoặc hàng dọc toàn bàn cờ tùy theo cách nó được ghép
- Ghép 5 viên sẽ ăn 5 viên, chỉ số mỗi viên tăng x lần, để lại viên cường hoá (viên biến đổi), khi ghép viên cường hoá với bất kỳ viên nào sẽ ăn toàn bộ viên cùng loại trên bàn cờ, đồng thời có xác xuất rơi ra đồ.
- ghép hình chữ L hoặc chữ T sẽ ăn và tạo ra viên nổ cùng loại, nếu viên nổ được ghép các viên được ghép sẽ bị ăn trước, sau khi viên mới rơi xuống sẽ tạo ra một vụ nổ 3x3 quanh vị trí cuối cùng của viên nổ, nếu 2 viên nổ được ghép sẽ tạo tăng lượt, chỉ số vụ nổ tăng x lần, nếu ghép viên nổ và viên ghép sẽ tạo ra hiệu ứng quét 2 hàng hoặc 2 cột.
- Ghép viên biến đổi và viên nổ sẽ biến tất cả viên cùng loại thành viên nổ, ghép viên biến đổi và viên quét sẽ biến tất cả viên cùng loại thành viên quét với chiều ngẫu nhiên 
- ghép tấn công sẽ tấn công trừ máu đối phương, máu về 0 sẽ thua, bị trừ một mạng, lượng máu mất sẽ duy trì qua trận đấu tiếp theo. Mạng sẽ hồi theo thời gian, ngẫu nhiên qua match-5 hoặc nạp tiền
- ghép máu sẽ hồi lại máu đã mất, một số tướng và quái vật có thể hồi vượt lượng tối đa và biến thành một dạng buff tùy nhân vật
- ghép năng lượng sẽ hồi năng lượng, dùng để sử dụng skill
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

# Hệ thống tính điểm, thiết kế quái vật/boss và cân bằng
Sẽ thực hiện ở giai đoạn sau.
