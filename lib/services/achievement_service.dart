class AchievementService {
  // El servicio ahora es solo un stub — los logros vienen del backend
  static const List<String> categories = [
    'lectora',
    'paginas',
    'sagas',
    'generos',
    'resenas',
    'club',
    'clubvision',
    'constancia',
  ];

  static const Map<String, String> categoryLabels = {
    'lectora': '📚 Lector',
    'paginas': '📄 Páginas',
    'sagas': '🌀 Sagas',
    'generos': '🎭 Géneros',
    'resenas': '✍️ Reseñas',
    'club': '💬 Club',
    'clubvision': '🗳️ Clubvisión',
    'constancia': '🔥 Constancia',
  };

  static const Map<String, String> rarityLabels = {
    'common': 'Común',
    'rare': 'Raro',
    'epic': 'Épico',
    'legendary': 'Legendario',
  };

  static const Map<String, String> rarityColors = {
    'common': '#7C7C7C',
    'rare': '#2563EB',
    'epic': '#7C3AED',
    'legendary': '#D97706',
  };
}
