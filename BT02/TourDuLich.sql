USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'DULICH')
BEGIN
	ALTER DATABASE DULICH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DULICH;
END
GO

CREATE DATABASE DULICH
GO

USE DULICH
GO

Create TABLE TOUR
(
	MAT char(4) primary key,
	TENT char(40),
	nNGAY int, nDEM int,
	PTDI char(12), PTVE char(12),
	GIALE int, GIANHOM int
)
CREATE TABLE TINHTP
(
	MATP char(5) primary key,
	TENTP char(20),
	MIEN char(5)
)
CREATE TABLE DIEMDL
(
	MADL char(5) primary key,
	TENDL char(20),
	MATP char(5) foreign key references TINHTP(MATP),
	DACTRUNG char(40)
)
CREATE TABLE CHITIET
(
	MAT char(4) foreign key references TOUR(MAT),
	MADL char(5) foreign key references DIEMDL(MADL),
	NGAY int, DEM int
)
--Mỗi Tour luôn có giá lẻ (GiaLe) cao hơn giá theo nhóm (GiaNhom) từ 10% đến 20%
ALTER TABLE TOUR ADD CONSTRAINT ck_giasi CHECK(GIALE < 1.2 * GIANHOM AND GIALE > 1.1 * GIANHOM)
GO


INSERT INTO TOUR(MAT,TENT,nNGAY,nDEM,PTDI,PTVE,GIALE,GIANHOM)
VALUES
	('01','Tour 1','2','3','Xe khach','Xe Khach','1800000','1600000'),
	('02','Tour 2','3','4','Oto','May bay','1600000','1400000');

GO

INSERT INTO TINHTP(MATP,TENTP,MIEN)
VALUES
	('DN','Da Nang','Trung'),
	('DL','Da Lat','Trung'),
	('HCM','TPHCM','Nam'),
	('HP','Hai Phong','Bac');
GO

INSERT INTO DIEMDL(MADL,TENDL,MATP,DACTRUNG)
VALUES
	('PT','Phan Thiet','DN','Tam bien'),
	('LB','LaingBian','DL','Leo nui'),
	('HL','Vinh Ha Long','HP','Tam bien'),
	('CXG','Coi xay gio','DL','Leo Nui');
GO

INSERT INTO CHITIET(MAT,MADL,NGAY,DEM)
VALUES
	('01','HL','2','1'),
	('02','PT','1','1'),
	('02','LB','1','2');
GO
--Tìm những Tour (MaTour, TenTour, SoNgay, SoDem, PT_Di, PT_Ve, GiaLe) đi qua điểm du lịch có đặc trưng là ‘Leo nui’ hoặc ‘Tam bien’ với giá theo nhóm (GiaNhom) từ 1.500.000 đến 2.000.000. 
SELECT T.MAT, T.TENT, T.nNGAY, T.nDEM,T.PTDI,T.GIALE FROM TOUR T JOIN CHITIET CT ON T.MAT = CT.MAT JOIN DIEMDL DL ON CT.MADL = DL.MADL
WHERE DL.DACTRUNG IN ('Leo nui','Tam bien') AND T.GIANHOM between 1500000 and 2000000
GO
--Tìm những tỉnh (thành phố) ở miền ‘Nam’ chưa có điểm du lịch nào
SELECT TP.MATP, TP.TENTP FROM TINHTP TP
WHERE TP.MATP Not IN (
		SELECT TP.MATP FROM TINHTP TP JOIN DIEMDL DL ON DL.MATP = TP.MATP 
		)
GO
--Tìm những Tour (MaTour)  ít nhất 1 ngày 1 đêm ở điểm du lịch ‘Vinh Ha Long’ (TenDDL)
SELECT CT.MAT FROM CHITIET CT JOIN DIEMDL DL ON CT.MADL = DL.MADL
WHERE DL.TENDL = 'Vinh Ha Long' and CT.NGAY > 0 AND CT.DEM > 0
GO
--Tìm tên tỉnh (thành phố) có nhiều điểm du lịch nhất
WITH TOPTINH AS (
			SELECT TP.TENTP, COUNT(DL.MADL) as SoDiemDuLich FROM TINHTP TP JOIN DIEMDL DL ON TP.MATP = DL.MATP
			GROUP BY TP.TENTP 
			)
SELECT TENTP FROM TOPTINH WHERE SoDiemDuLich = (SELECT MAX(SoDiemDuLich) FROM TOPTINH)
--Tìm những Tour (MaTour, TenTour) 3 ngày 4 đêm đi bằng ‘Oto’, về bằng ‘May bay’ và qua ít nhất 2 điểm du lịch ở miền ‘Trung’ 
SELECT T.MAT, T.TENT FROM TOUR T JOIN CHITIET CT ON T.MAT = CT.MAT JOIN DIEMDL DL ON CT.MADL = DL.MADL
WHERE T.nNGAY = 3 and T.nDEM = 4 and T.PTDI = 'Oto' and T.PTVE = 'May bay' AND DL.MATP IN (
	SELECT MATP FROM TINHTP WHERE MIEN = 'Trung')
Group by T.MAT, T.TENT
HAVING COUNT(DISTINCT DL.MADL) > 1
