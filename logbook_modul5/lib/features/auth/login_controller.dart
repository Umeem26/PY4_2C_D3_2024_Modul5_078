class LoginController {
  // Database sederhana (Hardcoded untuk latihan)
  final String _validUsername = "admin";
  final String _validPassword = "123";

  // Fungsi Logic-Only: Mengembalikan true jika cocok, false jika salah
  bool login(String username, String password) {
    if (username.isNotEmpty && password == "123") {
      return true;
    }
    return false;
  }
}