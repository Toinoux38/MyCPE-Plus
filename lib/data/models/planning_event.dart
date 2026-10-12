import '../../core/utils/date_utils.dart' as date_utils;

/// Planning intervention model
class PlanningEvent {
  final int? id;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? duree;
  final String? matiere;
  final String? typeActivite;
  final String? statutIntervention;
  final String? intervenants;
  final String? salle;
  final bool isBreak;
  final bool isEmpty;
  final String? description;
  final String? favoriMatiere;

  const PlanningEvent({
    this.id,
    this.dateDebut,
    this.dateFin,
    this.duree,
    this.matiere,
    this.typeActivite,
    this.statutIntervention,
    this.intervenants,
    this.salle,
    this.isBreak = false,
    this.isEmpty = false,
    this.description,
    this.favoriMatiere,
  });

  factory PlanningEvent.fromJson(Map<String, dynamic> json) {
    return PlanningEvent(
      id: json['id'] as int?,
      dateDebut: date_utils.DateUtils.parseApiDate(
        json['date_debut'] as String?,
      ),
      dateFin: date_utils.DateUtils.parseApiDate(json['date_fin'] as String?),
      duree: json['duree'] as String?,
      matiere: json['matiere'] as String?,
      typeActivite: json['type_activite'] as String?,
      statutIntervention: json['statut_intervention'] as String?,
      intervenants: json['intervenants'] as String?,
      salle: json['ressource'] as String? ?? json['salle'] as String?,
      isBreak: json['is_break'] as bool? ?? false,
      isEmpty: json['is_empty'] as bool? ?? false,
      description: json['description'] as String?,
      favoriMatiere: (json['favori'] as Map<String, dynamic>?)?['f3'] as String?
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'duree': duree,
      'matiere': matiere,
      'type_activite': typeActivite,
      'statut_intervention': statutIntervention,
      'intervenants': intervenants,
      'ressource': salle,
      'is_break': isBreak,
      'is_empty': isEmpty,
      'description': description,
      'favori_matiere': favoriMatiere,
    };
  }

  /// Everything the UI shows about this event, to detect real changes.
  String get contentKey => [
    id,
    dateDebut?.toIso8601String(),
    dateFin?.toIso8601String(),
    matiere,
    typeActivite,
    statutIntervention,
    intervenants,
    salle,
    isBreak,
    isEmpty,
    description,
  ].join('|');

  /// Get formatted start time only
  String get startTime {
    if (dateDebut == null) return '';
    return date_utils.DateUtils.formatTime(dateDebut!);
  }

  /// Get formatted end time only
  String get endTime {
    if (dateFin == null) return '';
    return date_utils.DateUtils.formatTime(dateFin!);
  }

  /// Get formatted time range
  String get timeRange {
    if (dateDebut == null || dateFin == null) return '';
    return '${date_utils.DateUtils.formatTime(dateDebut!)} - ${date_utils.DateUtils.formatTime(dateFin!)}';
  }

  /// Get display title
  String get displayTitle {
    if (isBreak) return 'Break';
    return favoriMatiere ?? matiere ?? 'Untitled';
  }

  /// Check if event is a valid course (not break or empty)
  bool get isValidCourse => !isBreak && !isEmpty && matiere != null;

  /// Check if event is currently ongoing
  bool get isOngoing {
    if (dateDebut == null || dateFin == null) return false;
    final now = DateTime.now();
    return now.isAfter(dateDebut!) && now.isBefore(dateFin!);
  }

  /// Check if event is in the past
  bool get isPast {
    if (dateFin == null) return false;
    return DateTime.now().isAfter(dateFin!);
  }

  /// Check if event is in the future
  bool get isFuture {
    if (dateDebut == null) return false;
    return DateTime.now().isBefore(dateDebut!);
  }
}

/// Group planning events by day
class DayPlanning {
  final DateTime date;
  final List<PlanningEvent> events;

  const DayPlanning({required this.date, required this.events});

  /// Get only valid courses (excluding breaks)
  List<PlanningEvent> get courses =>
      events.where((e) => e.isValidCourse).toList();

  /// Check if day has any courses
  bool get hasCourses => courses.isNotEmpty;
}
