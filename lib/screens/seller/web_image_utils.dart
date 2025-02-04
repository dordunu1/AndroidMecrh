// Stub file for non-web platforms
class Url {
  static String createObjectUrl(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class Blob {
  Blob(List<dynamic> contents);
} 