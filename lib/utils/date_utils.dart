import 'package:intl/intl.dart';

/// Utilitaires pour la gestion des dates

/// Formate une date au format dd/MM/yyyy
String formatDate(DateTime? date) {
  if (date == null) return 'Jamais';
  return DateFormat('dd/MM/yyyy').format(date);
}

/// Formate une date avec heure au format dd/MM/yyyy HH:mm
String formatDateTime(DateTime? date) {
  if (date == null) return 'Jamais';
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

/// Calcule le nombre de jours depuis le dernier contact
int? daysSinceLastContact(DateTime? lastContact) {
  if (lastContact == null) return null;
  final now = DateTime.now();
  final difference = now.difference(lastContact);
  return difference.inDays;
}

/// Retourne un texte relatif pour une date (il y a X jours, etc.)
String getRelativeDateText(DateTime? date) {
  if (date == null) return 'Jamais contacté';

  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        return 'À l\'instant';
      }
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
    return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
  } else if (difference.inDays == 1) {
    return 'Hier';
  } else if (difference.inDays < 7) {
    return 'Il y a ${difference.inDays} jours';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return 'Il y a $months mois';
  } else {
    final years = (difference.inDays / 365).floor();
    return 'Il y a $years an${years > 1 ? 's' : ''}';
  }
}

/// Vérifie si deux dates sont le même jour (ignore l'heure)
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

/// Calcule le nombre de jours entre deux dates
int daysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}
