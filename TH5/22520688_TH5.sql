------------------------------ QUANLYBANHANG ------------------------------------------
/*
DROP TABLE KHACHHANG
DROP TABLE NHANVIEN
DROP TABLE SANPHAM
DROP TABLE HOADON
DROP TABLE CTHD

DELETE FROM KHACHHANG
DELETE FROM NHANVIEN
DELETE FROM SANPHAM
DELETE FROM HOADON
DELETE FROM CTHD

SELECT * FROM KHACHHANG
SELECT * FROM NHANVIEN
SELECT * FROM SANPHAM
SELECT * FROM HOADON
SELECT * FROM CTHD
*/
GO

SET DATEFORMAT DMY;
USE QUANLYBANHANG
GO

-- I. Ngôn ngữ định nghĩa dữ liệu (Data Definition Language):
-- 11.	Ngày mua hàng (NGHD) của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK).
CREATE TRIGGER TRG_HD_KH ON HOADON FOR INSERT
AS
BEGIN
	DECLARE @NGHD SMALLDATETIME, @NGDK SMALLDATETIME, @MAKH CHAR(4)
	SELECT @NGHD = NGHD, @MAKH = MAKH FROM INSERTED
	SELECT	@NGDK = NGDK FROM KHACHHANG WHERE MAKH = @MAKH

	PRINT @NGHD 
	PRINT @NGDK

	IF (@NGHD >= @NGDK)
		PRINT N'Thêm mới một hóa đơn thành công.'
	ELSE
	BEGIN
		PRINT N'Lỗi: Ngày mua hàng của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên.'
		ROLLBACK TRANSACTION
	END
END
GO

INSERT INTO HOADON(SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES('1024', '22/07/2005', 'KH01', 'NV01', '320000')
delete from HOADON where SOHD = '1024'
GO

-- 12.	Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.
CREATE TRIGGER TRG_HD_NV ON HOADON FOR INSERT
AS
BEGIN
	DECLARE @NGHD SMALLDATETIME, @NGVL SMALLDATETIME, @MANV CHAR(4)
	SELECT @NGHD = NGHD, @MANV = MANV FROM INSERTED
	SELECT	@NGVL = NGVL FROM NHANVIEN WHERE MANV = @MANV

	IF (@NGHD >= @NGVL)
		PRINT N'Thêm mới một hóa đơn thành công.'
	ELSE
	BEGIN
		PRINT N'Lỗi: Ngày bán hàng của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.'
		ROLLBACK TRANSACTION
	END
END
GO

-- 13.	Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.
CREATE TRIGGER TRG_HD_CTHD ON HOADON FOR INSERT
AS
BEGIN
	DECLARE @SOHD INT, @COUNT_SOHD INT
	SELECT @SOHD = SOHD FROM INSERTED
	SELECT @COUNT_SOHD = COUNT(SOHD) FROM CTHD WHERE SOHD = @SOHD

	IF (@COUNT_SOHD >= 1)
		PRINT N'Thêm mới một hóa đơn thành công.'
	ELSE
	BEGIN
		PRINT N'Lỗi: Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.'
		ROLLBACK TRANSACTION
	END
END
GO

-- 14.	Trị giá của một hóa đơn là tổng thành tiền (số lượng*đơn giá) của các chi tiết thuộc hóa đơn đó.
CREATE TRIGGER TRG_CTHD ON CTHD FOR INSERT, DELETE
AS
BEGIN
	DECLARE @SOHD INT, @TONGGIATRI INT

	SELECT @TONGGIATRI = SUM(SL * GIA), @SOHD = SOHD 
	FROM INSERTED INNER JOIN SANPHAM
	ON INSERTED.MASP = SANPHAM.MASP
	GROUP BY SOHD

	UPDATE HOADON
	SET TRIGIA += @TONGGIATRI
	WHERE SOHD = @SOHD
END
GO 

CREATE TRIGGER TR_DEL_CTHD ON CTHD FOR DELETE
AS
BEGIN
	DECLARE @SOHD INT, @GIATRI INT

	SELECT @SOHD = SOHD, @GIATRI = SL * GIA 
	FROM DELETED INNER JOIN SANPHAM 
	ON SANPHAM.MASP = DELETED.MASP

	UPDATE HOADON
	SET TRIGIA -= @GIATRI
	WHERE SOHD = @SOHD
END
GO


-------------------------------- QUANLYHOCVU ------------------------------------------
/*
DROP TABLE KHOA 
DROP TABLE MONHOC 
DROP TABLE DIEUKIEN 
DROP TABLE GIAOVIEN  
DROP TABLE LOP 
DROP TABLE HOCVIEN 
DROP TABLE GIANGDAY  
DROP TABLE KETQUATHI  

DELETE FROM KHOA 
DELETE FROM MONHOC 
DELETE FROM DIEUKIEN
DELETE FROM GIAOVIEN
DELETE FROM LOP
DELETE FROM HOCVIEN
DELETE FROM GIANGDAY
DELETE FROM KETQUATHI

SELECT * FROM KHOA 
SELECT * FROM MONHOC 
SELECT * FROM DIEUKIEN
SELECT * FROM GIAOVIEN
SELECT * FROM LOP
SELECT * FROM HOCVIEN
SELECT * FROM GIANGDAY
SELECT * FROM KETQUATHI
*/
GO

USE QUANLYHOCVU
GO

-- I. Ngôn ngữ định nghĩa dữ liệu (Data Definition Language):
-- 9.	Lớp trưởng của một lớp phải là học viên của lớp đó.
CREATE TRIGGER trg_ins_udt_LopTruong ON LOP
FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, HOCVIEN HV
	WHERE I.TRGLOP = HV.MAHV AND I.MALOP = HV.MALOP)
	BEGIN
		PRINT 'Error: Lop truong cua mot lop phai la hoc vien cua lop do'
		ROLLBACK TRANSACTION
	END
END
Go
CREATE TRIGGER trg_del_HOCVIEN ON HOCVIEN
FOR DELETE
AS
BEGIN
	IF EXISTS (SELECT * FROM DELETED D, INSERTED I, LOP L 
	WHERE D.MAHV = L.TRGLOP AND D.MALOP = L.MALOP)
	BEGIN
		PRINT 'Error: Hoc vien hien tai dang la truong lop'
		ROLLBACK TRANSACTION
	END
END

-- UPDATE LOP SET TRGLOP = 'K1205' Where MALOP = 'K11'
-- UPDATE LOP SET TRGLOP = 'K1105' Where MALOP = 'K11'
SELECT * FROM LOP
GO

-- 10.	Trưởng khoa phải là giáo viên thuộc khoa và có học vị “TS” hoặc “PTS”.
-- Trigger len KHOA
CREATE TRIGGER trg_ins_TruongKhoa ON KHOA
FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, GIAOVIEN GV
	WHERE I.TRGKHOA = GV.MAGV AND I.MAKHOA = GV.MAKHOA)
	BEGIN
		PRINT 'Error: Truong khoa phai la mot giao vien thuoc khoa do'
		ROLLBACK TRANSACTION
	END
END
GO
CREATE TRIGGER trg_ins_Hocvi_TruongKhoa ON KHOA
FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, GIAOVIEN GV
	WHERE I.TRGKHOA = GV.MAGV AND (GV.HOCVI = 'TS' OR GV.HOCVI = 'PTS'))
	BEGIN
		PRINT 'Error: Truong khoa phai la mot giao vien co hoc vi la PTS hay TS'
		ROLLBACK TRANSACTION
	End
ENd
-- UPDATE KHOA SET TRGKHOA = 'GV01' Where MAKHOA = 'KHMT'
GO

--Trigger len GIAOVIEN
CREATE TRIGGER trg_ins_TruongKhoa_gv ON GIAOVIEN
FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, KHOA K
	WHERE I.MAGV = K.TRGKHOA AND I.MAKHOA = K.MAKHOA)
	BEGIN
		PRINT 'Error: Truong khoa phai la mot giao vien thuoc khoa do'
		ROLLBACK TRANSACTION
	END
END
GO
CREATE TRIGGER trg_ins_Hocvi_TruongKhoa_gv ON GIAOVIEN
FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, KHOA K
	WHERE I.MAGV = K.TRGKHOA AND (I.HOCVI = 'TS' OR I.HOCVI = 'PTS'))
	BEGIN
		PRINT 'Error: Truong khoa phai la mot giao vien co hoc vi la PTS hay TS'
		ROLLBACK TRANSACTION
	End
ENd

-- UPDATE GIAOVIEN SET HOCVI = 'CN' WHERE MAGV = 'GV01'

-- 15.	Học viên chỉ được thi một môn học nào đó khi lớp của học viên đã học xong môn học này.
-- Trigger len KETQUATHI
CREATE TRIGGER trg_ins_ketqua ON KETQUATHI
FOR INSERT, UPDATE
AS 
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, HOCVIEN HV, GIANGDAY GD
	WHERE I.MAHV = HV.MAHV AND HV.MALOP = GD.MALOP AND I.MAMH = GD.MAMH AND I.NGTHI > GD.DENNGAY)
	BEGIN
		Print 'Error: Hoc vien phai hoc xong mon hoc de duoc thi'
		ROLLBACK TRANSACTION
	END
END

--INSERT INTO KETQUATHI (MAHV, MAMH, LANTHI, NGTHI, DIEM, KQUA)
--VALUES 
        
--		('K1211', 'CSDL' ,1, '2006/20/05', 10.00, 'Dat');
GO
-- Trigger len GIANGDAY
CREATE TRIGGER trg_ins_ketqua_GD ON GIANGDAY
FOR INSERT, UPDATE
AS
BEGIN 
	IF NOT EXISTS (SELECT * FROM INSERTED I, HOCVIEN HV, KETQUATHI KQ
	WHERE I.MALOP = HV.MALOP AND HV.MAHV = KQ.MAHV AND I.MAMH = KQ.MAMH AND I.DENNGAY < KQ.NGTHI)
	BEGIN
		PRINT 'Error: Ngay ket thuc lop phai som hon ngay thi mon hoc'
		ROLLBACK TRANSACTION
	END
END
GO

--UPDATE GIANGDAY SET DENNGAY = '2006-21-03' Where MALOP = 'K11'AND MAMH = 'THDC'
--GO


-- 16.	Mỗi học kỳ của một năm học, một lớp chỉ được học tối đa 3 môn.
CREATE TRIGGER trg_ins_maxmonhoc ON GIANGDAY
FOR INSERT, UPDATE
AS
BEGIN 
	DECLARE @SL_Mon INT
	SELECT @SL_Mon = COUNT(GD.MAMH) FROM INSERTED I, GIANGDAY GD
	WHERE I.MALOP = GD.MALOP AND I.HOCKY = GD.HOCKY AND I.NAM = GD.NAM
	IF(@SL_Mon = 4)
	BEGIN
		PRINT 'Error: Lop nay da hoc qua 3 mon mot hoc ky'
		ROLLBACK TRANSACTION
	END
END
GO

--UPDATE GIANGDAY SET HOCKY = '1' WHERE MALOP = 'K11' AND MAMH = 'CTDLGT'
--UPDATE GIANGDAY SET HOCKY = '1' WHERE MALOP = 'K11' AND MAMH = 'CSDL'
--SELECT * FROM GIANGDAY

-- 17.	Sỉ số của một lớp bằng với số lượng học viên thuộc lớp đó.

--------------
CREATE TRIGGER INSERT_HOCVIEN
ON HOCVIEN
FOR INSERT
AS
		UPDATE LOP
		SET SISO=SISO+1
		WHERE MALOP=(SELECT MALOP
		FROM INSERTED)
GO
------------
Create TRIGGER DELETE_HOCVIEN
ON HOCVIEN
FOR DELETE
AS
		
	Declare @MALOP CHAR(3)
	SELECT @MALOP=D.MALOP
	FROM DELETED D, LOP L
	WHERE D.MALOP=L.MALOP
	UPDATE LOP
	SET SISO=SISO-1
	WHERE MALOP=@MALOP
GO
-------------
CREATE TRIGGER UPDATE_HOCVIEN
ON HOCVIEN
FOR UPDATE
AS
	UPDATE LOP SET SISO=SISO+1
	WHERE MALOP=(SELECT MALOP
	FROM INSERTED)
UPDATE LOP
SET SISO=SISO-1
WHERE MALOP=(SELECT MALOP
 FROM DELETED)
	-------------------------

/*INSERT INTO HOCVIEN(MAHV, HO, TEN, NGSINH, GIOITINH, NOISINH, MALOP)
	VALUES ('K1112', 'Nguyen Xuan', 'Duy' ,'1986-01-27' ,'Nam' ,'TpHCM' ,'K11');
DELETE HOCVIEN WHERE MAHV = 'K1112'
Update HOCVIEN SET MALOP = 'K12' WHERE MAHV = 'K1112'
SELECT * FROM LOP
SELECT * FROM HOCVIEN*/

GO

/* 18.	Trong quan hệ DIEUKIEN giá trị của thuộc tính MAMH và MAMH_TRUOC trong cùng một bộ 
không được giống nhau (“A”,”A”) và cũng không tồn tại hai bộ (“A”,”B”) và (“B”,”A”). */
CREATE Trigger trg_ins_update ON DIEUKIEN
FOR INSERT, UPDATE
AS
	Declare @MAMH varchar(10), @MAMH_TRUOC varchar(10)
	SELECT @MAMH = I.MAMH, @MAMH_TRUOC = I.MAMH_TRUOC FROM INSERTED I
	IF((@MAMH = @MAMH_TRUOC) OR 
		(@MAMH IN (SELECT DK.MAMH_TRUOC FROM DIEUKIEN DK WHERE DK.MAMH = @MAMH_TRUOC)) OR
		(@MAMH_TRUOC IN (SELECT DK.MAMH FROM DIEUKIEN DK WHERE DK.MAMH_TRUOC = @MAMH)))
	Begin
		Print 'Dieu kien khong hop le'
		Rollback Transaction
	ENd
GO

--INSERT INTO DIEUKIEN(MAMH, MAMH_TRUOC)
--VALUES ('CTRR', 'CSDL')

-- 19.	Các giáo viên có cùng học vị, học hàm, hệ số lương thì mức lương bằng nhau.
alter trigger trg_updt_luonggv ON GIAOVIEN
FOR INSERT, UPDATE
AS
	Declare @LUONG money, @MAGV char(4)
	SELECT DISTINCT @LUONG = GV.MUCLUONG, @MAGV = I.MAGV FROM GIAOVIEN GV, INSERTED I
	WHERE GV.HOCHAM = I.HOCHAM AND GV.HOCVI = I.HOCVI AND GV.HESO = I.HESO AND GV.MAGV <> I.MAGV
	UPDATE GIAOVIEN SET MUCLUONG = @LUONG WHERE  MAGV = @MAGV
GO
/*
INSERT INTO GIAOVIEN(MAGV, HOTEN, HOCVI, HOCHAM, GIOITINH, NGSINH, NGVL, HESO, MUCLUONG, MAKHOA)
VALUES 
('GV16', 'Phan Tuan Anh Khoa', 'PTS', 'GS', 'Nam', '1950-05-02' ,'2004-01-11' ,5.00, 2350000, 'CNPM');
SELECT * FROm GIAOVIEN
*/
-- 20.	Học viên chỉ được thi lại (lần thi >1) khi điểm của lần thi trước đó dưới 5.
create Trigger trg_ins_updt_thilai ON KETQUATHI
FOR INSERT, UPDATE
AS
	DECLARE @LANTHI INT, @DIEM NUMERIC(4,2)
	SELECT @LANTHI = I.LANTHI FROM INSERTED I
	IF(@LANTHI > 1)
		BEGIN
			SELECT @DIEM = KQ.DIEM FROM INSERTED I, KETQUATHI KQ
			WHERE I.MAHV = KQ.MAHV AND I.MAMH = KQ.MAMH AND KQ.LANTHI = @LANTHI - 1
			IF(@DIEM >= 5)
				BEGIN 
					PRINT 'Hoc vien da thi dat mon nay'
					ROLLBACK TRANSACTION
				END
		END
	DELETE FROM KETQUATHI
	WHERE LANTHI > @LANTHI
GO

--INSERT INTO KETQUATHI (MAHV, MAMH, LANTHI, NGTHI, DIEM, KQUA)
--VALUES 
 --       ('K1101', 'CSDL' ,2, '2006-07-20', 9.00, 'Dat');

-- 21.	Ngày thi của lần thi sau phải lớn hơn ngày thi của lần thi trước (cùng học viên, cùng môn học).
create TRIGGER trg_ins_ngaythi ON KETQUATHI
FOR INSERT, UPDATE
AS 
	DECLARE @NGAYTHI SMALLDATETIME, @LANTHI INT, @NGAYTHISAU smalldatetime, @LANTHISAU INT
	SELECT @LANTHI = KQ.LANTHI, @LANTHISAU = I.LANTHI, @NGAYTHI = KQ.NGTHI, @NGAYTHISAU = I.NGTHI FROM INSERTED I, HOCVIEN HV, KETQUATHI KQ
	WHERE I.MAHV = HV.MAHV AND I.MAMH = KQ.MAMH
	IF(@LANTHI < @LANTHISAU)
		BEGIN
			IF(@NGAYTHI > @NGAYTHISAU)
			BEGIN	
				PRINT 'Ngay thi khong hop le'
				Rollback Transaction
			END
		END
	Else
		PRINT 'Hoc vien da thi lan nay roi'
GO
/*
INSERT INTO KETQUATHI (MAHV, MAMH, LANTHI, NGTHI, DIEM, KQUA)
VALUES 
        ('K1104', 'CSDL' ,2, '2006-06-20', 9.00, 'Dat');
SELECT * FROM KETQUATHI
*/
-- 22.	Học viên chỉ được thi những môn mà lớp của học viên đó đã học xong.
CREATE TRIGGER trg_ins_ketqua_22 ON KETQUATHI
FOR INSERT, UPDATE
AS 
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, HOCVIEN HV, GIANGDAY GD
	WHERE I.MAHV = HV.MAHV AND HV.MALOP = GD.MALOP AND I.MAMH = GD.MAMH AND I.NGTHI > GD.DENNGAY)
	BEGIN
		Print 'Error: Hoc vien phai hoc xong mon hoc de duoc thi'
		ROLLBACK TRANSACTION
	END
END

--INSERT INTO KETQUATHI (MAHV, MAMH, LANTHI, NGTHI, DIEM, KQUA)
--VALUES 
        
--		('K1211', 'CSDL' ,1, '2006/20/05', 10.00, 'Dat');
GO
-- Trigger len GIANGDAY
CREATE TRIGGER trg_ins_ketqua_GD_22 ON GIANGDAY
FOR INSERT, UPDATE
AS
BEGIN 
	IF NOT EXISTS (SELECT * FROM INSERTED I, HOCVIEN HV, KETQUATHI KQ
	WHERE I.MALOP = HV.MALOP AND HV.MAHV = KQ.MAHV AND I.MAMH = KQ.MAMH AND I.DENNGAY < KQ.NGTHI)
	BEGIN
		PRINT 'Error: Ngay ket thuc lop phai som hon ngay thi mon hoc'
		ROLLBACK TRANSACTION
	END
END
GO


/* 23.	Khi phân công giảng dạy một môn học, phải xét đến thứ tự trước sau giữa các môn học 
(sau khi học xong những môn học phải học trước mới được học những môn liền sau). */
create TRIGGER trg_ins_thutuphancong_dkmh ON DIEUKIEN
FOR INSERT, UPDATE
AS 
	DECLARE @MAMH varchar(10), @MAMH_TRUOC varchar(10), @MAMH2 varchar(10)
	SELECT @MAMH = I.MAMH, @MAMH_TRUOC = I.MAMH_TRUOC, @MAMH2 = DK.MAMH  FROM INSERTED I, DIEUKIEN DK
	IF(@MAMH_TRUOC = @MAMH2)
		BEGIN
			Print 'Phan cong mon hoc hop ly'
			Rollback Transaction
		END
	Else
		PRINT 'Can phai day mon hoc truoc'
GO
create TRIGGER trg_ins_thutuphancong ON GIANGDAY
FOR INSERT, UPDATE
AS 
	DECLARE @DENNGAY1 SMALLDATETIME, @TUNGAY2 smalldatetime
	SELECT @DENNGAY1 = GD.DENNGAY, @TUNGAY2 = I.TUNGAY FROM INSERTED I, GIANGDAY GD, GIAOVIEN GV
	WHERE GV.MAGV = I.MAGV
	IF(@TUNGAY2 < @DENNGAY1)
	BEGIN
		Print 'Error: Phai hoan thanh mon hoc truoc'
		Rollback Transaction
	END
	ELSE
		PRINT 'Phan cong thoi gian hop ly'
GO
/*
INSERT INTO GIANGDAY (MALOP, MAMH, MAGV, HOCKY, NAM, TUNGAY, DENNGAY)
VALUES
('K11' ,'LTHDT' ,'GV12', 3 ,2006 ,'2006-10-02' ,'2006-05-12');
GO
*/


-- 24.	Giáo viên chỉ được phân công dạy những môn thuộc khoa giáo viên đó phụ trách.
Create Trigger trg_ins_phancong ON GIANGDAY
FOR INSERT, UPDATE
AS	
BEGIN
	IF NOT EXISTS (SELECT * FROM INSERTED I, MONHOC MH, GIAOVIEN GV
	WHERE I.MAMH = MH.MAMH AND I.MAGV = GV.MAGV AND MH.MAKHOA = GV.MAKHOA)
	BEGIN 
		PRINT 'Error: Giao vien chi day nhung mon duoc phu trach'
		Rollback Transaction
	END
END
GO
/*
INSERT INTO GIANGDAY(MALOP, MAMH, MAGV, HOCKY, NAM, TUNGAY, DENNGAY)
VALUES
('K13' ,'LTHDT' ,'GV01', 1 ,2006 ,'2006-01-02' ,'2006-05-12');
*/