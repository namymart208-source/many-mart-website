# NAMY MART — GitHub + Cloudflare Pages + Supabase

Bản giao diện chạy sẵn, không cần cài Node.js trên máy. Giao diện song ngữ Việt–Anh; menu, thư viện ảnh và admin email/mật khẩu.

Tên cửa hàng đã được cập nhật thành NAMY MART trên toàn bộ trang giới thiệu, Menu, Hình ảnh và Admin. Có 8 ảnh đính kèm mới trong thư viện; không bổ sung ảnh cigar vào website quảng bá.

## 1. Tạo bảng và kho ảnh trong Supabase

Mở project mới của cửa hàng → SQL Editor → New query.
Mở `setup/01-database.sql`, sao chép toàn bộ nội dung, dán vào SQL Editor và nhấn Run.
Script tạo bảng danh mục/sản phẩm/ảnh, bảng quyền quản trị, RLS và bucket `namy-images`.
Chỉ chạy trong project mới dành riêng cho cửa hàng. Không chạy trong project khác đang có dữ liệu.

Các danh mục khởi tạo: Rượu vang, Rượu mạnh, Bia và Thực phẩm. Admin được thêm danh mục phù hợp khác. Không có dữ liệu sản phẩm/giá giả.

## 2. Tạo tài khoản Admin

Supabase → Authentication → Users → Add user → Create new user.
Nhập email của admin và mật khẩu mạnh do anh tự đặt. Chọn Auto Confirm User nếu có.
Không gửi mật khẩu trong chat hoặc đưa mật khẩu vào GitHub.

Mở `setup/02-admin.sql`, thay `YOUR_ADMIN_EMAIL` bằng email vừa tạo.
Dán nội dung vào SQL Editor và Run. Script sẽ báo lỗi nếu email chưa tồn tại.
Chỉ chạy script này từ Dashboard. Người đăng ký thông thường không tự trở thành Admin.
Trong cấu hình Supabase Auth, có thể tắt tạo tài khoản mới nếu không cần cho người khác đăng ký.

## 3. Kết nối website

Trong project Supabase, mở Connect để lấy Project URL và Publishable key.
Hoặc Settings → API Keys để lấy Publishable key (`sb_publishable_...`). Legacy anon key cũng được hỗ trợ.
Mở `site/config.js` và thay hai giá trị:

    url: "https://PROJECT-ID.supabase.co",
    publishableKey: "sb_publishable_..."

Chỉ dùng Publishable key/anon key. Không dùng secret key, service_role key hoặc mật khẩu database.
Hai giá trị này được đọc bởi trình duyệt; quyền đọc/ghi được bảo vệ bởi RLS và Supabase Auth.

## 4. Đưa lên GitHub bằng trình duyệt

Tạo repository mới, ví dụ `many-mart-website`.
Giải nén gói ZIP trên máy. Mở thư mục bên trong.
GitHub → Add file → Upload files → kéo các thư mục/file bên trong vào.
Không upload nguyên file ZIP. Không lồng thêm một thư mục cha bên ngoài `site/`.
Sau khi upload, trang đầu repository cần thấy thư mục `site` và `setup`.
Đảm bảo đã sửa `site/config.js`; commit thay đổi.

## 5. Triển khai Cloudflare Pages

Cloudflare Dashboard → Workers & Pages → Create application → Pages → kết nối GitHub.
Chọn repository vừa tạo và nhánh `main`.

| Cấu hình | Giá trị |
|---|---|
| Framework preset | None |
| Build command | `exit 0` |
| Build output directory | `site` |
| Root directory | Để trống nếu `site/` nằm ngay trong repository |

Save and Deploy. Dùng URL Pages trả về, không dùng URL GitHub làm địa chỉ website.
Bản này đã chuyển xử lý dữ liệu sang Supabase nên Cloudflare Pages chỉ cần phục vụ HTML/CSS/JS/ảnh/font có sẵn.
Không cần D1, R2 hoặc cơ chế đăng nhập của ChatGPT Sites cho bản này.
File `worker-wrangler.example.jsonc` chỉ là cấu hình tham khảo nếu sau này muốn dùng Workers Static Assets; không cần cho Pages.

## 6. Sử dụng

- `/`: trang giới thiệu.
- `/menu`: danh mục, tìm kiếm và sản phẩm đã xuất bản.
- `/gallery`: xem ảnh, mở ảnh lớn.
- `/admin`: đăng nhập bằng email/mật khẩu ở bước 2.

Admin → Thêm mới → điền tiếng Việt và tiếng Anh → chọn danh mục, giá, tải ảnh → chọn Xuất bản → Lưu nội dung.
Chọn Bản nháp để ẩn. Ẩn danh mục sẽ ẩn các sản phẩm bên trong đối với khách.
Ảnh JPG/PNG/WebP, tối đa 8 MB. Bucket ảnh là công khai: chỉ upload ảnh giới thiệu cửa hàng/sản phẩm, không upload tài liệu nội bộ.
Xóa bài đăng không tự xóa file ảnh khỏi bucket để tránh làm hỏng liên kết được dùng lại. Có thể dọn ảnh không dùng trong Supabase Storage.

## 7. Kiểm tra trước khi gửi khách

1. Dùng cửa sổ ẩn danh mở trang chủ, Menu, Hình ảnh: không yêu cầu đăng nhập.
2. Mở Admin: phải đăng nhập; người không được cấp quyền không chỉnh sửa được.
3. Thêm một sản phẩm bản nháp: khách không thấy. Chọn Xuất bản: khách thấy.
4. Tải ảnh và kiểm tra trên điện thoại.
5. Kiểm tra địa chỉ 208 Đỗ Bá, Đà Nẵng và điện thoại 0901 175 767.
6. Kiểm tra mục Database/Security Advisor của Supabase để xác nhận các bảng có RLS.

## Nếu có lỗi

- Báo cần cấu hình: kiểm tra `site/config.js`, commit GitHub và chờ Cloudflare deploy lại.
- Không tải dữ liệu: xác nhận đã chạy SQL 01 đúng project và dùng đúng URL/key.
- Đăng nhập được nhưng chưa có quyền: kiểm tra SQL 02 dùng đúng email tài khoản Auth.
- Không tải ảnh: kiểm tra bucket namy-images, đã chạy policies và ảnh <=8 MB.
- Không xóa được danh mục: chuyển hoặc xóa sản phẩm trong danh mục trước.
- Supabase project chưa được cấu hình/xác thực: website hiển thị thông báo lỗi, không có chế độ giả lập dữ liệu thành công.

## Kiểm tra đã thực hiện khi đóng gói

Đã kiểm tra cú pháp JavaScript, biên dịch giao diện và các luồng API với dữ liệu mô phỏng: public/admin, lọc bản nháp, đăng nhập và upload. Chưa kết nối project Supabase của anh vì chưa có URL/key; SQL cần được chạy và kiểm tra trong project đó. Không có dữ liệu từ website ChatGPT Sites được tự chuyển sang project mới.

## Nguồn tham khảo

- https://supabase.com/docs/guides/getting-started/api-keys
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/storage/security/access-control
- https://developers.cloudflare.com/pages/framework-guides/deploy-anything/

## Cập nhật từ bản cũ

Giữ nguyên `site/config.js` anh đã cấu hình với project Supabase. Thay các file giao diện và thư mục ảnh bằng bản mới, sau đó khôi phục file config.js của anh. Không cần chạy lại SQL nếu đã cài đặt bản trước. Bản này không tự thay đổi dữ liệu sản phẩm hoặc tài khoản Admin trong Supabase.

## Nếu đang dùng Cloudflare Workers (project many-mart-website)

Gói mới có `wrangler.jsonc` ngay gốc repository để xuất bản thư mục `site/`. Giữ Root directory tại gốc repository; Build command để trống (hoặc `exit 0` nếu bắt buộc); Deploy command `npx wrangler deploy`. Không upload ZIP trực tiếp lên GitHub; giải nén và cập nhật file. Không cần tạo lại project đang có. URL do Cloudflare hiển thị trong Domains được giữ nguyên.

Nếu dùng Cloudflare Pages, chọn output directory `site` như hướng dẫn ở trên; không cần lệnh Wrangler.
