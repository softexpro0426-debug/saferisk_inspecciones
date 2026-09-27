enum UserType {
  inspector,
  broker,
  unknown;

  static UserType fromApi(String value) {
    return switch (value.trim().toUpperCase()) {
      'I' => UserType.inspector,
      'B' => UserType.broker,
      _ => UserType.unknown,
    };
  }
}
