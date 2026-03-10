# Refleksi & Lesson Learnt
## Konsep Baru:
Dalam pemisahan logika hak akses itu memakai RBAC (Role-Bassed Acces Control) antara 'Ketua' dan 'Anggota' bisa langsung memanipulasi antarmuka seperti menyembunyikan tombol edit/hapus dan menampilkan ikon lock secara dinamis. selain itu dalam peningkatan tampilan UI saya memakai Lottie untuk menambahkan beberapa animasi.

## Kemenangan Kecil:
Berhasil menangani Bug RenderFlex Overflowed (menabrak batas layar), dengan memakai Wrap agar elemen bisa turun ke baris baru otomatos, beberapa hal lainnya seperti error struktur kode yang sederhana dan peringatan deprecated dengan mengganti opacity dengan alpha sesuai dengan standar Flutter

## Target Berikutnya:
Saya penasaran bagaimana jika seluruh system itu disambungkan dengan database/backend sungguhan (misal firebase atau supabase) agar fitur cloud sync benar benar berjalan secara nyata dan real time
