import 'app_locale.dart';
import '../utils/grade_utils.dart';

/// Application strings for localization
abstract class AppStrings {
  // App
  String get appName;

  // Auth
  String get signIn;
  String get signOut;
  String get email;
  String get password;
  String get emailHint;
  String get passwordHint;
  String get usernameHint;
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get passwordTooShort;
  String get invalidCredentials;
  String get signInToAccess;

  // Navigation
  String get planning;
  String get grades;
  String get settings;
  String get absences;

  // Planning
  String get loadingSchedule;
  String get noScheduleAvailable;
  String get noClassesScheduled;
  String get previousWeek;
  String get nextWeek;
  String get tapToGoToCurrentWeek;
  String get breakLabel;
  String coursesCount(int count);
  String get room;
  String get duration;
  String get status;
  String get instructor;
  String get descriptionLabel;
  String get close;
  String get courseDetails;

  // Grades
  String get loadingGrades;
  String get noGradesAvailable;
  String get overallAverage;
  String get courses;
  String get graded;
  String get credits;
  String get avg;
  String get absent;
  String get notGraded;
  String get unnamedExam;
  String gradedCount(int graded, int total);
  String creditsLabel(String credits);

  // Grade labels
  String get excellent;
  String get veryGood;
  String get good;
  String get pass;
  String get needsImprovement;

  // Absences
  String get loadingAbsences;
  String get noAbsencesAvailable;
  String get totalAbsences;
  String get excusedAbsences;
  String get unexcusedAbsences;
  String get totalDuration;
  String get reason;
  String get excused;
  String get notExcused;
  String absencesCount(int count);

  // Settings
  String get language;
  String get selectLanguage;
  String get about;
  String get version;
  String get theme;
  String get selectTheme;
  String get themeLight;
  String get themeDark;
  String get themeSystem;

  // Common
  String get retry;
  String get cancel;
  String get confirm;
  String get refresh;
  String get today;
  String get signOutConfirmTitle;
  String get signOutConfirmMessage;
  String get initializing;
  String get noInternetConnection;
  String get unexpectedError;

  // Sync status
  String get syncing;
  String get offlineMode;
  String get lastUpdated;
  String get mayNotBeUpToDate;

  // Planning view modes
  String get dayView;
  String get weekView;
  String get monthView;

  // Days
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;

  // Short days
  String get mon;
  String get tue;
  String get wed;
  String get thu;
  String get fri;
  String get sat;
  String get sun;

  /// Get grade label strings for localization
  GradeLabelStrings get gradeLabelStrings;

  /// Factory to get strings for a specific locale
  factory AppStrings.of(AppLocale locale) {
    switch (locale) {
      case AppLocale.french:
        return const FrenchStrings();
      case AppLocale.english:
        return const EnglishStrings();
    }
  }
}

/// English strings implementation
class EnglishStrings implements AppStrings {
  const EnglishStrings();

  @override
  String get appName => 'MyCPE+';

  // Auth
  @override
  String get signIn => 'Sign In';
  @override
  String get signOut => 'Sign Out';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get emailHint => 'Enter your email address';
  @override
  String get passwordHint => 'Enter your password';
  @override
  String get usernameHint => 'firstname.lastname';
  @override
  String get emailRequired => 'Email is required';
  @override
  String get emailInvalid => 'Please enter a valid email address';
  @override
  String get passwordRequired => 'Password is required';
  @override
  String get passwordTooShort => 'Password must be at least 4 characters';
  @override
  String get invalidCredentials => 'Invalid credentials';
  @override
  String get signInToAccess => 'Sign in to access your schedule and grades';

  // Navigation
  @override
  String get planning => 'Planning';
  @override
  String get grades => 'Grades';
  @override
  String get settings => 'Settings';
  @override
  String get absences => 'Absences';

  // Planning
  @override
  String get loadingSchedule => 'Loading schedule...';
  @override
  String get noScheduleAvailable => 'No schedule available for this week';
  @override
  String get noClassesScheduled => 'No classes scheduled';
  @override
  String get previousWeek => 'Previous week';
  @override
  String get nextWeek => 'Next week';
  @override
  String get tapToGoToCurrentWeek => 'Tap to go to current week';
  @override
  String get breakLabel => 'Break';
  @override
  String coursesCount(int count) => '$count course${count > 1 ? 's' : ''}';
  @override
  String get room => 'Room';
  @override
  String get duration => 'Duration';
  @override
  String get status => 'Status';
  @override
  String get instructor => 'Instructor';
  @override
  String get descriptionLabel => 'Description';
  @override
  String get close => 'Close';
  @override
  String get courseDetails => 'Course Details';

  // Grades
  @override
  String get loadingGrades => 'Loading grades...';
  @override
  String get noGradesAvailable => 'No grades available yet';
  @override
  String get overallAverage => 'Overall Average';
  @override
  String get courses => 'Courses';
  @override
  String get graded => 'Graded';
  @override
  String get credits => 'credits';
  @override
  String get avg => 'avg';
  @override
  String get absent => 'ABS';
  @override
  String get notGraded => 'N/A';
  @override
  String get unnamedExam => 'Unnamed Exam';
  @override
  String gradedCount(int graded, int total) => '$graded/$total graded';
  @override
  String creditsLabel(String credits) => '$credits credits';

  // Grade labels
  @override
  String get excellent => 'Excellent';
  @override
  String get veryGood => 'Very Good';
  @override
  String get good => 'Good';
  @override
  String get pass => 'Pass';
  @override
  String get needsImprovement => 'Needs Improvement';

  // Absences
  @override
  String get loadingAbsences => 'Loading absences...';
  @override
  String get noAbsencesAvailable => 'No absences recorded';
  @override
  String get totalAbsences => 'Total Absences';
  @override
  String get excusedAbsences => 'Excused';
  @override
  String get unexcusedAbsences => 'Unexcused';
  @override
  String get totalDuration => 'Total Duration';
  @override
  String get reason => 'Reason';
  @override
  String get excused => 'Excused';
  @override
  String get notExcused => 'Not excused';
  @override
  String absencesCount(int count) => '$count absence${count > 1 ? 's' : ''}';

  // Settings
  @override
  String get language => 'Language';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get about => 'About';
  @override
  String get version => 'Version';
  @override
  String get theme => 'Theme';
  @override
  String get selectTheme => 'Select Theme';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System';

  // Common
  @override
  String get retry => 'Retry';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get refresh => 'Refresh';
  @override
  String get today => 'Today';
  @override
  String get signOutConfirmTitle => 'Sign Out';
  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';
  @override
  String get initializing => 'Initializing...';
  @override
  String get noInternetConnection => 'No internet connection';
  @override
  String get unexpectedError => 'An unexpected error occurred';

  // Sync status
  @override
  String get syncing => 'Updating...';
  @override
  String get offlineMode => 'Offline';
  @override
  String get lastUpdated => 'Updated';
  @override
  String get mayNotBeUpToDate => 'May not be up to date';

  // Planning view modes
  @override
  String get dayView => 'Day';
  @override
  String get weekView => 'Week';
  @override
  String get monthView => 'Month';

  // Days
  @override
  String get monday => 'Monday';
  @override
  String get tuesday => 'Tuesday';
  @override
  String get wednesday => 'Wednesday';
  @override
  String get thursday => 'Thursday';
  @override
  String get friday => 'Friday';
  @override
  String get saturday => 'Saturday';
  @override
  String get sunday => 'Sunday';

  // Short days
  @override
  String get mon => 'Mon';
  @override
  String get tue => 'Tue';
  @override
  String get wed => 'Wed';
  @override
  String get thu => 'Thu';
  @override
  String get fri => 'Fri';
  @override
  String get sat => 'Sat';
  @override
  String get sun => 'Sun';

  @override
  GradeLabelStrings get gradeLabelStrings => GradeLabelStrings(
    excellent: excellent,
    veryGood: veryGood,
    good: good,
    pass: pass,
    needsImprovement: needsImprovement,
  );
}

/// French strings implementation
class FrenchStrings implements AppStrings {
  const FrenchStrings();

  @override
  String get appName => 'MyCPE+';

  // Auth
  @override
  String get signIn => 'Se connecter';
  @override
  String get signOut => 'Déconnexion';
  @override
  String get email => 'Email';
  @override
  String get password => 'Mot de passe';
  @override
  String get emailHint => 'Entrez votre adresse email';
  @override
  String get passwordHint => 'Entrez votre mot de passe';
  @override
  String get usernameHint => 'prenom.nom';
  @override
  String get emailRequired => 'L\'email est requis';
  @override
  String get emailInvalid => 'Veuillez entrer une adresse email valide';
  @override
  String get passwordRequired => 'Le mot de passe est requis';
  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 4 caractères';
  @override
  String get invalidCredentials => 'Identifiants invalides';
  @override
  String get signInToAccess =>
      'Connectez-vous pour accéder à votre emploi du temps et vos notes';

  // Navigation
  @override
  String get planning => 'Planning';
  @override
  String get grades => 'Notes';
  @override
  String get settings => 'Paramètres';
  @override
  String get absences => 'Absences';

  // Planning
  @override
  String get loadingSchedule => 'Chargement du planning...';
  @override
  String get noScheduleAvailable => 'Aucun cours prévu cette semaine';
  @override
  String get noClassesScheduled => 'Pas de cours';
  @override
  String get previousWeek => 'Semaine précédente';
  @override
  String get nextWeek => 'Semaine suivante';
  @override
  String get tapToGoToCurrentWeek =>
      'Appuyez pour revenir à la semaine actuelle';
  @override
  String get breakLabel => 'Pause';
  @override
  String coursesCount(int count) => '$count cours';
  @override
  String get room => 'Salle';
  @override
  String get duration => 'Durée';
  @override
  String get status => 'Statut';
  @override
  String get instructor => 'Intervenant';
  @override
  String get descriptionLabel => 'Description';
  @override
  String get close => 'Fermer';
  @override
  String get courseDetails => 'Détails du cours';

  // Grades
  @override
  String get loadingGrades => 'Chargement des notes...';
  @override
  String get noGradesAvailable => 'Aucune note disponible';
  @override
  String get overallAverage => 'Moyenne générale';
  @override
  String get courses => 'Cours';
  @override
  String get graded => 'Notés';
  @override
  String get credits => 'crédits';
  @override
  String get avg => 'moy';
  @override
  String get absent => 'ABS';
  @override
  String get notGraded => 'N/A';
  @override
  String get unnamedExam => 'Examen sans nom';
  @override
  String gradedCount(int graded, int total) => '$graded/$total notés';
  @override
  String creditsLabel(String credits) => '$credits crédits';

  // Grade labels
  @override
  String get excellent => 'Excellent';
  @override
  String get veryGood => 'Très bien';
  @override
  String get good => 'Bien';
  @override
  String get pass => 'Passable';
  @override
  String get needsImprovement => 'Insuffisant';

  // Absences
  @override
  String get loadingAbsences => 'Chargement des absences...';
  @override
  String get noAbsencesAvailable => 'Aucune absence enregistrée';
  @override
  String get totalAbsences => 'Total des absences';
  @override
  String get excusedAbsences => 'Justifiées';
  @override
  String get unexcusedAbsences => 'Non justifiées';
  @override
  String get totalDuration => 'Durée totale';
  @override
  String get reason => 'Motif';
  @override
  String get excused => 'Justifiée';
  @override
  String get notExcused => 'Non justifiée';
  @override
  String absencesCount(int count) => '$count absence${count > 1 ? 's' : ''}';

  // Settings
  @override
  String get language => 'Langue';
  @override
  String get selectLanguage => 'Choisir la langue';
  @override
  String get about => 'À propos';
  @override
  String get version => 'Version';
  @override
  String get theme => 'Thème';
  @override
  String get selectTheme => 'Choisir le thème';
  @override
  String get themeLight => 'Clair';
  @override
  String get themeDark => 'Sombre';
  @override
  String get themeSystem => 'Système';

  // Common
  @override
  String get retry => 'Réessayer';
  @override
  String get cancel => 'Annuler';
  @override
  String get confirm => 'Confirmer';
  @override
  String get refresh => 'Actualiser';
  @override
  String get today => 'Aujourd\'hui';
  @override
  String get signOutConfirmTitle => 'Déconnexion';
  @override
  String get signOutConfirmMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';
  @override
  String get initializing => 'Initialisation...';
  @override
  String get noInternetConnection => 'Pas de connexion internet';
  @override
  String get unexpectedError => 'Une erreur inattendue s\'est produite';

  // Sync status
  @override
  String get syncing => 'Mise à jour...';
  @override
  String get offlineMode => 'Hors ligne';
  @override
  String get lastUpdated => 'Mis à jour';
  @override
  String get mayNotBeUpToDate => 'Peut ne pas être à jour';

  // Planning view modes
  @override
  String get dayView => 'Jour';
  @override
  String get weekView => 'Semaine';
  @override
  String get monthView => 'Mois';

  // Days
  @override
  String get monday => 'Lundi';
  @override
  String get tuesday => 'Mardi';
  @override
  String get wednesday => 'Mercredi';
  @override
  String get thursday => 'Jeudi';
  @override
  String get friday => 'Vendredi';
  @override
  String get saturday => 'Samedi';
  @override
  String get sunday => 'Dimanche';

  // Short days
  @override
  String get mon => 'Lun';
  @override
  String get tue => 'Mar';
  @override
  String get wed => 'Mer';
  @override
  String get thu => 'Jeu';
  @override
  String get fri => 'Ven';
  @override
  String get sat => 'Sam';
  @override
  String get sun => 'Dim';

  @override
  GradeLabelStrings get gradeLabelStrings => GradeLabelStrings(
    excellent: excellent,
    veryGood: veryGood,
    good: good,
    pass: pass,
    needsImprovement: needsImprovement,
  );
}
