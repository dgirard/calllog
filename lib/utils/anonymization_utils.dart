/// Utilitaires pour anonymiser les données sensibles en mode démo

/// Anonymise un nom complet
/// Garde le prénom, remplace le nom par des étoiles
/// Exemples:
///   "Georges Girard" → "Georges ******"
///   "Marie-Claire Dupont" → "Marie-Claire ******"
///   "Jean" → "Jean"
String anonymizeName(String fullName) {
  final parts = fullName.trim().split(' ');

  if (parts.isEmpty) return fullName;
  if (parts.length == 1) return parts[0]; // Que le prénom

  // Garder le prénom (tous les mots avant le dernier)
  final firstName = parts.sublist(0, parts.length - 1).join(' ');
  // Remplacer le nom par des étoiles (longueur du nom)
  final lastName = parts.last;
  final anonymizedLastName = '*' * lastName.length;

  return '$firstName $anonymizedLastName';
}

/// Anonymise un numéro de téléphone
/// Masque les 4 derniers chiffres
/// Exemples:
///   "+33 6 74 53 03 02" → "+33 6 74 53 ** **"
///   "0674530302" → "067453****"
///   "+336 74 53 03 02" → "+336 74 53 ** **"
String anonymizePhoneNumber(String phoneNumber) {
  if (phoneNumber.isEmpty) return phoneNumber;

  // Retirer tous les espaces pour compter les chiffres
  final digitsOnly = phoneNumber.replaceAll(RegExp(r'\s'), '');

  // Trouver les 4 derniers chiffres
  if (digitsOnly.length < 4) return phoneNumber;

  // Construire le numéro anonymisé en gardant le format original
  final result = StringBuffer();
  int digitCount = 0;
  final totalDigits = digitsOnly.replaceAll(RegExp(r'[^\d]'), '').length;
  final digitsToKeep = totalDigits - 4;

  for (int i = 0; i < phoneNumber.length; i++) {
    final char = phoneNumber[i];

    if (RegExp(r'\d').hasMatch(char)) {
      digitCount++;
      if (digitCount <= digitsToKeep) {
        result.write(char);
      } else {
        result.write('*');
      }
    } else {
      result.write(char);
    }
  }

  return result.toString();
}

/// Anonymise un prénom seul (retourne tel quel)
/// Utilisé pour les messages d'anniversaire par exemple
String anonymizeFirstName(String firstName) {
  return firstName; // On garde le prénom tel quel
}
