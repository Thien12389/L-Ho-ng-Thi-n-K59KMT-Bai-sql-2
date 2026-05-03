-- ==============================================================================
-- BÀI KIỂM TRA SỐ 2 - CƠ SỞ DỮ LIỆU SQL SERVER
-- Sinh viên thực hiện: LÊ ĐỖ HOÀNG THIỆN
-- Lớp: K59KMT
-- MSSV: K235480106068
-- ==============================================================================

-- 0. TẠO VÀ SỬ DỤNG CƠ SỞ DỮ LIỆU
CREATE DATABASE [QuanLyThuVien_K235480106068];
GO
USE [QuanLyThuVien_K235480106068];
GO

-- ==============================================================================
-- PHẦN 1: KHỞI TẠO BẢNG VÀ THÊM DỮ LIỆU MẪU
-- ==============================================================================

-- 1. Xóa các bảng cũ nếu đã tồn tại (Phòng trường hợp chạy lại nhiều lần)
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


-- ==============================================================================
-- PHẦN 2 & 3: FUNCTION VÀ STORED PROCEDURE
-- ==============================================================================

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

-- Chạy thử các Function
SELECT [MaDocGia], [TenDocGia], dbo.fn_TongSachDangMuon([MaDocGia]) AS [SoSachDangGiu] FROM [DocGia];
SELECT * FROM dbo.fn_TimSachTheoTheLoai(N'Kỹ năng');
SELECT * FROM dbo.fn_ThongKeTinhTrangSach();
GO

-- 4. SP 1: Thêm Phiếu Mượn mới có kiểm tra tồn kho
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

-- 5. SP 2: Tính tiền phạt (Sử dụng tham số OUTPUT)
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

-- 6. SP 3: Xem lịch sử mượn trả
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

-- Lệnh gọi chạy thử Procedure
EXEC sp_XemLichSuMuon @MaDocGia = 1;
GO


-- ==============================================================================
-- PHẦN 4: TRIGGER VÀ XỬ LÝ LỖI ĐỆ QUY (PING-PONG)
-- ==============================================================================

-- 4.1. Tạo Trigger A trên bảng PhieuMuon: Khi có phiếu mượn mới, tự động trừ số lượng sách
CREATE OR ALTER TRIGGER trg_A_PhieuMuon 
ON [PhieuMuon] 
AFTER INSERT 
AS
BEGIN
    UPDATE s SET s.SoLuongTon = s.SoLuongTon - 1
    FROM [Sach] s JOIN inserted i ON s.MaSach = i.MaSach;
END;
GO

-- 4.2. Tạo Trigger B trên bảng Sach: Khi sách bị cập nhật, tự động đổi ngày trả trong PhieuMuon
CREATE OR ALTER TRIGGER trg_B_Sach 
ON [Sach] 
AFTER UPDATE 
AS
BEGIN
    UPDATE pm SET pm.NgayTra = DATEADD(day, 1, pm.NgayTra)
    FROM [PhieuMuon] pm JOIN inserted i ON pm.MaSach = i.MaSach;
END;
GO

-- 4.3. Kích hoạt đệ quy (Ping-Pong)
/* GHI CHÚ CHO GIÁO VIÊN: 
Em đã comment lệnh INSERT dưới đây lại để Script có thể chạy mượt mà từ đầu đến cuối. 
Nếu bỏ comment, lệnh này sẽ kích hoạt lỗi vượt quá 32 cấp độ (Maximum nesting level) do Trigger A và B gọi chéo nhau.
*/
-- INSERT INTO [PhieuMuon] ([MaDocGia], [MaSach], [NgayMuon], [NgayTra], [TrangThai])
-- VALUES (1, 2, GETDATE(), '2026-05-15', 0);
-- GO


-- ==============================================================================
-- PHẦN 5: CURSOR VÀ DUYỆT DỮ LIỆU (SET-BASED VS PROCEDURAL)
-- ==============================================================================

-- 5.1. TẮT 2 TRIGGER ĐỂ NGĂN LỖI ĐỆ QUY KHI CHẠY PHẦN 5
DISABLE TRIGGER trg_A_PhieuMuon ON [PhieuMuon];
DISABLE TRIGGER trg_B_Sach ON [Sach];
GO

-- 5.2. THÊM 1 PHIẾU MƯỢN ĐÃ QUÁ HẠN TỪ NĂM 2024 ĐỂ LÀM MỒI TÍNH TOÁN
INSERT INTO [PhieuMuon] ([MaDocGia], [MaSach], [NgayMuon], [NgayTra], [TrangThai])
VALUES (1, 1, '2024-04-01', '2024-04-15', 0);
GO

-- 5.3. GIẢI PHÁP 1: CHẠY CURSOR ĐỂ TÍNH TIỀN PHẠT TỪNG DÒNG
SET STATISTICS TIME ON;
GO

PRINT N'--- KẾT QUẢ TÍNH TIỀN PHẠT BẰNG CURSOR ---';
DECLARE @MaPhieu INT, @NgayTra DATE, @SoNgayTre INT, @TienPhat MONEY;
DECLARE @NgayHienTai DATE = GETDATE();

DECLARE cur_XuLyTienPhat CURSOR FOR 
SELECT MaPhieu, NgayTra FROM [PhieuMuon] 
WHERE TrangThai = 0 AND NgayTra < @NgayHienTai;

OPEN cur_XuLyTienPhat;
FETCH NEXT FROM cur_XuLyTienPhat INTO @MaPhieu, @NgayTra;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SoNgayTre = DATEDIFF(day, @NgayTra, @NgayHienTai);
    SET @TienPhat = @SoNgayTre * 5000;
    
    PRINT N'Phiếu: ' + CAST(@MaPhieu AS VARCHAR) + 
          N' - Trễ: ' + CAST(@SoNgayTre AS VARCHAR) + 
          N' ngày - Phạt: ' + CAST(@TienPhat AS VARCHAR) + ' VNĐ';
          
    FETCH NEXT FROM cur_XuLyTienPhat INTO @MaPhieu, @NgayTra;
END

CLOSE cur_XuLyTienPhat;
DEALLOCATE cur_XuLyTienPhat;
GO
SET STATISTICS TIME OFF;
GO

-- 5.4. GIẢI PHÁP 2: DÙNG LỆNH SELECT (SET-BASED) TỐI ƯU HIỆU SUẤT
PRINT N'--- KẾT QUẢ TÍNH TIỀN PHẠT BẰNG LỆNH SELECT (SET-BASED) ---';
SET STATISTICS TIME ON;
GO

SELECT MaPhieu, 
       DATEDIFF(day, NgayTra, GETDATE()) AS SoNgayTre,
       DATEDIFF(day, NgayTra, GETDATE()) * 5000 AS TienPhat
FROM [PhieuMuon]
WHERE TrangThai = 0 AND NgayTra < GETDATE();
GO
SET STATISTICS TIME OFF;
GO

-- ================================= END SCRIPT =================================