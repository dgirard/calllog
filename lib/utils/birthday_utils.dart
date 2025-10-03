import 'constants.dart';

/// Utilitaires pour la gestion des anniversaires

/// Calcule le prochain anniversaire à partir d'une date d'anniversaire
DateTime? getNextBirthday(DateTime? birthday) {
  if (birthday == null) return null;

  final now = DateTime.now();
  final thisYearBirthday = DateTime(now.year, birthday.month, birthday.day);

  // Si l'anniversaire de cette année est passé, retourner celui de l'année prochaine
  if (thisYearBirthday.isBefore(now) || isSameDayAsBirthday(now, birthday)) {
    if (isSameDayAsBirthday(now, birthday)) {
      return thisYearBirthday;
    }
    return DateTime(now.year + 1, birthday.month, birthday.day);
  }

  return thisYearBirthday;
}

/// Calcule le nombre de jours avant le prochain anniversaire
int? daysUntilBirthday(DateTime? birthday) {
  if (birthday == null) return null;

  final nextBirthday = getNextBirthday(birthday);
  if (nextBirthday == null) return null;

  final now = DateTime.now();
  final difference = nextBirthday.difference(DateTime(now.year, now.month, now.day));

  return difference.inDays;
}

/// Vérifie si c'est l'anniversaire aujourd'hui
bool isBirthdayToday(DateTime? birthday) {
  if (birthday == null) return false;

  final now = DateTime.now();
  return isSameDayAsBirthday(now, birthday);
}

/// Vérifie si l'anniversaire est dans les prochains jours (threshold défini dans constants)
bool isBirthdaySoon(DateTime? birthday) {
  if (birthday == null) return false;

  final daysUntil = daysUntilBirthday(birthday);
  if (daysUntil == null) return false;

  return daysUntil >= 0 && daysUntil <= birthdayThresholdDays;
}

/// Vérifie si deux dates correspondent au même jour/mois (anniversaire)
bool isSameDayAsBirthday(DateTime date, DateTime birthday) {
  return date.month == birthday.month && date.day == birthday.day;
}

/// Calcule l'âge à partir d'une date de naissance
int? calculateAge(DateTime? birthday) {
  if (birthday == null) return null;

  final now = DateTime.now();
  int age = now.year - birthday.year;

  // Ajuster si l'anniversaire n'est pas encore passé cette année
  if (now.month < birthday.month ||
      (now.month == birthday.month && now.day < birthday.day)) {
    age--;
  }

  return age >= 0 ? age : null;
}

/// Formate un message d'anniversaire avec le prénom
String formatBirthdayMessage(String firstName, {String? customTemplate}) {
  final template = customTemplate ?? defaultBirthdaySmsTemplate;
  return template.replaceAll('{name}', firstName);
}

/// Retourne un texte pour afficher le compte à rebours avant l'anniversaire
String getBirthdayCountdownText(DateTime? birthday) {
  if (birthday == null) return '';

  if (isBirthdayToday(birthday)) {
    return 'Aujourd\'hui ! 🎂';
  }

  final daysUntil = daysUntilBirthday(birthday);
  if (daysUntil == null) return '';

  if (daysUntil == 1) {
    return 'Demain';
  } else if (daysUntil <= birthdayThresholdDays) {
    return 'Dans $daysUntil jours';
  }

  return '';
}
