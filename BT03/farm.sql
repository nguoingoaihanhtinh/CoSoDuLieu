USE master
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME = 'Farm')
BEGIN
	ALTER DATABASE Farm SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Farm;
END
GO

CREATE DATABASE Farm
GO

USE Farm
GO

/*
VatNuoi(MaVatNuoi, TenVatNuoi, MaNCC, TG_SinhTruong, LoaiVatNuoi )Thông tin về hoa bao gồm: Mã vật nuôi, Tên của vật nuôi, Mã nhà cung cấp giống, Thời gian sinh trưởng (ngày), Loại vật nuôi)
NhaCungCap(MaNCC, TenNCC, DiaChi, Email, SDT)Thông tin về hoa bao gồm:Mã nhà cung cấp, Tên Nhà cung cấp, Địa chỉ, Email, Số điện thoại
NongTrai(MaNongTrai, TenNongTrai,MaNongHo, LoaiNongTrai, DienTich)Thông tin về Nông trại bao gồm: Mã nông trại, Tên nông trại,Mã nông hộ, Loại nông trại, Diện tích (mét vuông)
NongHo(MaNongHo, TenNongHo, DiaChi, SDT)Thông tin về Nông hộ bao gồm: Mã nông hộ, Tên nông hộ, Địa chỉ, Số điện thoại
ChanNuoi(MaVatNuoi, MaNongTrai   , NgayBD,    NgayTH, SanLuong)Thông tin về Chăn nuôi gồm: Mã vật nuôi, Mã nông trại, Ngày bắt đầu, Ngày thu hoạch, Sản lượng (kg)
*/


CREATE TABLE NHACUNGCAP
(
	MACC char(4) primary key,
	TENCC char(25) not null,
	DIACHI char(50) not null,
	EMAIL varchar(50),
	SDT char(20)
)
Create table VATNUOI
(
	MAVN char(4) primary key,
	TENVN varchar(25) not null,
	MACC char(4) foreign key references NHACUNGCAP(MACC),
	TGST int not null,
	LOAIVN varchar(25) not null
)
CREATE TABLE NHAVUON -- Nong Ho
(
	MANH char(4) primary key,
	TENNH varchar(25) not null,
	DIACHI varchar(25) not null,
	SDT char(10)
)
CREATE TABLE NONGTRAI
(
	MANT char(4) primary key,
	TENNT varchar(25) not null,
	MANH char(4) foreign key references NHAVUON(MANH),
	LOAINT varchar(25) not null,
	DIENTICH int
)
CREATE TABLE CHANNUOI
(
	MAVN char(4) foreign key references VATNUOI(MAVN),
	MANT char(4) foreign key references NONGTRAI(MANT),
	NGAYBD smalldatetime primary key,
	NGAYTH smalldatetime,
	SANLUONG int
)
-- Thời gian sinh trưởng của vật nuôi tối thiểu là 60 ngày
ALTER TABLE VATNUOI ADD CONSTRAINT ck_sinhtr CHECK(TGST >= 60)
GO
--Loại vật nuôi gồm các vụ mùa sau (“Gia súc”,“ Gia cầm”, “Cá”, “ Loại khác”)
ALTER TABLE VATNUOI ADD CONSTRAINT ck_loaivn CHECK( LOAIVN IN('Gia suc','Gia cam','Ca','Khac'))
GO
--Viết trigger cho thao tác thêm mới trong bảng CHANNUOI, kiểm tra nếu vật nuôithuộc loại “Cá” thì loại nông trại phải thuộc loại “Ao hồ”
CREATE TRIGGER ck_aoho ON CHANNUOI
FOR INSERT, UPDATE 
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM INSERTED I, VATNUOI VN, NONGTRAI NT
	WHERE I.MAVN = VN.MAVN AND I.MANT = NT.MANT AND VN.LOAIVN = 'Ca' AND NT.LOAINT = 'Ao ho')
	BEGIN
		PRINT 'Error: Vat nuoi Ca phai thuoc loai Ao ho'
		ROLLBACK TRAN
	END
END
GO
INSERT INTO NHACUNGCAP(MACC,TENCC,DIACHI,EMAIL,SDT)
VALUES
	('CC01','Cung cap 1','TpHCM','cc1@gmail.com','1234567890'),
	('CC02','Cung cap 2','Ha Noi','cc2@gmail.com','1269358629');

GO
INSERT INTO VATNUOI(MAVN,TENVN,MACC,TGST,LOAIVN)
VALUES
	('OC01','Ca Dieu Hong','CC01','70','Ca'),
	('OC02','Ca Basa','CC02','71','Ca'),
	('PO01','Ga Dong Tao','CC01','75','Gia cam'),
	('CA01','Bo Xiem Thit','CC02','61','Gia suc');
GO
INSERT INTO NHAVUON(MANH,TENNH, DIACHI, SDT)
VALUES
	('NV01','Nha vuon 1','Da Lat','0165496976'),
	('NV02','Nguyen Anh Tuan','Bac Ninh','0513589378');
GO
INSERT INTO NONGTRAI(MANT, TENNT, MANH, LOAINT, DIENTICH)
VALUES
	('NT01','Ho Lac Long Vuong','NV01','Ao ho','3000'),
	('NT02','Nui Au Co','NV02','Doi nui','2000'),
	('NT03','Ho Con Rua','NV02','Ao ho','1000');
GO
INSERT INTO CHANNUOI(MAVN,MANT,NGAYBD,NGAYTH,SANLUONG)
VALUES
	('OC01','NT01','2020-6-6','2021-1-1','30'),
	('CA01','NT02','2018-8-8','2021-2-2','20'),
	('PO01','NT02','2020-4-4','2021-5-5','100'),
	('OC02','NT03','2020-5-5','2021-6-6','200');
GO
--Liệt   kê   danh   sách   nông   trại   và   nông   hộ   sở   hữu   nông   trại   (TenNongTrai,TenNongHo) nuôi “Cá diêu hồng”, các nông trại phải có diện tích hơn 1.000 mét vuông
SELECT NT.TENNT, NH.TENNH FROM NONGTRAI NT JOIN NHAVUON NH ON NH.MANH = NT.MANH JOIN CHANNUOI CN ON CN.MANT = NT.MANT JOIN VATNUOI VN ON VN.MAVN = CN.MAVN
WHERE VN.TENVN ='Ca Dieu Hong' AND NT.DIENTICH > 1000;
GO
--Tìm những Nhà cung cấp (MaNCC, TenNCC, NgayTH, SanLuong) đã cung cấpvật nuôi “ Bò xiêm thịt” đã thu hoạch từ tháng 1 đến tháng 6 năm 2021
SELECT CC.MACC, CC.TENCC, CN.NGAYTH, CN.SANLUONG FROM NHACUNGCAP CC JOIN VATNUOI VN ON CC.MACC = VN.MACC JOIN CHANNUOI CN ON CN.MAVN = VN.MAVN
WHERE YEAR(CN.NGAYTH) = '2021' AND (MONTH(CN.NGAYTH) between '1' and '6') AND VN.TENVN = 'Bo Xiem Thit'
GROUP BY CC.MACC, CC.TENCC, CN.NGAYTH, CN.SANLUONG
--Tìm những vật nuôi (MaVatNuoi,TenVatNuoi,LoaiVatNuoi) được nuôi trong năm2019, 2020 nhưng  không ai nuôi trong năm 2021 (Căn cứ NgayBD) 
SELECT VN.MAVN, VN.TENVN, VN.LOAIVN FROM VATNUOI VN JOIN CHANNUOI CN ON VN.MAVN = CN.MAVN
WHERE YEAR(CN.NGAYBD) IN ('2019','2020') AND VN.MAVN NOT IN
				(SELECT VN.MAVN FROM VATNUOI VN JOIN CHANNUOI CN ON VN.MAVN = CN.MAVN
				WHERE YEAR(CN.NGAYBD) = 2021);
--Tìm những nông hộ (MaNongHo,TenNongHo) đã   nuôi tất cả các loại vật nuôithuộc loại “ Gia cầm” (0,75 điểm)
SELECT NH.MANH, NH.TENNH FROM NHAVUON NH
WHERE NOT EXISTS (
		SELECT DISTINCT VN.MAVN FROM VATNUOI VN
		WHERE VN.LOAIVN = 'Gia cam'
		AND NOT EXISTS(
			SELECT CN.MAVN FROM CHANNUOI CN JOIN NONGTRAI NT ON CN.MANT = NT.MANT
			WHERE NT.MANH = NH.MANH AND CN.MAVN = VN.MAVN));
-- Thống kê tổng sản lượng tất cả vật nuôi theo từng nông trại của nông hộ “ NguyễnAnh   Tuấn”   thu   hoạch   trong   năm   2021   (theo   NgayTH)   thông   tin   cần   hiển   thị( MaNongTrai,TenNongTrai, TongSanLuong)
SELECT NT.MANT, NT.TENNT, sum(CN.SANLUONG) as TongSanLuong FROM NONGTRAI NT JOIN CHANNUOI CN ON NT.MANT = CN.MANT JOIN NHAVUON NH ON NH.MANH = NT.MANH
WHERE YEAR(CN.NGAYTH) = '2021' AND NH.TENNH = 'Nguyen Anh Tuan'
GROUP BY NT.MANT, NT.TENNT
GO
-- Nông hộ (MaNongHo,TenNongHo,TongSanLuong) nào thu hoạch được tổng sảnlượng của 2 loại: “Cá basa”+“ Cá diêu hồng” nhất trong năm 2021 (tính theo NgayTH)
WITH TongSanLuongNH as(
		SELECT NH.MANH, NH.TENNH, sum(CN.SANLUONG) as TongSanLuong FROM NHAVUON NH JOIN NONGTRAI NT ON NH.MANH = NT.MANH JOIN CHANNUOI CN ON CN.MANT = NT.MANT JOIN VATNUOI VN ON VN.MAVN = CN.MAVN
		WHERE YEAR(CN.NGAYTH) = '2021' AND VN.TENVN IN ('Ca Basa','Ca Dieu Hong')
		GROUP BY NH.MANH, NH.TENNH
)
SELECT MANH, TENNH, TongSanLuong FROM TongSanLuongNH 
WHERE TongSanLuong = (SELECT max(TongSanLuong) From TongSanLuongNH)
GO
