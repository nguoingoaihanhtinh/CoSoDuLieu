USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'Olympic')
BEGIN
	ALTER DATABASE Olympic SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Olympic;
END
GO

CREATE DATABASE Olympic
GO

USE Olympic
GO

/*Quocgia (MaQG, TenQG, ChauLuc, DienTich) Tân từ: Quan hệ Quocgia chứa thông tin về quốc gia gồm: mã quốc gia (MaQG), tên quốc gia (TenQG), tên châu lục (ChauLuc), diện tích (DienTich). 
Thevanhoi (MaTVH, TenTVH, MaQG, Nam) Tân từ: Quan hệ Thevanhoi chứa thông tin về thế vận hội gồm: mã thế vận hội (MaTVH), tên thế vận hội (TenTVH), mã quốc gia đăng cai thế vận hội (MaQG), năm (Nam) diễn ra thế vận hội. 
Vandongvien (MaVDV, HoTen, NgSinh, GioiTinh, QuocTich) Tân từ: Quan hệ Vandongvien chứa thông tin vận động viên gồm: mã vận động viên (MaVDV), họ tên (HoTen), ngày sinh (NgSinh), giới tính (GioiTinh), quốc tịch (QuocTich) của vận động viên (quốc tịch chính là mã quốc gia) 
Noidungthi (MaNDT, TenNDT, GhiChu) Tân từ: Quan hệ Noidungthi chứa thông tin nội dung thi gồm: mã nội dung thi (MaNDT), tên nội dung thi (TenNDT), ghi chú (GhiChu). 
Thamgia (MaVDV, MaNDT, MaTVH, HuyChuong) Tân từ: Quan hệ Thamgia chứa thông tin vận động viên (MaVDV) tham dự nội dung (MaNDT) gì ở thế vận hội (MaTVH) nào và đạt huy chương gì (thuộc tính HuyChuong có giá trị là: 0 nếu không đạt huy chương, 1 nếu đạt huy chương vàng, 2 nếu đạt huy chương bạc, 3 nếu đạt huy chương đồng)

1. Hãy phát biểu chặt chẽ ràng buộc toàn vẹn (bao gồm bối cảnh, nội dung, bảng tầm ảnh hưởng): (1.5 điểm)  
Tại một kỳ thế vận hội, mỗi nội dung thi chỉ có duy nhất một huy chương vàng. 
*Lưu ý: Không được sửa thuộc tính khóa chính
*/

CREATE TABLE QUOCGIA 
(
	MAQG char(5) primary key,
	TENQG char(40) not null,
	CHAULUC char(25) not null,
	DIENTICH int
)
CREATE TABLE THEVANHOI
(
	MATVH char(5) primary key,
	TENTVH char(40) not null,
	MAQG char(5) foreign key references QUOCGIA(MAQG),
	NAM int
)
CREATE TABLE VANDONGVIEN
(
	MAVDV char(5) primary key,
	HOTEN char(40),
	NSINH smalldatetime,
	GIOITINH char(3),
	QUOCTICH char(20)
)
CREATE TABLE NOIDUNGTHI
(
	MAND char(5) primary key,
	TENND char(40) not null,
	GHICHU char(5) foreign key references QUOCGIA(MAQG)
)
CREATE TABLE THAMGIA
(
	MAVDV char(5) foreign key references VANDONGVIEN(MAVDV),
	MAND char(5) foreign key references NOIDUNGTHI(MAND),
	MATVH char(5) foreign key references THEVANHOI(MATVH),
	HUYCHUONG char(4)
)

INSERT INTO QUOCGIA(MAQG,TENQG,CHAULUC,DIENTICH)
VALUES
	('UK','United Kingdom','Europe','300000'),
	('JP','Japan','Asia','180000'),
	('BR','Brazil','South America','350000'),
	('VN','Viet Nam','South East Asia','200000');
INSERT INTO THEVANHOI(MATVH,TENTVH,MAQG,NAM)
VALUES
	('TVH01','Olympic Rio','BR','2016'),
	('TVH02','Olympic Tokyo','JP','2020'),
	('TVH03','Olympic Da Nang','VN','2020');
INSERT INTO VANDONGVIEN(MAVDV,HOTEN,NSINH,GIOITINH,QUOCTICH)
VALUES
	('V01','Tamy Holland','2000-10-10','Nu','UK'),
	('V02','Kuzou Tanako','2001-6-6','Nu','JP'),
	('V03','Khoa Phan','2004-04-21','Nam','VN'),
	('V04','Tom Holland','1999-7-7','Nam','UK'),
	('V05','Hideo Kojima','1997-6-6','Nam','JP');
INSERT INTO NOIDUNGTHI(MAND,TENND,GHICHU)
VALUES
	('BC','Ban Cung',null),
	('SW1','100m boi ngua',null),
	('SW2','200m tu do', null);
INSERT INTO THAMGIA(MAVDV,MAND,MATVH,HUYCHUONG)
VALUES
	('V01','SW1','TVH01','Bac'),
	('V01','BC','TVH02','Bac'),
	('V01','SW2','TVH03','Bac'),
	('V02','SW1','TVH01', 'Vang'),
	('V02','BC','TVH01','Vang'),
	('V02','BC','TVH02','Vang'),
	('V03','SW2','TVH03','Vang'),
	('V05','SW1','TVH02','Vang'),
	('V04','SW1','TVH02','Bac');
GO
--Liệt kê danh sách vận động viên (HoTen, NgSinh, GioiTinh) có Quốc tịch là ‘UK’ và sắp xếp danh sách theo (HoTen) tăng dần.
SELECT VDV.HOTEN, VDV.NSINH, VDV.GIOITINH FROM VANDONGVIEN VDV
WHERE VDV.QUOCTICH = 'UK'
GROUP BY VDV.HOTEN, VDV.NSINH, VDV.GIOITINH
ORDER BY VDV.HOTEN asc
GO
--In ra danh sách những vận động viên tham  gia  nội dung thi ‘Bắn Cung’ ở thế vận hội ‘Olympic Tokyo 2020’
SELECT VDV.MAVDV, VDV.HOTEN FROM VANDONGVIEN VDV JOIN THAMGIA TG ON VDV.MAVDV = TG.MAVDV JOIN NOIDUNGTHI ND ON ND.MAND = TG.MAND JOIN THEVANHOI TVH ON TG.MATVH = TVH.MATVH
WHERE ND.TENND = 'Ban cung' AND TVH.TENTVH = 'Olympic Tokyo' AND TVH.NAM = '2020'
GROUP BY VDV.MAVDV, VDV.HOTEN
GO
--Cho biết số lượng huy chương vàng mà các vận động viên ‘Nhật Bản’ đạt được ở thế vận hội diễn ra vào năm 2020.
SELECT COUNT(TG.HUYCHUONG) FROM THAMGIA TG JOIN VANDONGVIEN VDV ON TG.MAVDV = VDV.MAVDV JOIN THEVANHOI TVH ON TG.MATVH = TVH.MATVH
WHERE VDV.QUOCTICH = 'JP'and TVH.NAM = '2020'
GO
--Liệt kê họ tên và quốc tịch của những vận động viên tham gia cả 2 nội dung thi ‘100m bơi ngửa’ và ‘200m tự do’.
SELECT VDV.HOTEN, VDV.QUOCTICH FROM VANDONGVIEN VDV JOIN THAMGIA TG ON VDV.MAVDV = TG.MAVDV JOIN NOIDUNGTHI ND ON ND.MAND = TG.MAND
WHERE ND.TENND in ('100m boi ngua','200m tu do')
Group by  VDV.HOTEN, VDV.QUOCTICH
HAVING COUNT(ND.MAND) = 2;
GO
--In ra thông tin (MaVDV, HoTen) của những vận động viên Nữ người Anh (QuocTich=UK) tham gia tất cả các kỳ thế vận hội từ năm 2008 tới nay. 
SELECT VDV.MAVDV, VDV.HOTEN FROM VANDONGVIEN VDV JOIN THAMGIA TG ON TG.MAVDV = VDV.MAVDV JOIN THEVANHOI TVH ON TG.MATVH = TVH.MATVH
WHERE VDV.GIOITINH = 'Nu' and VDV.QUOCTICH = 'UK' and TVH.NAM >= '2008'
GROUP BY VDV.MAVDV, VDV.HOTEN
HAVING COUNT(TVH.MATVH) = (
		SELECT COUNT(MATVH) FROM THEVANHOI)
GO
--Tìm vận đông viên (MaVDV, HoTen) đã đạt từ 2 huy chương vàng trở lên tại thế vận hội ‘Olympic Rio 2016’
SELECT VDV.MAVDV, VDV.HOTEN FROM VANDONGVIEN VDV 
JOIN THAMGIA TG ON VDV.MAVDV = TG.MAVDV
JOIN THEVANHOI TVH ON TVH.MATVH = TG.MATVH
WHERE TVH.TENTVH = 'Olympic Rio' and TVH.NAM = '2016' and TG.HUYCHUONG = 'Vang'
GROUP BY VDV.MAVDV, VDV.HOTEN
HAVING COUNT(TG.HUYCHUONG) >= 2
GO

--Câu 2: Phụ thuộc hàm và các dạng chuẩn (2.5 điểm)  
--Cho lược đồ quan hệ Q(ABCDEGH) có tập phụ thuộc hàm: 
--F = {f1: AD→CG; f2: AE→BH; f3: C→D; f4: CE→H; f5: DE→G; f6: CD→BE}  
--1. CG→AE có thuộc F+ không? Giải thích. (1 điểm) 
--2. Lược đồ quan hệ (Q, F) có đạt dạng chuẩn 2 không? Giải thích. 
