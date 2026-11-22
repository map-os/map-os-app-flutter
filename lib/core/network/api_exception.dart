class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  final String message;
  final int? statusCode;
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Converte qualquer erro em uma mensagem amigável.
String friendlyError(Object error) {
  if (error is ApiException) return error.message;
  return 'Algo deu errado. Tente novamente.';
}
