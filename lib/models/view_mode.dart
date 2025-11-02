/// Mode d'affichage pour la vue des événements
enum ViewMode {
  list,     // Vue liste/flux
  calendar, // Vue calendrier
}

extension ViewModeExtension on ViewMode {
  String get displayName {
    switch (this) {
      case ViewMode.list:
        return 'Liste';
      case ViewMode.calendar:
        return 'Calendrier';
    }
  }

  String get icon {
    switch (this) {
      case ViewMode.list:
        return 'list';
      case ViewMode.calendar:
        return 'calendar_month';
    }
  }
}