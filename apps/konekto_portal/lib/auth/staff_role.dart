enum StaffRole {
  gerente,
  recepcao;

  static StaffRole fromString(String value) {
    return StaffRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => throw ArgumentError('Papel de staff desconhecido: "$value"'),
    );
  }

  String get label => switch (this) {
        StaffRole.gerente => 'Gerente',
        StaffRole.recepcao => 'Recepção',
      };
}
