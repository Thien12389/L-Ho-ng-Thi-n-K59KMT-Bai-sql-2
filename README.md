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
+ Chạy thử Hàm vô hướng và Hàm nội tuyến
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/fdbb5634-b815-4caf-8e6b-971d81fed5eb" />
- Bảng trên sử dụng hàm fn_TongSachDangMuon để đếm số sách mỗi người đang giữ.
- Bảng dưới sử dụng hàm fn_TimSachTheoTheLoai để lọc nhanh các sách thuộc nhóm 'Kỹ năng'.

```code sql
SELECT [MaDocGia], [TenDocGia], dbo.fn_TongSachDangMuon([MaDocGia]) AS [SoSachDangGiu] FROM [DocGia];
SELECT * FROM dbo.fn_TimSachTheoTheLoai(N'Kỹ năng');
```
+ 2: Chạy thử Hàm đa câu lệnh (Báo cáo tồn kho)
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/31dd70ac-0549-42eb-b758-4c88021aed46" />
hàm này xử lý logic phức tạp hơn, tự động gắn nhãn "Sắp hết" hoặc "Hết hàng" dựa trên số lượng tồn thực tế trong kho.

```code sql
SELECT * FROM dbo.fn_ThongKeTinhTrangSach();
```

## Phần 3: Xây dựng Store Procedure (Kiến thức 10)

1. Store Procedure có sẵn trong hệ thống:
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-02 174811" src="https://github.com/user-attachments/assets/55866555-fafc-4f83-b502-e93125138b0a" />
Trong SQL Server, các System Store Procedure (có tiền tố `sp_`) là các thủ tục được Microsoft viết sẵn để hỗ trợ quản trị và truy xuất thông tin hệ thống.
 ** Một số SP tiêu biểu em tìm hiểu được:**
  * `sp_help 'Tên_Bảng'`: Trả về toàn bộ thông tin chi tiết về cấu trúc của một bảng (các cột, kiểu dữ liệu, ràng buộc). Rất hữu ích khi muốn xem nhanh thiết kế bảng.
   * `sp_rename 'Tên_Cũ', 'Tên_Mới'`: Dùng để đổi tên các đối tượng (bảng, cột) một cách an toàn.
  *`sp_helpdb`: Liệt kê tất cả các Database đang có trên Server kèm theo kích thước của chúng.

2. Store Procedure INSERT có kiểm tra điều kiện:

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
Trong phần này, em thực hiện kịch bản tạo ra lỗi Đệ quy vô tận (Recursive Trigger) để hiểu về cơ chế kiểm soát của SQL Server.

1. Trigger A: Tự động cập nhật kho khi mượn sách
Mô tả: Khi có một bản ghi mới được thêm vào bảng [PhieuMuon], Trigger này sẽ tự động trừ đi 1 sản phẩm trong bảng [Sach].
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-03 180427" src="https://github.com/user-attachments/assets/4696c6f1-6c6d-41a8-a364-a17499b77bb5" />

Code SQL:
```
CREATE OR ALTER TRIGGER trg_A_PhieuMuon 
ON [PhieuMuon] 
AFTER INSERT 
AS
BEGIN
    UPDATE s SET s.SoLuongTon = s.SoLuongTon - 1
    FROM [Sach] s JOIN inserted i ON s.MaSach = i.MaSach;
END;
GO
```

2. Trigger B: Cố tình tạo vòng lặp (Ping-Pong)
Mô tả: Em tạo thêm Trigger B trên bảng [Sach]. Khi số lượng tồn bị thay đổi (do Trigger A tác động), Trigger B sẽ tự động cập nhật lại ngày trả của sách trong bảng [PhieuMuon].
Việc này tạo ra một vòng lặp: A gọi B -> B gọi A liên tục.
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-03 183533" src="https://github.com/user-attachments/assets/e03fb234-fd8a-471d-9c06-e265f18183d6" />

```code sql
CREATE OR ALTER TRIGGER trg_B_Sach 
ON [Sach] 
AFTER UPDATE 
AS
BEGIN
    UPDATE pm SET pm.NgayTra = DATEADD(day, 1, pm.NgayTra)
    FROM [PhieuMuon] pm JOIN inserted i ON pm.MaSach = i.MaSach;
END;
GO
```

3. Kích hoạt và quan sát lỗi đệ quy
<img width="1920" height="1080" alt="Ảnh chụp màn hình 2026-05-03 184034" src="https://github.com/user-attachments/assets/5bc6c32d-9b62-4265-af5a-e19aa69fbd0a" />
Ảnh chụp màn hình thông báo lỗi từ SQL Server. Hệ thống đã tự động ngắt giao dịch và báo lỗi vượt quá giới hạn lồng nhau (limit 32) khi phát hiện vòng lặp đệ quy vô tận giữa Trigger A và Trigger B, nhằm bảo vệ tài nguyên máy chủ khỏi bị treo

```code sql
INSERT INTO [PhieuMuon] ([MaDocGia], [MaSach], [NgayMuon], [NgayTra], [TrangThai])
VALUES (1, 2, GETDATE(), '2026-05-15', 0);
```

## Phần 5: Cursor và Duyệt dữ liệu (Kiến thức 11)
1. Bài toán thực tế
Em đặt ra logic: Tính tiền phạt quá hạn cho các phiếu mượn chưa trả.

Điều kiện: Phiếu mượn có TrangThai = 0 (chưa trả) và NgayTra < Ngày hiện tại.

Mức phạt: 5.000 VNĐ cho mỗi ngày chậm trễ.

2. Giải pháp 1: Sử dụng CURSOR (Xử lý tuần tự)
Em dùng Cursor để "cầm tay chỉ việc" cho SQL Server: mở danh sách, đi đến từng dòng, tính toán và in kết quả.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b652cf68-3170-4368-80c6-bd8ddcff55a4" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/287657bf-6fab-4e7c-befc-9be244d2fce4" />
Bảng kết quả trả về từ câu lệnh SELECT (Set-based). Kết quả tính toán số ngày trễ và tiền phạt hoàn toàn khớp với phương pháp dùng Cursor ở trên.

* Từ bài toán này, em nhận thấy nguyên tắc vàng trong SQL Server là: "Hãy suy nghĩ theo hướng Tập hợp (Set-based), thay vì hướng Tuần tự (Procedural)". Dù Cursor có thể giải quyết bài toán, nhưng nếu một nghiệp vụ có thể dùng các lệnh SQL thuần (như SELECT, UPDATE, DELETE) kết hợp với các hàm tích hợp (như DATEDIFF), thì tuyệt đối phải ưu tiên dùng SQL thuần để tối ưu hiệu suất toàn hệ thống, tránh gây nghẽn cổ chai (bottleneck) khi dữ liệu phình to.*

```code sql
-- 0. CHỌN ĐÚNG CƠ SỞ DỮ LIỆU CỦA BẠN (Đảm bảo tên này khớp với tên DB của bạn)
USE [QuanLyThuVien_K235480106068];
GO

-- 1. TẮT 2 TRIGGER ĐỂ NGĂN LỖI ĐỆ QUY
DISABLE TRIGGER trg_A_PhieuMuon ON [PhieuMuon];
DISABLE TRIGGER trg_B_Sach ON [Sach];
GO

-- 2. THÊM 1 PHIẾU MƯỢN ĐÃ QUÁ HẠN TỪ NĂM 2024 ĐỂ LÀM MỒI
INSERT INTO [PhieuMuon] ([MaDocGia], [MaSach], [NgayMuon], [NgayTra], [TrangThai])
VALUES (1, 1, '2024-04-01', '2024-04-15', 0);
GO

-- 3. CHẠY CURSOR ĐỂ TÍNH TIỀN PHẠT CHO PHIẾU VỪA THÊM
SET STATISTICS TIME ON;
GO

DECLARE @MaPhieu INT, @NgayTra DATE, @SoNgayTre INT, @TienPhat MONEY;
DECLARE @NgayHienTai DATE = GETDATE();

-- Khai báo Cursor duyệt danh sách phiếu quá hạn
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
```
3. Giải pháp 2: Sử dụng lệnh SELECT (Set-based) - Tối ưu hiệu suất
Thay vì duyệt từng dòng, em sử dụng truy vấn tập hợp (Set-based) để tính toán toàn bộ danh sách trong một lần duy nhất.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/189fa6a3-25cd-4191-a4d6-4018eb78f262" />
Bảng kết quả trả về từ lệnh SELECT. Kết quả khớp hoàn toàn với phương pháp dùng Cursor nhưng trình bày dưới dạng bảng chuyên nghiệp.

4. Phân tích: Khi nào bắt buộc sử dụng Cursor?
Mặc dù SELECT luôn nhanh hơn, nhưng em nhận thấy có những bài toán đặc thù chỉ có Cursor mới giải quyết tốt:

Bài toán: Tính số dư lũy kế (Running Total)

Ví dụ: Trong báo cáo kế toán của thư viện, dòng tính toán tháng này phải lấy kết quả "Số dư" của dòng tháng trước đó để tính tiếp.

Vì SQL Server xử lý các dòng độc lập, nên lệnh SELECT thuần rất khó để lấy giá trị vừa tính xong của dòng kề trước.

Cursor cho phép lưu giá trị đó vào một biến trung gian và mang sang dòng tiếp theo, giúp giải quyết các bài toán có tính chất "lũy kế" một cách tự nhiên và chính xác.

Nguyên tắc vàng trong SQL là ưu tiên dùng Set-based (SELECT) để tối ưu tốc độ. Chỉ sử dụng Cursor khi gặp các logic nghiệp vụ phức tạp, xử lý tuần tự mà các hàm tập hợp không thể đáp ứng.

##  TỔNG KẾT BÀI KIỂM TRA SỐ 2

Qua bài tập này, em đã vận dụng thành công các kiến thức SQL Server từ tuần 1 đến tuần 4 vào bài toán thực tế là Quản lý thư viện. Bài làm giúp em củng cố vững chắc các kỹ năng:
- Thiết kế CSDL và đóng gói logic nghiệp vụ an toàn bằng **Function/Procedure**.
- Nắm bắt cơ chế hoạt động của **Trigger** (kể cả việc chủ động tạo và xử lý lỗi đệ quy Ping-Pong).
- Hiểu sâu về tối ưu hóa hiệu suất, biết rõ khi nào nên dùng truy vấn tập hợp **SELECT (Set-based)** cực nhanh và khi nào bắt buộc phải duyệt tuần tự bằng **Cursor**.

Em xin chân thành cảm ơn thầy đã dành thời gian xem và chấm bài. Trong quá trình làm bài chắc chắn vẫn còn những thiếu sót và đôi khi phải xóa đi chỉnh lại bài nhiều, rất mong thầy thông cảm và bỏ qua cho em ạ. Em cảm ơn thầy rất nhiều!





