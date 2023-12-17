USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'DOIBONG')
BEGIN
	ALTER DATABASE DOIBONG SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DOIBONG;
END
GO

CREATE DATABASE DOIBONG
GO

USE DOIBONG
GO

CREATE TABLE DOIBONG
(
	MADOI varchar(2) primary key,
	TENDOI varchar(100),
	NAMTL int
)
GO
CREATE TABLE CAUTHU
(
	MACT varchar(4) primary key,
	TENCT varchar(50) not null,
	Phai bit,
	NGAYSINH smalldatetime,
	NOISINH varchar(50)
)
GO
CREATE TABLE CTDB
(
	MADOI varchar(2) foreign key references DOIBONG(MADOI),
	MACT varchar(4) foreign key references CAUTHU(MACT),
	NGAYVAO smalldatetime
)
CREATE TABLE THIDAU
(
	MADOI varchar(2) foreign key references DOIBONG(MADOI),
	NGTHIDAU smalldatetime,
	HIEUSO int,
	KETQUA char(5)
)
CREATE TABLE BANGPHAT
(
	MAPHAT varchar(2) primary key,
	MACT varchar(4) foreign key references CAUTHU(MACT),
	TIENPHAT numeric,
	LOAITHE varchar(4),
	NGAYPHAT smalldatetime
)
GO
CREATE Trigger tienphat_thedo ON BANGPHAT
FOR INSERT, UPDATE 
AS
	DECLARE @THE varchar(4)
	SELECT @THE = I.LOAITHE FROM INSERTED I
	IF(@THE = 'Do')
	BEGIN
			UPDATE BANGPHAT SET TIENPHAT = 1000000;
	END
GO
CREATE Trigger ck_tuoi ON CAUTHU
FOR INSERT, UPDATE
AS
	DECLARE @TUOI int
	SELECT @TUOI = YEAR(CT.NGAYVAO) - YEAR(I.NGAYSINH) FROM CTDB CT, INSERTED I
	WHERE CT.MACT = I.MACT
	IF(@TUOI < 18)
	BEGIn
		PRINT 'Error: Cau thu chua du 18 tuoi'
		ROLLBACK TRANSACTION
	END
GO
---- De 7-8-9
--Loại thẻ phạt chỉ có thể là ‘D’ hoặc ‘V’ 
ALTER TABLE BANGPHAT ADD constraint ck_the CHECK(LOAITHE in ('Do' , 'Vang'))
GO
--Nếu loại thẻ là D (đỏ) thì số lần phạt cho mỗi cầu thủ trong một ngày chỉ tối đa bằng 1.
Create trigger ck_solanthe ON BANGPHAT
FOR INSERT, UPDATE
AS
	Declare @SOLAN int, @THE char(4), @NGAY smalldatetime, @NGAYMOI smalldatetime
	SELECT @THE = I.LOAITHE, @NGAY = BP.NGAYPHAT, @NGAYMOI = I.NGAYPHAT FROM INSERTED I, CAUTHU CT, BANGPHAT BP WHERE CT.MACT = I.MACT
	SELECT @SOLAN = count(BP.MAPHAT) FROM BANGPHAT BP

	IF(@THE = 'Do' and  @NGAY = @NGAYMOI and @SOLAN > 1)
	BEGIN
		Print 'Error: Chi phat 1 the de trong ngay'
		Rollback tran
	End
Go
------------------------------------------De 8------------------------------------------
-- Tuổi của cầu thủ phải từ 18 đến 35

CREATE Trigger ck_tuoi2 ON CAUTHU
FOR INSERT, UPDATE
AS
		DECLARE  @TUOI int
		SELECT @TUOI = YEAR(GETDATE()) - YEAR(NGAYSINH) FROM INSERTED I
		IF(@TUOI < 18 or @TUOI > 35)
		BEGIN
			PRINT'Error: Tuoi cau thu phai thuoc tu 18 - 35'
			Rollback tran
		END
GO

-- Mỗi lần bị phạt, ngày phạt cầu thủ phải lớn hơn ngày sinh của cầu thủ đó.

CREATE Trigger ck_ngphat ON BANGPHAT
FOR INSERT, UPDATE
AS
		DECLARE @NGAYPHAT smalldatetime, @NGAYSINH smalldatetime
		SELECT @NGAYPHAT = I.NGAYPHAT, @NGAYSINH = CT.NGAYSINH FROM INSERTED I, CAUTHU CT 
		WHERE CT.MACT = I.MACT
		IF(@NGAYSINH > @NGAYPHAT)
		BEGIN
			PRINT 'Error: Ngay phat phai lon hon ngay sinh'
			Rollback tran
		END
GO
-- Năm gia nhập vào đội bóng của mỗi cầu thủ phải lớn hơn hoặc bằng năm thành lập của đội bóng đó.
Create trigger ck_namgianhap ON CTDB
FOR INSERT, UPDATE
AS
		Declare @NGAYVAO smalldatetime, @NGAYLAP int
		SELECT @NGAYVAO = YEAR(I.NGAYVAO), @NGAYLAP = DB.NAMTL FROM INSERTED I, DOIBONG DB
		WHERE I.MADOI = DB.MADOI
		IF(@NGAYVAO < @NGAYLAP)
		BEGIN
			PRINT 'Error: Ngay vao phai sau ngay thanh lap'
			Rollback tran
		END
GO
--------------INSERT
INSERT INTO DOIBONG(MADOI, TENDOI, NAMTL)
VALUES
	('MU','Manchester United','1990'),
	('CH','Chelsea','1993'),
	('LV','Liverpool','1997');
GO
INSERT INTO CAUTHU(MACT, TENCT, Phai, NGAYSINH, NOISINH)
VALUES
	('MU01','Christiano Ronaldo','1','1990-12-12','Portugal'),
	('CH01','Frank Lampard','1','1992-5-5','England'),
	('LV01','Mohammed Salah','1','1993-4-4','Egypt'),
	('VN01','Khoa Phan','1','2004-04-21','Ha Noi');
GO
INSERT INTO CTDB(MADOI, MACT, NGAYVAO)
VALUES
	('MU','MU01','2000-5-5'),
	('CH','CH01','2003-11-11'),
	('LV','LV01','2004-9-9'),
	('CH','MU01','2001-5-5'),
	('LV','MU01','2002-5-5');
GO
INSERT INTO BANGPHAT(MAPHAT, MACT, TIENPHAT, LOAITHE, NGAYPHAT)
VALUES
	('01','CH01', null, 'Do', '2005-7-7'),
	('02','CH01',500000, 'Vang', '2005-8-8'),
	('03','MU01',500000, 'Vang','2005-6-6'),
	('04','CH01', null, 'Do', '2005-7-9');
GO
INSERT INTO THIDAU(MADOI, NGTHIDAU, HIEUSO, KETQUA)
VALUES
	('MU','2006-12-2','-3','0'),
	('CH','2006-12-2','3','1'),
	('MU','2006-10-10','2','1'),
	('LV','2006-10-10','-2','0');


SELECT C_DB.MADOI, COUNT(CT.MACT) AS Socauthu FROM CAUTHU CT JOIN CTDB C_DB ON CT.MACT = C_DB.MACT
GROUP BY C_DB.MADOI
HAVING COUNT(CT.MACT) > 0;

SELECT * FROM BANGPHAT

SELECT CT.MACT, CT.TENCT, MONTH(BP.NGAYPHAT) AS THANG, SUM(CASE when BP.LOAITHE = 'Do' then 1 else 0 end) as TheDo, Sum(case when BP.LOAITHE = 'Vang' then 1 else 0 end) as TheVang 
FROM CAUTHU CT JOIN BANGPHAT BP ON CT.MACT = BP.MACT
WHERE YEAR(BP.NGAYPHAT) = '2005'
GROUP BY CT.MACT, CT.TENCT, MONTH(BP.NGAYPHAT)

---- De 7-8-9
--Đưa ra thông tin các cầu thủ quê ở Hà Nội (nơi sinh tại Hà Nội). Thông tin gồm : Tên Cầu thủ, Ngày sinh, Nơi sinh
SELECT CT.TENCT, CT.NGAYSINH, CT.NOISINH FROM CAUTHU CT WHERE CT.NOISINH = 'Ha Noi'
--Thống kê số cầu thủ theo loại thẻ phạt. Thông tin hiển thị gồm có: Loại thẻ (LoaiThe), số lượng cầu thủ bị phạt.
SELECT BP.LOAITHE, count(CT.MACT) FROM BANGPHAT BP Join CAUTHU CT ON BP.MACT = CT.MACT
GROUP BY BP.LOAITHE
HAVING COUNT(CT.MACT) > 0;
--Tính tổng hiệu số bàn thắng, tổng hiệu số bàn thua của từng đội bóng. Thông tin gồm : Mã đội, tên đội, tổng hiệu số bàn thắng, tổng hiệu số bàn thua.
SELECT D.MADOI, D.TENDOI, sum(TD.HIEUSO) as hsBANTHANG, sum(TD.HIEUSO) * (-1) as hsBANTHUA FROM DOIBONG D JOIN THIDAU TD ON D.MADOI = TD.MADOI
GROUP BY D.MADOI, D.TENDOI
-----------------------------------------De 8---------------------------------
--Đưa ra thông tin các cầu thủ bị phạt thẻ đỏ trong năm 2005 (LoaiThe=‘D’). Thông tin gồm: Tên Cầu thủ, Ngày sinh, Nơi sinh 
SELECT CT.TENCT, COUNT(BP.MAPHAT) AS SoTheDo FROm CAUTHU CT JOIN BANGPHAT BP ON CT.MACT = BP.MACT
WHERE YEAR(BP.NGAYPHAT) = 2005 and BP.LOAITHE = 'Do'
GROUP BY CT.TENCT
HAVING COUNT(BP.MAPHAT) > 0;
--Tìm cầu thủ chưa bị phạt thẻ đỏ (LoaiThe=‘D’)
SELECT CT.MACT, CT.TENCT FROM CAUTHU CT
WHERE CT.MACT NOT IN (
	SELECT CT.MACT FROM BANGPHAT BP JOIN CAUTHU CT ON CT.MACT = BP.MACT
	WHERE BP.LOAITHE = 'Do'
	GROUP BY CT.MACT
	HAVING COUNT(BP.MAPHAT) > 0);

--Cho biết cầu thủ có tổng số lần phạt lớn hơn tổng số lần phạt của cầu thủ có mã số MU01. Thông tin gồm : Mã cầu thủ, Tên cầu thủ, số lần phạt.
SELECT CT.MACT, CT.TENCT, COUNT(distinct BP.MAPHAT) as SoLanPhat FROM CAUTHU CT Join BANGPHAT BP ON CT.MACT = BP.MACT
GROUP BY CT.MACT, CT.TENCT
HAVING COUNT(distinct BP.MAPHAT) > (
		Select count(distinct MAPHAT)
		FROM BANGPHAT
		WHERE MACT = 'MU01'
)
-----------------------------------------De 9---------------------------------
-- Đưa ra danh sách các cầu thủ của đội bóng ‘CH’.
SELECT CT.MACT, CT.TENCT FROM CAUTHU CT JOIN CTDB CD ON CT.MACT = CD.MACT
WHERE CD.MADOI = 'CH'
GO
-- Đưa ra thông tin các đội bóng và số trận tham gia thi đấu của từng đội. Thông tin gồm : Tên đội bóng, số trận đấu
SELECT DB.TENDOI, COUNT(TD.NGTHIDAU) as SoTran FROM DOIBONG DB JOIN THIDAU TD ON DB.MADOI = TD.MADOI
GROUP BY DB.TENDOI
HAVING COUNT(TD.NGTHIDAU) > 0
GO
-- Cho biết họ tên cầu thủ đã tham gia cả 3 đội bóng (A1, B2, C2)
SELECT CT.TENCT FROM CAUTHU CT 
WHERE CT.MACT IN (
		SELECT CT.MACT FROM CAUTHU CT JOIN CTDB CD ON CT.MACT = CD.MACT
		WHERE CD.MADOI IN ('MU','CH','LV')
		GROUP BY CT.MACT
		HAVING COUNT(CD.MADOI) = 3
		)