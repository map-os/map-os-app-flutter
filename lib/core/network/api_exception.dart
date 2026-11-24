class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.codigo,
    this.erros = const {},
    this.isNetwork = false,
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final String? codigo;
  final Map<String, String> erros;
  final bool isNetwork;
  final int? retryAfter;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422 && erros.isNotEmpty;

  String? erroDo(String campo) {
    if (erros.containsKey(campo)) return erros[campo];
    for (final entry in erros.entries) {
      if (entry.key.endsWith('.$campo')) return entry.value;
    }
    return null;
  }

  String get completa {
    if (erros.isEmpty) return message;
    return '$message\n${erros.values.map((e) => '• $e').join('\n')}';
  }

  @override
  String toString() => message;
}

String friendlyError(Object error) {
  if (error is ApiException) return error.isValidation ? error.completa : error.message;
  return 'Algo deu errado. Tente novamente.';
}
