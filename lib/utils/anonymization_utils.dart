/// Utilitaires pour anonymiser les données sensibles en mode démo

/// Anonymise un nom complet
/// Garde la première lettre du prénom, tout le reste en étoiles
/// Exemples:
///   "Georges Girard" → "G****** ******"
///   "Marie-Claire Dupont" → "M***********- ******"
///   "Jean" → "J***"
String anonymizeName(String fullName) {
  final parts = fullName.trim().split(' ');

  if (parts.isEmpty) return fullName;

  // Anonymiser chaque partie (prénom et nom)
  final anonymizedParts = parts.map((part) {
    if (part.isEmpty) return part;

    // Gérer les prénoms composés avec tiret (Marie-Claire)
    if (part.contains('-')) {
      return part.split('-').map((subPart) {
        if (subPart.isEmpty) return subPart;
        return subPart[0] + ('*' * (subPart.length - 1));
      }).join('-');
    }

    // Garder première lettre + étoiles pour le reste
    return part[0] + ('*' * (part.length - 1));
  }).toList();

  return anonymizedParts.join(' ');
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

/// Anonymise un prénom seul
/// Garde la première lettre, tout le reste en étoiles
/// Utilisé pour les messages d'anniversaire par exemple
String anonymizeFirstName(String firstName) {
  if (firstName.isEmpty) return firstName;

  // Gérer les prénoms composés avec tiret (Marie-Claire)
  if (firstName.contains('-')) {
    return firstName.split('-').map((subPart) {
      if (subPart.isEmpty) return subPart;
      return subPart[0] + ('*' * (subPart.length - 1));
    }).join('-');
  }

  return firstName[0] + ('*' * (firstName.length - 1));
}
