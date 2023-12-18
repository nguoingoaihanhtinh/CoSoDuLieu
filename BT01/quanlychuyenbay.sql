USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'DeAirport')
BEGIN
	ALTER DATABASE DeAirport SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DeAirport;
END
GO

CREATE DATABASE DeAirport
GO

USE DeAirport
GO

Create Table CHUYENBAY
(
	MACB char(5) primary key,
	NOIXP char(15),
	NOIDEN char(15),
	GIOXP smalldatetime,
	GIODEN smalldatetime
)
Create table PHICO
(
	MAPCo char(5) primary key,
	TENPCo char(50),
	KCBAY int
)
CREATE TABLE PHICONG
(
	MAPC char(5) primary key,
	TENPC char(40),
	LUONG int
)
CREATE TABLE CHUNGNHAN
(
	MAPCo char(5) foreign key references PHICO(MAPCo),
	MAPC char(5) foreign key references PHICONG(MAPC)
)
Go

--Giờ xuất phát phải trước giờ đến.
Alter table CHUYENBAY add CONSTRAINT ck_gio CHECK(GIOXP <GIODEN)
GO
--Nơi xuất phát phải khác nơi đến
ALTER table CHUYENBAY add CONSTRAINT ck_diadiem CHECK(NOIXP != NOIDEN) 
GO


INSERT INTO CHUYENBAY(MACB,NOIXP,NOIDEN,GIOXP,GIODEN)
VALUES
	('VN01','Ha Noi','Hue','2023-12-12','2023-12-14');
GO

INSERT INTO PHICO(MAPCo,TENPCo,KCBAY)
VALUES
	('VN','Viet Nam Airline','3000'),
	('BO','Boeing','5000');
GO

INSERT INTO PHICONG(MAPC,TENPC,LUONG)
VALUES
	('PC01','Khoa Phan','10000000'),
	('PC02','Quan Doan','12000000');
GO

INSERT INTO CHUNGNHAN(MAPCo, MAPC)
VALUES
	('BO','PC01'),
	('VN','PC01'),
	('VN','PC02');
GO

--Tìm mã các phi công lái được ’máy bay Boeing' 
SELECT CN.MAPC FROM CHUNGNHAN CN JOIN PHICO PCo ON CN.MAPCo = PCo.MAPCo WHERE PCo.TENPCo = 'Boeing';

--Tìm mã, tên (các) phi công có mức lương cao nhất.
SELECT PC.MAPC, PC.TENPC, PC.LUONG as LUONG FROM PHICONG PC
WHERE PC.LUONG = (SELECT MAX(LUONG) FROM PHICONG )
GO
--Tìm những phi công (MaPhiCong, TenPhiCong) có khả năng lái tất cả các loại phi cơ.
SELECT PC.MAPC, PC.TENPC FROM  PHICONG PC
WHERE NOT EXISTS ( SELECT MAPCo FROM PHICO PCo WHERE NOT EXISTS	
											(SELECT 1 FROM CHUNGNHAN CN WHERE CN.MAPC = PC.MAPC AND CN.MAPCo = PCo.MAPCo)
											);

