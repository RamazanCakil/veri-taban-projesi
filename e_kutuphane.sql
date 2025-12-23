create database if not exists kutuphane;
use kutuphane;

create table if not exists kullanici(
user_id int primary key AUTO_INCREMENT,
ad varchar(50) NOT NULL,
soyad varchar(50) NOT NULL,
email varchar(50) UNIQUE NOT NULL,
telefon varchar(50),
kayit_tarihi date check(kayit_tarihi>=0)

);
create table if not exists yazarlar(
author_id int primary key AUTO_INCREMENT,
author_name varchar(50) NOT NULL

);
create table if not exists kategori(
kategori_id int primary key AUTO_INCREMENT,
kategori_adi varchar(50) NOT NULL
);
create table if not exists kitaplar(
book_id int primary key AUTO_INCREMENT,
book_title varchar(50) NOT NULL,
isbn varchar(50) UNIQUE ,
publish_year int check(publish_year>=0),
stock int check(stock>=0),
author_id int NOT NULL,
kategori_id int NOT NULL,
foreign key (author_id) references yazarlar(author_id),
foreign key (kategori_id) references kategori(kategori_id)
);

create table if not exists odunc(
odunc_id int primary key AUTO_INCREMENT,
user_id int NOT NULL ,
book_id int NOT NULL,
loan_date date check(loan_date>=0),
due_date date check(due_date>=0),
return_date date check(return_date>=0),
foreign key (user_id) references kullanici(user_id),
foreign key (book_id) references kitaplar(book_id)
);
create table if not exists log(
log_id int primary key AUTO_INCREMENT,
user_id int NULL,
action_type varchar(50),
action_detail varchar(200),
log_date date check(log_date>=0),
foreign key (user_id) references kullanici(user_id)
);


INSERT INTO yazarlar (author_name) VALUES
('Sabahattin Ali'),
('Orhan Pamuk'),
('George Orwell'),
('Fyodor Dostoyevski'),
('J.K. Rowling');


INSERT INTO kategori (kategori_adi) VALUES
('Roman'),
('Bilim Kurgu'),
('Fantastik'),
('Psikoloji'),
('Tarih');


INSERT INTO kitaplar (book_title, isbn, publish_year, stock, author_id, kategori_id) VALUES
('Kürk Mantolu Madonna', '9789753638029', 1943, 5, 1, 1),
('Masumiyet Müzesi', '9789750818356', 2008, 3, 2, 1),
('1984', '9780451524935', 1949, 4, 3, 2),
('Suç ve Ceza', '9780140449136', 1866, 2, 4, 1),
('Harry Potter ve Felsefe Taşı', '9789750802942', 1997, 6, 5, 3);


INSERT INTO kullanici (ad, soyad, email, telefon, kayit_tarihi) VALUES
('Ali', 'Yılmaz', 'ali.yilmaz@mail.com', '05551234567', NOW()),
('Ayşe', 'Demir', 'ayse.demir@mail.com', '05559876543', NOW()),
('Mehmet', 'Kaya', 'mehmet.kaya@mail.com', '05441239876', NOW()),
('Zeynep', 'Çelik', 'zeynep.celik@mail.com', '05321234567', NOW());


INSERT INTO odunc (user_id, book_id, loan_date, due_date, return_date) VALUES
(1, 1, CURDATE(), CURDATE() + INTERVAL 14 DAY, NULL),
(2, 3, CURDATE() - INTERVAL 5 DAY, CURDATE() + INTERVAL 9 DAY, NULL),
(3, 4, CURDATE() - INTERVAL 20 DAY, CURDATE() - INTERVAL 6 DAY, CURDATE() - INTERVAL 3 DAY),
(4, 2, CURDATE(), CURDATE() + INTERVAL 14 DAY, NULL);


INSERT INTO log (user_id, action_type, action_detail, log_date) VALUES
(1, 'LOGIN', 'Kullanıcı sisteme giriş yaptı', NOW()),
(1, 'BORROW', 'Kürk Mantolu Madonna ödünç alındı', NOW()),
(2, 'BORROW', '1984 kitabı ödünç alındı', NOW()),
(3, 'RETURN', 'Suç ve Ceza kitabı iade edildi', NOW()),
(4, 'REGISTER', 'Yeni kullanıcı kaydı oluşturuldu', NOW());



SELECT book_title, stock
FROM kitaplar
ORDER BY stock DESC;


SELECT kategori_id, COUNT(*) AS kitap_sayisi
FROM kitaplar
GROUP BY kategori_id;


SELECT book_title
FROM kitaplar
WHERE book_title LIKE '% ve %'
   OR book_title LIKE '% ile %';
   
   SELECT book_title
FROM kitaplar
WHERE book_title LIKE 'Harry Potter%';
   
   
SELECT ad AS isim, 'KULLANICI' AS tur
FROM kullanici
UNION
SELECT author_name, 'YAZAR'
FROM yazarlar;



SELECT book_title
FROM kitaplar
WHERE book_id = (
    SELECT book_id
    FROM odunc
    GROUP BY book_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);


WITH OduncAlanKitaplar AS (
    SELECT DISTINCT book_id
    FROM odunc
)
SELECT k.book_title
FROM kitaplar k
WHERE NOT EXISTS (
    SELECT 1
    FROM OduncAlanKitaplar o
    WHERE o.book_id = k.book_id
);


SELECT book_title,
       stock,
       CASE
           WHEN stock = 0 THEN 'TUKENDI'
           WHEN stock BETWEEN 1 AND 2 THEN 'KRITIK'
           ELSE 'YETERLI'
       END AS stok_durumu
FROM kitaplar;


SELECT y.author_name, AVG(k.publish_year) AS ort_yil
FROM yazarlar y
JOIN kitaplar k ON y.author_id = k.author_id
GROUP BY y.author_id
HAVING AVG(k.publish_year) > 1950;


SELECT k.book_title, k.stock
FROM kitaplar k
WHERE EXISTS (
    SELECT 1
    FROM kitaplar k2
    WHERE k2.kategori_id = k.kategori_id
    GROUP BY k2.kategori_id
    HAVING AVG(k2.stock) > k.stock
);







DELIMITER //

CREATE PROCEDURE borrow_book(
    IN p_user_id INT,
    IN p_book_id INT
)
BEGIN
    DECLARE v_stock INT;

    -- Kitabın stok durumunu kontrol et
    SELECT stock INTO v_stock FROM kitaplar WHERE book_id = p_book_id;

    IF v_stock > 0 THEN
        -- Ödünç verme kaydı oluştur
        INSERT INTO odunc(user_id, book_id, loan_date, due_date, return_date)
        VALUES (p_user_id, p_book_id, CURDATE(), CURDATE() + INTERVAL 14 DAY, NULL);

        -- Kitap stokunu azalt
        UPDATE kitaplar SET stock = stock - 1 WHERE book_id = p_book_id;

        -- Log kaydı oluştur
        INSERT INTO log(user_id, action_type, action_detail, log_date)
        VALUES (p_user_id, 'BORROW', CONCAT('Kitap ID ', p_book_id, ' ödünç alındı'), NOW());
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stokta yeterli kitap yok!';
    END IF;
END;
//

DELIMITER ;

CALL borrow_book(1, 3);






DELIMITER //

CREATE PROCEDURE return_book(
    IN p_user_id INT,
    IN p_book_id INT
)
BEGIN
    -- Ödünç kaydını güncelle (return_date)
    UPDATE odunc
    SET return_date = CURDATE()
    WHERE user_id = p_user_id AND book_id = p_book_id AND return_date IS NULL;

    -- Kitap stokunu artır
    UPDATE kitaplar SET stock = stock + 1 WHERE book_id = p_book_id;

    -- Log kaydı oluştur
    INSERT INTO log(user_id, action_type, action_detail, log_date)
    VALUES (p_user_id, 'RETURN', CONCAT('Kitap ID ', p_book_id, ' iade edildi'), NOW());
END;
//

DELIMITER ;


CALL return_book(3, 4);



DELIMITER //

CREATE PROCEDURE add_user(
    IN p_ad VARCHAR(50),
    IN p_soyad VARCHAR(50),
    IN p_email VARCHAR(50),
    IN p_telefon VARCHAR(50)
)
BEGIN
    -- Kullanıcı ekleme
    INSERT INTO kullanici(ad, soyad, email, telefon, kayit_tarihi)
    VALUES (p_ad, p_soyad, p_email, p_telefon, NOW());

    -- Log kaydı
    INSERT INTO log(user_id, action_type, action_detail, log_date)
    VALUES (LAST_INSERT_ID(), 'REGISTER', CONCAT('Kullanıcı ', p_ad, ' ', p_soyad, ' eklendi'), NOW());
END;
//

DELIMITER ;


CALL add_user('Fatma', 'Öztürk', 'fatma.ozturk@mail.com', '05550001122');


CREATE VIEW vw_odunc_kitaplar AS
SELECT 
    o.odunc_id,
    k.book_title,
    u.ad AS kullanici_ad,
    u.soyad AS kullanici_soyad,
    o.loan_date,
    o.due_date,
    o.return_date
FROM odunc o
JOIN kitaplar k ON o.book_id = k.book_id
JOIN kullanici u ON o.user_id = u.user_id;

SELECT * FROM vw_odunc_kitaplar;



CREATE VIEW vw_kitap_yazar AS
SELECT 
    k.book_id,
    k.book_title,
    k.stock,
    y.author_name,
    c.kategori_adi
FROM kitaplar k
JOIN yazarlar y ON k.author_id = y.author_id
JOIN kategori c ON k.kategori_id = c.kategori_id;

SELECT * FROM vw_kitap_yazar;



CREATE VIEW vw_kullanici_odunc_sayisi AS
SELECT 
    u.user_id,
    u.ad,
    u.soyad,
    COUNT(o.odunc_id) AS odunc_sayisi
FROM kullanici u
LEFT JOIN odunc o ON u.user_id = o.user_id
GROUP BY u.user_id, u.ad, u.soyad;

SELECT * FROM vw_kullanici_odunc_sayisi;










BEGIN;

INSERT INTO kullanici(ad, soyad, email, telefon, kayit_tarihi)
VALUES ('Deniz', 'Arslan', 'deniz.arslan@mail.com', '05553334455', NOW());

INSERT INTO log(user_id, action_type, action_detail, log_date)
VALUES (LAST_INSERT_ID(), 'REGISTER', 'Yeni kullanıcı eklendi', NOW());

COMMIT;

select * FROM kullanici;




START TRANSACTION;

DELETE FROM kitaplar WHERE book_id = 5;

INSERT INTO log(user_id, action_type, action_detail, log_date)
VALUES (1, 'DELETE', 'Harry Potter kitabı silindi', NOW());

COMMIT;

select * from kitaplar;




BEGIN;

INSERT INTO odunc(user_id, book_id, loan_date, due_date, return_date)
VALUES (1, 2, CURDATE(), CURDATE() + INTERVAL 14 DAY, NULL);

UPDATE kitaplar
SET stock = stock - 1
WHERE book_id = 2;

-- İşlem iptal ediliyor
ROLLBACK;

select * from odunc;




BEGIN;

INSERT INTO odunc(user_id, book_id, loan_date, due_date, return_date)
VALUES (1, 3, CURDATE(), CURDATE() + INTERVAL 14 DAY, NULL);

UPDATE kitaplar
SET stock = stock - 1
WHERE book_id = 3;

INSERT INTO log(user_id, action_type, action_detail, log_date)
VALUES (1, 'BORROW', '1984 kitabı ödünç alındı', NOW());

COMMIT;
select * from odunc;











DELIMITER //

CREATE TRIGGER trg_kitap_insert
AFTER INSERT ON kitaplar
FOR EACH ROW
BEGIN
    INSERT INTO log(action_type, action_detail, log_date)
    VALUES (
        'INSERT',
        CONCAT('Yeni kitap eklendi: ', NEW.book_title),
        NOW()
    );
END;
//

DELIMITER ;



DELIMITER //

CREATE TRIGGER trg_kitap_update
AFTER UPDATE ON kitaplar
FOR EACH ROW
BEGIN
    INSERT INTO log(action_type, action_detail, log_date)
    VALUES (
        'UPDATE',
        CONCAT(
            'Kitap güncellendi: ',
            OLD.book_title,
            ' | Eski stok: ', OLD.stock,
            ' → Yeni stok: ', NEW.stock
        ),
        NOW()
    );
END;
//

DELIMITER ;




DELIMITER //

CREATE TRIGGER trg_kitap_delete
AFTER DELETE ON kitaplar
FOR EACH ROW
BEGIN
    INSERT INTO log(action_type, action_detail, log_date)
    VALUES (
        'DELETE',
        CONCAT('Kitap silindi: ', OLD.book_title),
        NOW()
    );
END;
//

DELIMITER ;



INSERT INTO kitaplar(book_title, isbn, publish_year, stock, author_id, kategori_id)
VALUES ('Deneme Kitabı', '111222333', 2024, 3, 1, 1);


UPDATE kitaplar
SET stock = 10
WHERE book_title = 'Deneme Kitabı';


DELETE FROM kitaplar
WHERE book_title = 'Deneme Kitabı';


SELECT * FROM log;


