USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'Cinema')
BEGIN
	ALTER DATABASE Cinema SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Cinema;
END
GO

CREATE DATABASE Cinema
GO

USE Cinema
GO

Create table THANHVIEN
(
	MATV char(5) primary key,
	HOTEN char(40) not null,
	NSINH smalldatetime,
	GIOITINH char(3),
	SDT int,
	QUAN char(20),
	LOAITV char(20)
)
Create Table PHIM
(
	MAP char(5) primary key,
	TENP char(40),
	NAMSX int,
	THELOAI char(20),
	THOILUONG int,
	TINHTRANG char(20),
	LUOTXEM int,
)
Create Table RAPPHIM
(
	MARP char(5) primary key, 
	TENRP char(40),
	SLVE int,
	DIACHI char(40),
	THANHPHO char(20)
)
CREATE TABLE LICHCHIEU
(
	MALC char(5) primary key,
	MARP char(5) foreign key references RAPPHIM(MARP),
	MAP char(5) foreign key references PHIM(MAP),
	PHONGCHIEU int,
	SUCCHUA int,
	SUATCHIEU int,
	TUNGAY smalldatetime, DENNGAY smalldatetime
)
CREATE TABLE VE
(
	MAV char(5) primary key,
	MATV char(5) foreign key references THANHVIEN(MATV),
	MALC char(5) foreign key references LICHCHIEU(MALC),
	NGAYMUA smalldatetime,
	LOAIVE char(20),
	GIATIEN int
)
GO
--A1. “Số lượt xem (SoLuotXem) của một bộ phim phải bằng số vé đã bán xem bộ phim đó.”
CREATE TRIGGER ck_luotxem ON PHIM
FOR INSERT, UPDATE
AS
		Declare @LUOTXEM int, @VEBAN int 
		SELECT @LUOTXEM = I.LUOTXEM FROM INSERTED I 
		SELECT @VEBAN = count(V.MAV) FROM VE V, LICHCHIEU LC, INSERTED I
		WHERE I.MAP = LC.MAP and LC.MALC = V.MALC
		GROUP BY V.MAV
		IF(@LUOTXEM != @VEBAN)
		BEGIN
			PRINT 'So luot xem phai bang voi so ve ban'
			Rollback tran
		END
GO
--A2. “Số lượng vé (SLVe) của một rạp phải bằng số vé đã bán xem tại rạp đó.”
/*
CREATE TRIGGER ck_slve ON RAPPHIM
FOR INSERT, UPDATE
AS
		DECLARE @SOVE int, @VEBAN int
		SELECT @SOVE = I.SLVE FROM INSERTED I
		SELECT @VEBAN = COUNT(V.MAV) FROM VE V, LICHCHIEU LC , INSERTED I
		WHERE I.MARP = LC.MARP and LC.MALC = V.MALC
		IF(@SOVE != @VEBAN)
		BEGIN
			PRINT 'So luong ve phai bang so ve da ban'
			Rollback tran
		End
GO
*/

INSERT INTO THANHVIEN(MATV, HOTEN,NSINH,GIOITINH,SDT,QUAN,LOAITV)
VALUES
	('TV01','Khoa Phan','2004-04-21','Nam','22520688','Binh Chanh','X-Star'),
	('TV02','Quan Doan','2004-2-2','Nam','12345678','Phu Nhuan','G-Star');
INSERT INTO PHIM(MAP,TENP,NAMSX,THELOAI,THOILUONG,TINHTRANG,LUOTXEM)
VALUES
	('MI','Mission Imposible','2021','Hanh dong','90','Dang chieu','1200000'),
	('BG','Bo Gia','2002','Hai huoc','110','Dang chieu','200000'),
	('LM','Lat Mat','2003','Kinh di','75','Ngung chieu','150000'),
	('DO','Doraemon','2004','Gia dinh','120', 'Dang chieu','1000000');
INSERT INTO RAPPHIM(MARP,TENRP,SLVE,DIACHI,THANHPHO)
VALUES
	('R01','Galaxy Linh Trung','1','Thu Duc','TpHCM'),
	('R02','Galaxy Tan Binh','1','Tan Binh','TpHCM');
INSERT INTO LICHCHIEU(MALC,MARP,MAP,PHONGCHIEU,SUATCHIEU,SUCCHUA,TUNGAY,DENNGAY)
VALUES
	('L01','R01','DO','01','01','1000000','2022-12-12','2023-12-12'),
	('L02','R02','MI','01','01','1000000','2020-11-11','2021-11-11'),
	('L03','R01','LM','1','1','50','2020-10-10','2020-11-11'),
	('L04','R01','BG','1','1','50','2020-9-9','2020-10-10'),
	('L05','R02','LM','2','2','22','2019-2-2','2020-2-2'),
	('L06','R01','MI','01','01','1000000','2022-12-12','2023-12-12');
INSERT INTO VE(MAV,MATV,MALC,NGAYMUA,LOAIVE,GIATIEN)
VALUES
	('V01','TV01','L01','2021-11-17','3D','100000'),
	('V02','TV02','L02','2022-10-10','2D','50000'),
	('V03','TV02','L03','2022-5-5','2D','45000'),
	('V04','TV02','L04','2022-5-5','2D','34000');
GO

--Cho biết thông tin thành viên (HoTen, DienThoai) thuộc loại thành viên ‘X-Star’ hoặc ở quận ‘Phú Nhuận’. Kết quả được sắp xếp theo ngày sinh giảm dần
SELECT TV.HOTEN, TV.SDT FROM THANHVIEN TV 
WHERE TV.LOAITV = 'X-Star' OR TV.QUAN = 'Phu Nhuan'
GROUP BY TV.HOTEN, TV.SDT, TV.NSINH
ORDER BY TV.NSINH desc
--Cho biết thông tin phim (TenP, NamSX) thuộc thể loại ‘Hành động’ hoặc thời lượng xem 120 phút. Kết quả được sắp xếp theo số lượt xem phim giảm dần.
SELECT P.TENP, P.NAMSX FROM PHIM P
WHERE P.THELOAI = 'Hanh dong' OR P.THOILUONG = '120'
GROUP BY P.TENP, P.NAMSX, P.LUOTXEM
ORDER BY P.LUOTXEM desc
--Cho biết thông tin thành viên (MaTV, HoTen) sinh sau năm 2000 mua vé loại ‘3D’.
SELECT TV.MATV, TV.HOTEN FROM THANHVIEN TV JOIN VE V ON V.MATV = TV.MATV
WHERE YEAR(TV.NSINH) > 2000 and V.LOAIVE = '3D';
GO
--Cho biết thông tin thành viên (MaTV, HoTen) mua vé vào tháng 11 năm 2021
SELECT TV.MATV, TV.HOTEN FROM THANHVIEN TV JOIN VE V ON V.MATV = TV.MATV 
WHERE MONTH(V.NGAYMUA) = '11' and YEAR(V.NGAYMUA) = '2021';
GO
--Cho biết thông tin những phim (MaP, TenP) chưa có lịch chiếu tại rạp ‘Galaxy Linh Trung’ (TenRP).
SELECT P.MAP, P.TENP FROM PHIM P
WHERE P.MAP not in (
		SELECT Distinct LC.MAP FROM LICHCHIEU LC 
		JOIN RAPPHIM RP ON RP.MARP = LC.MARP
		WHERE RP.TENRP = 'Galaxy Linh Trung');

--Cho biết  thông  tin  những  rạp  (MaRP, TenRP) chưa có lịch chiếu bộ phim ‘Stand  by  me doraemon’ (TenP).
SELECT RP.MARP,RP.TENRP FROM RAPPHIM RP
WHERE RP.MARP not in(
		SELECT DISTINCT LC.MARP FROM LICHCHIEU LC 
		JOIN PHIM P On P.MAP = LC.MAP
		WHERE P.TENP = 'Doraemon');
--Cho biết thành viên (MaTV) đã xem cả hai bộ phim có tên là ‘Lật mặt’ và ‘Bố Già’
SELECT TV.MATV FROM THANHVIEN TV JOIN VE V ON TV.MATV = V.MATV
JOIN LICHCHIEU LC ON V.MALC = LC.MALC
JOIN PHIM P ON P.MAP = LC.MAP
WHERE P.TENP in ('Lat mat','Bo gia')
GROUP BY TV.MATV
HAVING COUNT(distinct P.MAP) = 2
GO
--Cho biết thành viên (MaTV) đã xem ở cả hai rạp có tên là ‘Galaxy Linh Trung’ và ‘Galaxy Tân Bình’. (1 điểm)
SELECT TV.MATV FROm THANHVIEN TV JOIN VE V ON TV.MATV = V.MATV
JOIN LICHCHIEU LC ON V.MALC = LC.MALC
JOIN RAPPHIM RP ON RP.MARP = LC.MARP
WHERE RP.TENRP IN ('Galaxy Linh Trung', 'Galaxy Tan Binh')
Group by TV.MATV
HAVING COUNT(Distinct RP.MARP) = 2;
GO
--Cho biết thông tin khách hàng (MaTV, HoTen) mua nhiều vé xem phim nhất.
WITH TOPTV as(
		SELECT TV.MATV, TV.HOTEN, COUNT(V.MAV) as SoVe FROM THANHVIEN TV JOIN VE V ON V.MATV = TV.MATV
		GROUP BY TV.MATV, TV.HOTEN)
SELECT MATV, HOTEN FROM TOPTV WHERE SoVe = (SELECT MAX(SoVe) FROM TOPTV)
GO
--Cho biết thông tin khách hàng (MaTV, HoTen) đã chi nhiều tiền mua vé nhất. (1 điểm)
WITH TOPTIEN as(
		SELECT TV.MATV, TV.HOTEN, SUM(V.GIATIEN) as GiaTien FROM THANHVIEN TV JOIN VE V ON V.MATV = TV.MATV
		GROUP BY TV.MATV, TV.HOTEN)
SELECT MATV, HOTEN FROM TOPTIEN WHERE GiaTien = (SELECT MAX(GiaTien) FROM TOPTIEN)
--Tìm rạp phim (MaRP, TenRP) ở thành phố ‘TPHCM’ có lịch chiếu tất cả các phim sản xuất trong năm 2021.
SELECT RP.MARP, RP.TENRP FROM RAPPHIM RP JOIN LICHCHIEU LC ON LC.MARP = RP.MARP
JOIN PHIM P ON P.MAP = LC.MAP 
WHERE RP.THANHPHO = 'TpHCM' AND P.NAMSX = '2021'
GROUp BY RP.MARP, RP.TENRP
HAVING COUNT(P.MAP) = (SELECT COUNT(MAP) FROM PHIM)
GO
--Tìm bộ phim (MaP, TenP) thuộc thể loại 'Kinh dị' có lịch chiếu tại tất cả các rạp trong thành phố ‘TPHCM’
SELECT P.MAP, P.TENP FROM PHIM P JOIN LICHCHIEU LC ON LC.MAP = P.MAP
JOIN RAPPHIM RP ON RP.MARP = LC.MARP
WHERE RP.THANHPHO = 'TpHCM' AND P.THELOAI = 'Kinh di'
GROUp BY P.MAP, P.TENP
HAVING COUNT(RP.MARP) = (SELECT COUNT(MARP) FROM RAPPHIM)