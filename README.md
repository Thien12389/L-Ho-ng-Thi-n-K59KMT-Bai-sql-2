### Quản lý thư viện
## Sinh Viên Thực Hiện: LÊ ĐỖ HOÀNG THIỆN
## LỚP: K59KMT
## MSSV: K235480106068

## Phần 1: Thiết kế và Khởi tạo Cấu trúc Dữ liệu
Bước 1:Đây là bước khởi tạo Database và cấu trúc các bảng (Độc giả, Sách, Phiếu mượn) cùng dữ liệu mẫu ban đầu để hệ thống có thể hoạt động.
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 104058" src="https://github.com/user-attachments/assets/9861d708-bcbc-48da-bc43-8ed720150245" />

Bước 2:Tạo Bảng và Thêm Dữ liệu (Phần 1)
 <img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 215746" src="https://github.com/user-attachments/assets/8ad72e84-d619-4f77-8d31-57908da6a4ed" />

Còn đây là phần code em đã tạo
** Code SQL:*
```sql
USE [QuanLyThuVien_K235480106068];
GO

-- 1. Xóa các bảng cũ nếu đã tồn tại
DROP TABLE IF EXISTS [PhieuMuon];
DROP TABLE IF EXISTS [Sach];
DROP TABLE IF EXISTS [DocGia];
GO

-- 2. Tạo bảng Độc Giả (MaDocGia là Khóa chính - PK)
CREATE TABLE [DocGia] (
    [MaDocGia] INT PRIMARY KEY,
    [TenDocGia] NVARCHAR(100)
);

-- 3. Tạo bảng Sách (MaSach là Khóa chính - PK)
CREATE TABLE [Sach] (
    [MaSach] INT PRIMARY KEY,
    [TenSach] NVARCHAR(200),
    [TheLoai] NVARCHAR(50),
    [GiaTien] MONEY,
    [SoLuongTon] INT
);

-- 4. Tạo bảng Phiếu Mượn (Có Khóa ngoại - FK liên kết với bảng Sách và Độc giả)
CREATE TABLE [PhieuMuon] (
    [MaPhieu] INT IDENTITY(1,1) PRIMARY KEY,
    [MaDocGia] INT FOREIGN KEY REFERENCES [DocGia]([MaDocGia]),
    [MaSach] INT FOREIGN KEY REFERENCES [Sach]([MaSach]),
    [NgayMuon] DATETIME,
    [NgayTra] DATETIME,
    [TrangThai] INT -- 0: Đang mượn, 1: Đã trả
);
GO

-- 5. Thêm dữ liệu mẫu vào các bảng
INSERT INTO [DocGia] ([MaDocGia], [TenDocGia]) 
VALUES (1, N'Lê Đỗ Hoàng Thiện'), (2, N'Nguyễn Văn A');

INSERT INTO [Sach] ([MaSach], [TenSach], [TheLoai], [GiaTien], [SoLuongTon]) 
VALUES 
(1, N'Lập trình SQL', N'Công nghệ', 150000, 5),
(2, N'Đắc Nhân Tâm', N'Kỹ năng', 80000, 2),
(3, N'Cấu trúc dữ liệu', N'Công nghệ', 120000, 0);

INSERT INTO [PhieuMuon] ([MaDocGia], [MaSach], [NgayMuon], [NgayTra], [TrangThai])
VALUES (1, 1, '2024-04-01', '2024-04-10', 0);
GO
```

## Phần 2: xây dựng FUNCTION
# 1. Lý thuyết về Function trong SQL Server
Các loại function built-in (hàm có sẵn): - SQL Server cung cấp sẵn các nhóm hàm như: Hàm toán học (ABS, ROUND), Hàm chuỗi (LEN, UPPER, SUBSTRING), Hàm ngày tháng (GETDATE, DATEDIFF), và các Hàm tổng hợp (SUM, AVG, COUNT).

Ví dụ đặc sắc: Em thường xuyên sử dụng hàm DATEDIFF để tính toán số ngày quá hạn của phiếu mượn và hàm GETDATE() để lấy thời gian thực tế khi phát sinh giao dịch.

Mục đích của User-Defined Function (Hàm tự viết): - Dùng để đóng gói các logic tính toán phức tạp hoặc các quy tắc nghiệp vụ riêng của thư viện (như công thức tính tiền phạt, phân loại độc giả) để tái sử dụng ở nhiều nơi.

Các loại hàm tự viết: 
+ Scalar Function (Hàm vô hướng): Trả về một giá trị đơn duy nhất.
+ Inline Table-Valued Function (Hàm nội tuyến): Trả về một bảng dữ liệu, đóng vai trò như một khung nhìn (View) có tham số.
+  Multi-statement Table-Valued Function (Hàm đa câu lệnh): Trả về một bảng nhưng cho phép viết nhiều câu lệnh logic phức tạp bên trong.
+ Khởi tạo các hàm nghiệp vụ (Code SQL)
# 2. Khởi tạo các hàm nghiệp vụ (Code SQL)
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/459d6b59-44b8-4a6a-a073-5c542eda9793" />
```code sql
USE [QuanLyThuVien_K235480106068];
GO

-- 1. HÀM VÔ HƯỚNG: Tính tổng số sách mà một độc giả đang mượn (chưa trả)
CREATE OR ALTER FUNCTION fn_TongSachDangMuon (@MaDocGia INT)
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

-- 2. HÀM NỘI TUYẾN: Tìm kiếm các sách theo Thể loại và kho vẫn còn hàng
CREATE OR ALTER FUNCTION fn_TimSachTheoTheLoai (@TheLoai NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT [MaSach], [TenSach], [GiaTien], [SoLuongTon]
    FROM [Sach]
    WHERE [TheLoai] = @TheLoai AND [SoLuongTon] > 0
);
GO

-- 3. HÀM ĐA CÂU LỆNH: Thống kê và đánh giá tình trạng kho sách (Sẵn sàng/Hết hàng)
CREATE OR ALTER FUNCTION fn_ThongKeTinhTrangSach ()
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

# 3. Kết quả thực thi
# 1: Chạy thử Hàm vô hướng và Hàm nội tuyến
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/fdbb5634-b815-4caf-8e6b-971d81fed5eb" />
- Bảng trên sử dụng hàm fn_TongSachDangMuon để đếm số sách mỗi người đang giữ.
- Bảng dưới sử dụng hàm fn_TimSachTheoTheLoai để lọc nhanh các sách thuộc nhóm 'Kỹ năng'.
```code sql
SELECT [MaDocGia], [TenDocGia], dbo.fn_TongSachDangMuon([MaDocGia]) AS [SoSachDangGiu] FROM [DocGia];
SELECT * FROM dbo.fn_TimSachTheoTheLoai(N'Kỹ năng');
```
# 2: Chạy thử Hàm đa câu lệnh (Báo cáo tồn kho)
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/31dd70ac-0549-42eb-b758-4c88021aed46" />
hàm này xử lý logic phức tạp hơn, tự động gắn nhãn "Sắp hết" hoặc "Hết hàng" dựa trên số lượng tồn thực tế trong kho.
```code sql
SELECT * FROM dbo.fn_ThongKeTinhTrangSach();
```

## Phần 3: Xây dựng Store Procedure (Kiến thức 10)

# 1. Store Procedure có sẵn trong hệ thống:
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 174811" src="https://github.com/user-attachments/assets/55866555-fafc-4f83-b502-e93125138b0a" />
Trong SQL Server, các System Store Procedure (có tiền tố `sp_`) là các thủ tục được Microsoft viết sẵn để hỗ trợ quản trị và truy xuất thông tin hệ thống.
 ** Một số SP tiêu biểu em tìm hiểu được:**
  * `sp_help 'Tên_Bảng'`: Trả về toàn bộ thông tin chi tiết về cấu trúc của một bảng (các cột, kiểu dữ liệu, ràng buộc). Rất hữu ích khi muốn xem nhanh thiết kế bảng.
   * `sp_rename 'Tên_Cũ', 'Tên_Mới'`: Dùng để đổi tên các đối tượng (bảng, cột) một cách an toàn.
  *`sp_helpdb`: Liệt kê tất cả các Database đang có trên Server kèm theo kích thước của chúng.

# 2. Store Procedure INSERT có kiểm tra điều kiện:
Logic của em: Viết SP `sp_ThemPhieuMuon` để thêm mới một phiếu mượn sách. Tuy nhiên, trước khi `INSERT`, SP phải kiểm tra xem cuốn sách đó có còn trong kho không (`SoLuongTon > 0`). Nếu còn mới cho mượn, nếu hết thì báo lỗi.
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 175129" src="https://github.com/user-attachments/assets/08dea00f-56a7-4d1c-addb-36fc4cc27ede" />

**Code SQL:**

```sql
CREATE OR ALTER PROCEDURE sp_ThemPhieuMuon
    @MaDocGia INT,
    @MaSach INT
AS
BEGIN
    DECLARE @TonKho INT;
    SELECT @TonKho = [SoLuongTon] FROM [Sach] WHERE [MaSach] = @MaSach;

    IF @TonKho > 0
    BEGIN
        INSERT INTO [PhieuMuon] ([MaDocGia], [MaSach], [NgayMuon], [TrangThai])
        VALUES (@MaDocGia, @MaSach, GETDATE(), 0);
        PRINT N'Thành công: Đã tạo phiếu mượn sách!';
    END
    ELSE
    BEGIN
        PRINT N'Thất bại: Sách này hiện đã hết trong kho!';
    END
END;
GO
```

# 3. Store Procedure có sử dụng tham số OUTPUT:
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 180107" src="https://github.com/user-attachments/assets/23a7d9a9-d7e1-4e97-923d-db83a6e047cd" />
em viết SP `sp_TinhTienPhat` để tính tổng số tiền phạt của một độc giả dựa trên số ngày mượn quá hạn. Kết quả không in ra màn hình ngay mà được trả về qua một biến `OUTPUT` để các chương trình bên ngoài có thể gọi và sử dụng tiếp.

```code sql
USE [QuanLyThuVien_K235480106068];
GO

CREATE OR ALTER PROCEDURE sp_TinhTienPhat
    @MaDocGia INT,
    @TongTienPhat MONEY OUTPUT
AS
BEGIN
    -- Phí phạt là 5000đ cho mỗi ngày quá hạn
    SELECT @TongTienPhat = SUM(DATEDIFF(DAY, [NgayTra], GETDATE()) * 5000)
    FROM [PhieuMuon]
    WHERE [MaDocGia] = @MaDocGia AND [TrangThai] = 0 AND [NgayTra] < GETDATE();
    
    IF @TongTienPhat IS NULL SET @TongTienPhat = 0;
END;
GO
```

# 4 Store Procedure trả về bảng kết quả từ lệnh JOIN
em:** Viết SP `sp_XemLichSuMuon` truyền vào Mã Độc Giả. Hệ thống sẽ JOIN bảng `[PhieuMuon]` và bảng `[Sach]` để trả về danh sách chi tiết tên các cuốn sách người đó đã mượn.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6b918107-9efe-4c32-a9ed-1e3b314137af" />
Khi thực thi Procedure, hệ thống trả về một bảng dữ liệu rõ ràng nhờ kết hợp lệnh JOIN giữa bảng Sách và Phiếu Mượn.

```code sql
USE [QuanLyThuVien_K235480106068];
GO

CREATE OR ALTER PROCEDURE sp_XemLichSuMuon
    @MaDocGia INT
AS
BEGIN
    SELECT pm.[MaPhieu], s.[TenSach], pm.[NgayMuon], 
           CASE WHEN pm.[TrangThai] = 0 THEN N'Chưa trả' ELSE N'Đã trả' END AS [TinhTrang]
    FROM [PhieuMuon] pm
    JOIN [Sach] s ON pm.[MaSach] = s.[MaSach]
    WHERE pm.[MaDocGia] = @MaDocGia;
END;
GO

-- Lệnh gọi chạy thử (bắt buộc bôi đen chạy cả lệnh này để ra bảng kết quả):
EXEC sp_XemLichSuMuon @MaDocGia = 1;
```

## Phần 4: Trigger và Xử lý logic nghiệp vụ (Kiến thức 11)
1. Trigger tự động cập nhật (Logic thực tế)
Em tạo trg_A_PhieuMuon để khi có một độc giả mượn sách (INSERT vào bảng PhieuMuon), hệ thống sẽ tự động trừ số lượng tồn kho trong bảng Sach.
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 225812" src="https://github.com/user-attachments/assets/e175148c-5222-4896-8482-47662b957bde" />
2.Thử nghiệm lỗi Đệ quy vô tận (Vòng lặp A-B
Em viết thêm trg_B_Sach. Mỗi khi bảng Sach được cập nhật (do Trigger A tác động), Trigger B này sẽ tự động cập nhật lại ngày trả trong bảng PhieuMuon.

Điều này tạo ra vòng lặp: A gọi B -> B lại gọi A không hồi kết.

Kết quả: Khi thực hiện lệnh INSERT, hệ thống báo lỗi đỏ: "Maximum stored procedure, function, trigger, or view nesting level exceeded (limit 32)".
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 230118" src="https://github.com/user-attachments/assets/cee254b7-f786-4063-a46a-93bf43f3098c" />





