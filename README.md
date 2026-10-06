# BÁO CÁO BÀI THỰC HÀNH 4: QUẢN LÝ TIẾN TRÌNH NỀN VỚI NOHUP VÀ TÍN HIỆU KILL

## 1. Mục tiêu bài lab
- Nắm vững cách khởi chạy tiến trình chạy ngầm (Background Process) độc lập với phiên làm việc Terminal bằng tiện ích `nohup` và toán tử `&`.
- Thành thạo việc giám sát tiến trình hệ thống bằng các công cụ: `ps`, `pgrep`, `top`/`htop`.
- Theo dõi sự biến đổi tệp tin nhật ký liên tục với lệnh `tail`.
- Hiểu rõ cơ chế và sử dụng thành thạo lệnh `kill` với các tín hiệu hệ thống (POSIX Signals) như `SIGTERM` (15) và `SIGKILL` (9).

---

## 2. Nhật ký các bước thực hiện

### Bước 1: Tạo kịch bản Shell Script `loop-monitor.sh`
Tạo tệp kịch bản thực hiện ghi thời gian hệ thống vào tệp `/tmp/monitor.log` định kỳ mỗi 5 giây:

```bash
cat << 'EOF' > loop-monitor.sh
#!/bin/bash

# Script giam sat ghi thoi gian he thong vao file log
# File luu log: /tmp/monitor.log
# Chu ky: 5 giay / lan

echo "=== Bat dau khao sat monitor: $(date) ===" >> /tmp/monitor.log

while true; do
    echo "System time: $(date)" >> /tmp/monitor.log
    sleep 5
done
EOF
```

Gán quyền thực thi cho file script:
```bash
chmod +x loop-monitor.sh
```

---

### Bước 2: Khởi chạy tiến trình chạy nền độc lập với `nohup`

Chạy script với `nohup` và đưa vào chế độ nền (`&`):

```bash
nohup ./loop-monitor.sh > /dev/null 2>&1 &
```

*Giải thích các thành phần*:
- `nohup` (No Hang Up): Bỏ qua tín hiệu `SIGHUP` gửi tới tiến trình khi phiên Terminal bị đóng hoặc người dùng thoát SSH.
- `> /dev/null 2>&1`: Chuyển hướng cả đầu ra chuẩn (`stdout`) và lỗi chuẩn (`stderr`) vào thiết bị rỗng `/dev/null` (do dữ liệu đã được script tự ghi vào `/tmp/monitor.log`).
- `&`: Đưa tiến trình chạy dưới nền (Background), giải phóng Terminal ngay lập tức.

---

### Bước 3: Tìm PID và giám sát tiến trình

#### 3.1. Tìm số định danh tiến trình (PID):
```bash
ps aux | grep loop-monitor.sh
# Hoặc dùng lệnh pgrep:
pgrep -f loop-monitor.sh
```

**Kết quả hiển thị (Output):**
```text
ubuntu     24581  0.0  0.1   7340  3210 pts/0    S    15:47   0:00 /bin/bash ./loop-monitor.sh
ubuntu     24590  0.0  0.0   6432   720 pts/0    S+   15:47   0:00 grep --color=auto loop-monitor.sh
```
> $\rightarrow$ **PID của tiến trình là:** `24581`

#### 3.2. Kiểm tra dữ liệu log được ghi liên tục:
```bash
tail -n 10 /tmp/monitor.log
```

**Kết quả hiển thị (Output):**
```text
=== Bat dau khao sat monitor: Tue Oct  6 15:47:00 UTC 2026 ===
System time: Tue Oct  6 15:47:05 UTC 2026
System time: Tue Oct  6 15:47:10 UTC 2026
System time: Tue Oct  6 15:47:15 UTC 2026
System time: Tue Oct  6 15:47:20 UTC 2026
System time: Tue Oct  6 15:47:25 UTC 2026
System time: Tue Oct  6 15:47:30 UTC 2026
System time: Tue Oct  6 15:47:35 UTC 2026
System time: Tue Oct  6 15:47:40 UTC 2026
System time: Tue Oct  6 15:47:45 UTC 2026
```

---

### Bước 4: Tắt tiến trình an toàn bằng tín hiệu `SIGTERM`

Gửi tín hiệu dừng an toàn `SIGTERM` (mã tín hiệu `15`):

```bash
kill -15 24581
```

*Lưu ý*: Trong trường hợp tiến trình bị treo không phản hồi với `SIGTERM`, mới sử dụng tín hiệu buộc dừng khẩn cấp `SIGKILL` (mã tín hiệu `9`):
```bash
# Chỉ dùng khi thực sự cần thiết:
kill -9 24581
```

---

### Bước 5: Kiểm tra xác nhận tiến trình đã được dừng hoàn toàn

```bash
ps aux | grep loop-monitor.sh
```

**Kết quả hiển thị (Output):**
```text
ubuntu     24605  0.0  0.0   6432   720 pts/0    S+   15:48   0:00 grep --color=auto loop-monitor.sh
```
> Tiến trình `24581` đã không còn tồn tại trong danh sách tiến trình đang hoạt động.

---

## 3. Bảng so sánh các tín hiệu Kill thông dụng

| Tên tín hiệu (Signal) | Mã số (Value) | Mô tả & Cách hoạt động | Trường hợp sử dụng |
| :--- | :---: | :--- | :--- |
| **SIGTERM** | `15` | Tín hiệu yêu cầu kết thúc an toàn. Cho phép tiến trình dọn dẹp tài nguyên, lưu dữ liệu, đóng file log trước khi thoát. | **Mặc định / Khuyến nghị đầu tiên** khi muốn tắt ứng dụng hoặc dịch vụ. |
| **SIGKILL** | `9` | Tín hiệu buộc dừng lập tức do Kernel xử lý trực tiếp. Tiến trình không thể bắt (catch) hoặc bỏ qua tín hiệu này. | Dùng khi tiến trình bị treo hoàn toàn (deadlock), không phản hồi với `SIGTERM`. |
| **SIGHUP** | `1` | Tín hiệu ngắt kết nối (Hangup). Được gửi khi terminal đóng. Thường được các daemon dùng để reload lại file cấu hình. | Tải lại cấu hình (Nginx/Apache) mà không cần restart service. |
| **SIGINT** | `2` | Tín hiệu ngắt từ bàn phím (tương đương nhấn `Ctrl + C`). | Dừng tiến trình đang chạy trực tiếp trên foreground terminal. |
