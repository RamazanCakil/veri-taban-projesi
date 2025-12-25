# veri-tabanı-projesi : e-kütüphane veri tabanı
SELECT:

1- hangi kitaptan kaç tane olduğunu getirir.

2- her kategoride kaç kitap olduğunu getirir.

3- kitap başlığında "ve" ya da "ile" olan kitapları getirir.

4- kitap başlığı harry poter ile başlayan kitapları getirir.

5- kullanıcı isimlerini kullanıcı, yazar isimlerini yazar olarak tür kategorisinde gösterir.

6- en çok ödünç alınan kitabı getirir.

7- ödünç alınmayan kitapları getirir.

8- her kitabın stoklarına bakar. stok durumu sütununa; 0 ise tükendi, 1-2 ise kritik,daha fazla ise yeterli yazar.

9- her yazarın kitaplarının ortalama yayın yılını bulur ve bu 1950 den büyük olanları listeler.

10- kendi kategorisindeki kitapların stok ortalamasından daha düşük stokta olan kitapları listeler.


STORED PROCEDURE:
Birden çok kod bloğu bir tek işlem ile yapılır. Bu işlem her zaman değil, gerekli olduğunda çağırılarak yapılır.

1- kitap ödünç verme işlemi için girilen kitap_id ve kullanıcı_id'sine göre kitabın mevcut stok durumunu kontrol eder, eğer sıfırdan büyükse stoktan düşürür ve loglama işlemi yapar.

2-kitabı geri getirme işlemi için girilen kitap_id ve kullanıcı_id'sine göre mevcut kullanıcı ve kitabı bulup kitabın geri veriliş tarihini günceller, stok miktarını 1 arttırır ve loglama işlemi ile kaydeder.

3- yeni kullanıcı kaydı işlemi yapmak için gerekli kullanıcı verileri (isim , soy isim, email, telefon) tanımlanır, insert into ile kullanıcı tablosuna eklenir ve log kaydı oluşturularak yapılan işlem kaydedilir.


VIEW:
Sanal bir tablo oluşturur.

1- ödünç tablosunu halihazırda tanımlı olan foreign keyler ile (user_id,book_id) kullanici ve kitaplar tablolarıyla birleştirir. Böylece ödünç tablosundan; odunc_id,loan_date,due_date,return_date  , kitaplar tablosundan ; book_title   ve kullanici tablosundan da ad, soyad verilerini çekerek bir tablo oluşturur ve bizlere verir. Bu 3 tablonun verileri view ile oluşturulan sanal tablodan hızlıca çekilir.

2- aynı şekilde kitaplar tablosunu kategori ve yazarlar tablolarıyla birleştirir(join). Bu üç tablodan da veriler çekerek bir tablo oluşturup bizlere verir. Bu 3 tablonun verileri view ile oluşturulan sanal tablodan hızlıca çekilir.

3- hangi kullanıcının kaç kitap ödünç aldığı verilmesi için; kullanıcı tablosuyla odunc tablosu left join ile birleştirilir. inner join ile (normal join) birleştirilmemesinin sebebi hiç kitap almamış olan kullanıcıyı da getirmesini istememizdir. Count ile saydık ve group by ile gurupladık (tekrar olmasın diye). Bu tablodaki verilere view ile hızlıca erişebiliriz.


TRANSACTİON:
Birden fazla sql işlemi bir bütün gibi çalıştırılır.

1- kullanıcı tablosuna yeni kayıt eklemek için insert into ... + values() kullanılır. Aynı şekilde log kaydı da oluşturmak için insert into ... + values() ile yapılır. Stored prosedure gibi işlemi yapmak için dışarıdan veri almayı beklemez, ekleyeceği kişi zaten bellidir ve bu işlem bir kere yapılır. Transaction için parametre oluşturulmaz. Eklenecek değer direk insert into ile eklenir. Bunun yanında, stored procedure gibi birden fazla kere kullanılmaz.

2- kitaplar tablosundan kitap_id si 5 olan kitaap silindi. ve log kaydı da yapıldı. Begin ve start transaction arasında bir fark yoktur ikisi de kod bloğunu başlatır.commit ile sonlanır.

3- kitap ödünç vermek için odunc tablosuna veriler eklendi (insert into) , stok miktarı güncellendi ve yapılan işlem log'a kaydedildi.   


TRIGGER:
Örnek olarak kitaplar tablosu için ekleme, güncelleme ve silme işlemlerini otomatik olarak yapacak trigger oluşturalım. Her tablo için ayrı ayrı oluşturulabilir. 

1- create trigger ... ile trigger oluşturduk. after insert on kitaplar ile kitaplar tablosuna ekleme yapıldıktan sonra çalışsın dedik. for each row ile de her bir komut için bir log kaydı yapacak şekilde olsun dedik(yani her bir işlemi kaydedecek). Begin ile yapacağı işlem başlar . insert into log(...) diyerek values(...) ile eklenecek.
log action_type "insert" dedik.

2- Aynı şekilde create trigger ile triger oluşturduk. after update on kitaplar ile kitaplar tablosunda güncelleme yaptıktan sonra çalışsın dedik.for each row ile her işlemin kaydedilmesini söyledik. Begin ile yapacağı işlem başlar. Aynı şekilde insert yerine update bilgisi giriliyor. işlem detaylarına da ' | Eski stok: ', OLD.stock, ve  ' → Yeni stok: ', NEW.stock değerleri girdik (daha açıklayıcı).

3- Delete işlemi de aynı şekilde oluyor sadece update yerine delete bilgisi giriliyor ve action_detailsde de OLD.stock bilgisi gösteriliyor.


