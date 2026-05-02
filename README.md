### Quản lý thư viện
## Sinh Viên Thực Hiện: LÊ ĐỖ HOÀNG THIỆN
## LỚP: K59KMT
## MSSV: K235480106068

## Phần 1: Thiết kế và Khởi tạo Cấu trúc Dữ liệu
Bước 1:Trỏ đúng vào Database đã tạo
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 104058" src="https://github.com/user-attachments/assets/9861d708-bcbc-48da-bc43-8ed720150245" />

Bước 2:Tạo Bảng và Thêm Dữ liệu (Phần 1)
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/1d856bc2-36d3-40b6-bfe8-d4cc6dbddc76" />
Ảnh chụp màn hình đoạn code T-SQL khởi tạo 3 loại hàm (Scalar, Inline TVF, Multi-statement TVF) phục vụ nghiệp vụ thư viện. Các thông báo lỗi "already an object named..." phía dưới là minh chứng xác nhận các hàm này đã được thực thi và lưu trữ thành công vào hệ thống.(do em trót bấm nút Execute nhiều lần, lần đầu nó đã tạo xong, lần sau nó báo là bảng đã có sẵn nên không tạo đè lên được nữa)

Còn đây là phần code em đã tạo
** Code SQL:*
```sql
-- 1. HÀM VÔ HƯỚNG (Trả về 1 giá trị duy nhất)
-- Mục đích: Tính tổng số sách mà một độc giả đang mượn (chưa trả)
CREATE FUNCTION fn_TongSachDangMuon (@MaDocGia INT)
RETURNS INT
AS
BEGIN
    DECLARE @TongSach INT;
    SELECT @TongSach = COUNT(*) 
    FROM [PhieuMuon] 
    WHERE [MaDocGia] = @MaDocGia AND [TrangThai] = 0; 
    RETURN ISNULL(@TongSach, 0);
END;
GO

-- 2. HÀM NỘI TUYẾN (Trả về một bảng dữ liệu)
-- Mục đích: Tìm kiếm các sách theo Thể loại và kho vẫn còn hàng
CREATE FUNCTION fn_TimSachTheoTheLoai (@TheLoai NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT [MaSach], [TenSach], [GiaTien], [SoLuongTon]
    FROM [Sach]
    WHERE [TheLoai] = @TheLoai AND [SoLuongTon] > 0
);
GO

-- 3. HÀM ĐA CÂU LỆNH (Sử dụng biến bảng và logic phức tạp)
-- Mục đích: Đánh giá và dán nhãn tình trạng của từng cuốn sách trong kho
CREATE FUNCTION fn_ThongKeTinhTrangSach ()
RETURNS @BangThongKe TABLE (
    [MaSach] INT,
    [TenSach] NVARCHAR(200),
    [SoLuong] INT,
    [TinhTrang] NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @BangThongKe
    SELECT 
        [MaSach], [TenSach], [SoLuongTon],
        CASE 
            WHEN [SoLuongTon] = 0 THEN N'Hết hàng'
            WHEN [SoLuongTon] < 3 THEN N'Sắp hết'
            ELSE N'Sẵn sàng'
        END
    FROM [Sach];
    RETURN;
END;
GO
```

## Phần 2: xây dựng FUNCTION
Bước 1: Kết quả thực thi (Chạy thử hàm)

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/cead57e5-10f2-4642-bea3-1f3b8f92b8b8" />


> **Chú thích ảnh:** > * **Bảng phía trên:** Là kết quả em đã chạy thử **Hàm vô hướng** `fn_TongSachDangMuon`. Hàm đã đếm và trả về chính xác tổng số lượng sách mà mỗi độc giả đang mượn.
> * **Bảng phía dưới:** Là kết quả chạy thử **Hàm nội tuyến** `fn_TimSachTheoTheLoai`. Hàm đã lọc thành công ra danh sách các cuốn sách thuộc thể loại 'Kỹ năng' và có số lượng tồn kho lớn hơn 0.

đây là phần code ạ:

```sql
USE [QuanLyThuVien_K235480106068];
GO

-- Lệnh 1: Xem số sách mỗi người đang mượn
SELECT [MaDocGia], [TenDocGia], dbo.fn_TongSachDangMuon([MaDocGia]) AS [SoSachDangGiu] FROM [DocGia];

-- Lệnh 2: Tìm các sách thuộc thể loại 'Kỹ năng'
SELECT * FROM dbo.fn_TimSachTheoTheLoai(N'Kỹ năng');

-- Lệnh 3: Xem báo cáo tình trạng kho sách
SELECT * FROM dbo.fn_ThongKeTinhTrangSach();
```
Bước 2:Kiểm tra Hàm đa câu lệnh báo cáo chi tiết tình trạng kho sách.
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 114524" src="https://github.com/user-attachments/assets/3ba91d41-6ab0-42fb-8883-6ec1138dea45" />
ở đây em đã kiểm tra được tình trạng kho sách.
em đã dùng dòng lệnh phía dưới này để kiểm tra kết quả
```sql
SELECT * FROM dbo.fn_ThongKeTinhTrangSach();
```
## Phần 3: Xây dựng Store Procedure.







