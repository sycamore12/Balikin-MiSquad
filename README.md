# Balikin  

Balikin adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu mahasiswa melaporkan kehilangan barang atau mengumumkan penemuan barang di lingkungan kampus. Aplikasi ini memfasilitasi pengembalian barang secara aman, transparan, dan tercatat.  

---

## ✨ Fitur Unggulan  

Berikut adalah fitur utama yang telah diimplementasikan sesuai dengan SRS:  

### 🔐 Autentikasi & Keamanan  
* **Google Sign-In**: Login cepat menggunakan akun Google (terintegrasi dengan Firebase Auth).  
* **Profile Gate**: Memastikan setiap pengguna melengkapi data identitas (Nama, NIM, Fakultas, Prodi) sebelum bisa membuat laporan.  
* **Verifikasi Identitas**: Menampilkan identitas asli pelapor untuk mencegah penipuan.  

### 📝 Manajemen Laporan (CRUD)  
* **Lapor Kehilangan**: Posting barang yang hilang dengan detail lokasi dan ciri-ciri.  
* **Lapor Penemuan**: Posting barang yang ditemukan agar pemilik asli bisa mencarinya.  
* **Pencarian & Filter**: Mencari barang berdasarkan kata kunci atau status (Hilang/Ketemu).  

### 🤝 Penyelesaian Kasus (Berita Acara)  
* **Verifikasi Pihak Kedua**: Saat barang dikembalikan, pelapor wajib memasukkan *username* penerima/penemu untuk validasi.  
* **Bukti Serah Terima**: Wajib mengunggah foto bukti serah terima barang.  
* **Riwayat Permanen**: Data penyelesaian (Waktu, Pihak 1, Pihak 2, Foto Bukti) tersimpan permanen di menu Riwayat sebagai bukti sah (Berita Acara).  

### 💬 Komunikasi  
* **In-App Chat**: Fitur chat *real-time* antara pemilik dan penemu barang untuk janjian bertemu.  

SRS: https://docs.google.com/document/d/1TwB5AQRbwevBhUoSizZEOdIuJZFfMhZUVlZ_N9dFpdU/edit?usp=sharing

Release APK: https://drive.google.com/drive/folders/1-jvEUZFg9ykb4MirdtbZ_YqVdegomayZ?usp=drive_link
