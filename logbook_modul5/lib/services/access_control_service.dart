class AccessControlService {
  // Daftar aksi yang ada di aplikasi
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan dasar
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
  };

  // Fungsi Gatekeeper utama
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    if (action == actionUpdate || action == actionDelete) {
      return isOwner;
    }
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }
}