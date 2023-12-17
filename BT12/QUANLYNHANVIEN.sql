USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'QUANLYNHANVIEN')
BEGIN
	ALTER DATABASE QUANLYNHANVIEN SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE QUANLYNHANVIEN;
END
GO

CREATE DATABASE QUANLYNHANVIEN
GO

USE QUANLYNHANVIEN
GO

Create table PHONGBAN
(
	MAPB char(4) primary key,
	TENPB char(10),
	DIACHI varchar(40),
	NgayTL smalldatetime,
	MATrP int 
)
Create Table VITRI
(
	MAVT int primary key,
	MOTA varchar(30)
	)
Create Table NHANVIEN
(
	MANV int primary key,
	TENNV varchar(30),
	MAVT int foreign key references VITRI(MAVT),
	MAPB char(4) foreign key references PHONGBAN(MAPB),
	LUONG int,
	NGAYVL smalldatetime,
)
Create table MUCLUONG
(
	MAML int primary key,
	MUCTHAP int,
	MUCCao int
)

GO
Create Trigger luong_min ON NHANVIEN
FOR INSERT, UPDATE
AS	
	DECLARE @LUONG int, @MAPHONG char(4)
	SELECT @LUONG = I.LUONG, @MAPHONG = I.MAPB FROM INSERTED I
	IF(@MAPHONG = 'KT')
		BEGIN
		IF(@LUONG < 3000000)
		BEGIN
			PRINT 'Error: Nhan vien thuoc ban KT phai co muc luong lon hon 3000000'
			ROLLBACK TRANSACTION
		END
	END
Go

Create Trigger Mucluong_adjust ON MUCLUONG
FOR INSERT, UPDATE
AS
	DECLARE @THAP int, @CAO int
	SELECT @THAP = I.MUCTHAP, @CAO = I.MUCCAO FROM INSERTED I
	IF(@THAP > @CAO)
		BEGIN
			PRINT 'Error: Muc luong nen khong duoc cao hon luong tran'
			ROLLBACK TRANSACTION
		END
GO

Create Trigger Luong_NV ON NHANVIEN
FOR INSERT, UPDATE
AS
	DECLARE @LUONG int, @THAP int, @CAO int
	SELECT @LUONG = I.LUONG FROM INSERTED I;
	SELECT @THAP = min(MUCTHAP) FROM MUCLUONG;
	SELECT @CAO = max(MUCCAO) FROM MUCLUONG;
	IF(@LUONG < @THAP OR @LUONG > @CAO)
	BEGIN 
		PRINT 'Error: Luong cua nhan vien khong phu hop'
		ROLLBACK TRANSACTION
	END
GO

---De 3
-- Ngày vào làm của nhân viên phải nhỏ hơn ngày hiện tại.
Alter table NHANVIEN add constraint ck_ngvao Check(NGAYVL < Getdate())
GO
-- Địa chỉ phòng ban chỉ có thể là 'HANOI','TPHCM','DANANG', 'CANTHO’
Alter table PHONGBAN add constraint ck_diachi Check (DIACHI in ('HANOI','TPHCM','DANANG','CANTHO'))
GO
-- Ngày vào làm của nhân viên phải lớn hơn ngày thành lập của phòng ban mà nhân viên đó làm việc. 
Create Trigger ck_ngayvl ON NHANVIEN
FOR INSERT, UPDATE
AS
	Declare @NGAYVAO smalldatetime, @NGAYLAP smalldatetime
	SELECT @NGAYVAO = I.NGAYVL, @NGAYLAP = PB.NgayTL FROM inserted I, PHONGBAN PB
	WHERE PB.MAPB = I.MAPB
	IF(@NGAYVAO < @NGAYLAP)
	BEGIN
		PRINT 'Error: Ngay vao lam truoc ngay thanh lap'
		Rollback tran
	END
GO
INSERT INTO PHONGBAN(MAPB, TENPB, DIACHI, NgayTL, MATrP)
VALUES
	('KT','Kinh te','HANOI','2000-04-21', '01'),
	('TM','Thuong mai','TPHCM','2000-10-12','02'),
	('NC','Nhan cong','DANANG','1999-02-01','03');
GO
INSERT INTO VITRI(MAVT, MOTA)
VALUES
	('71','Ke toan'),
	('72','Nhan vien van phong'),
	('73','Truong phong');
Go
INSERT INTO MUCLUONG(MAML, MUCTHAP, MUCCAO)
VALUES
	('21','2000000','8000000');
GO
INSERT INTO NHANVIEN(MANV, TENNV, MAVT, MAPB,LUONG,NGAYVL)
VALUES
	('01','Khoa Phan','73','KT','4000000', '2004-04-21'),
	('02','Duy Nguyen','72','KT','2000000','2004-02-23'),
	('03','Quan Doan','71','NC','5000000','2004-01-02'),
	('04','Phat Nguyen','72','KT','2000000','2004-02-23'),
	('05','Phat Doan','72','KT','2000000','2004-02-23'),
	('06','Kiet Nguyen','72','KT','2000000','2004-02-23');
GO
--In ra danh sách các nhân viên (Manv, Hoten) của phòng ’NC’.
SELECT MANV,TENNV FROM NHANVIEN WHERE MAPB = 'NC';
GO
--Tìm họ tên nhân viên có vị trí là ’Truong Phong’ (Mota) của phòng  ’KT’ (Maphg). 
SELECT TENNV FROM NHANVIEN 
	WHERE MANV IN (
		SELECT MANV FROM PHONGBAN P, VITRI V, NHANVIEN NV WHERE NV.MAPB = P.MAPB AND NV.MAVT = V.MAVT AND P.MAPB = 'KT'AND V.MOTA = 'Truong phong'
);
GO
--Tìm tên phòng ban có 5 nhân viên có lương 2.000.000  trở lên
SELECT P.TENPB FROM PHONGBAN P INNER JOIN NHANVIEN N ON P.MAPB = N.MAPB
WHERE N.LUONG >= 2000000
GROUP BY P.TENPB 
HAVING COUNT(N.MANV) >= 5;
--Tìm những nhân viên có mức lương lớn hơn 3000. 
SELECT NV.MANV FROM NHANVIEN NV
WHERE NV.LUONG > 3000
GO
-- In ra thông tin các phòng ban có số lương nhân viên hơn 2 người. Các thông tin: mã phòng ban, tên phòng ban, số lương nhân viên thuộc phòng ban đó.
SELECT PB.MAPB, PB.TENPB, count(NV.MANV) as SoLuongNV FROM PHONGBAN PB JOIN NHANVIEN NV ON PB.MAPB = NV.MAPB
GROUP BY PB.MAPB, PB.TENPB
HAVING count(NV.MANV) >= 2;
GO
--In ra mã mức lương của các nhân viên (MaNV, TenNV, MaML)
SELECT NV.MANV, NV.TENNV, ML.MAML FROM NHANVIEN NV, MUCLUONG ML
WHERE NV.MANV IN (
		SELECT NV.MANV FROM MUCLUONG ML WHERE NV.LUONG > ML.MUCTHAP AND NV.LUONG < ML.MUCCao
	);

