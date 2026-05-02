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




