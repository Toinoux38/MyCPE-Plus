# Audit MyCPE+ — octobre 2026

## ✅ Corrigé

### Planning (réécriture de la couche données + logique des vues)
- **Décalage d'un jour au changement d'heure** (« semaine de dimanche à jeudi ») : les jours étaient calculés en ajoutant des tranches de 24 h (`Duration(days: n)`). Tout passe maintenant par `DateUtils.addDays` (jours calendaires).
- **Cours du vendredi / du dernier jour du mois absents du cache** : le filtre s'arrêtait à `vendredi 00:00`.
- **Mois ≠ semaine ≠ jour** : chaque vue avait ses propres données. Une seule source de vérité (`PlanningService`, données par jour) pour les trois vues.
- **Cache qui efface des mois / garde des cours annulés** : le préchargement remplaçait tout le cache, et la fusion par id ne supprimait jamais rien. Une réponse API remplace désormais exactement les jours qu'elle couvre.
- **« Pas de cours » affiché pour des jours jamais chargés**, puis les cours apparaissaient : le cache sait maintenant quels jours ont été synchronisés (chargement affiché uniquement pour ceux-là).
- **Réponses dans le désordre** : en changeant vite de semaine, la réponse de l'ancienne semaine s'affichait dans la nouvelle. Les réponses sont appliquées par date, plus par « semaine courante ».
- **Clignotements** : plus de remise en « chargement » à chaque rafraîchissement ; l'UI n'est notifiée que si les données ont changé ; l'indicateur de synchro est dans le pied de carte (hauteur fixe, plus de saut de mise en page).
- **Rafraîchissement au retour dans l'app** si les données ont plus de 15 min.
- Requêtes identiques simultanées mutualisées, cache lu une seule fois (au lieu de déchiffrer tout le JSON à chaque navigation), écriture différée.
- **Cours du samedi/dimanche** : visibles et cliquables (jour, semaine, mois) quand il y en a.
- Noms de jours/mois en français (ils étaient en anglais en dur : « Monday », « Jan 28 »), « il y a X min », « En cours ».
- Le week-end, l'app s'ouvre sur le lundi suivant.

### Autres
- **Déconnexion** : le planning/les notes/les absences de l'ancien compte restaient affichés au compte suivant. Ils sont maintenant vidés.
- **Déconnexion** : effaçait aussi la langue et le thème choisis (`deleteAll`).
- Dates des absences en français.
- `strings` typé `AppStrings` (était `dynamic` dans 28 widgets : une faute de frappe = crash à l'exécution).
- Code mort supprimé : `buttons.dart`, `text_field.dart`, `grades_card.dart`, `planning_card.dart`, `validators.dart` (~900 lignes jamais importées).
- Flèches de navigation semaine/mois assorties (chevron gauche + flèche pleine à droite).
- Tests : `test/planning_service_test.dart` (changement d'heure, cache, annulations, requêtes concurrentes, déconnexion). L'ancien `widget_test.dart` testait un texte anglais qui n'existe plus.

### Lot 2
- **Widget d'écran d'accueil** : l'app pousse les 3 prochaines semaines de cours (heures exactes) ; le widget choisit lui-même le jour (aujourd'hui tant qu'il reste un cours, sinon le prochain jour avec cours) et le prochain cours, à chaque rafraîchissement (30 min). Libellés dans la langue de l'app ; vidé à la déconnexion.
- **Poppins embarquée** (`assets/fonts`, licence OFL) et définie une fois dans le thème : plus de téléchargement au lancement, plus de changement de police hors ligne, et les boîtes de dialogue/snackbars sont aussi en Poppins. Dépendance `google_fonts` retirée.
- **Couleurs clair/sombre** : 109 `isDark ? AppColors.xDark : AppColors.x` et 52 `isDark` remplacés par l'extension `context.textPrimaryColor` etc.
- **Notes et absences en cache** : dernières données affichées immédiatement et hors ligne ; le rafraîchissement ne remplace plus la liste par un spinner ; pied « Mis à jour / Hors ligne » commun aux 3 onglets ; cache vidé à la déconnexion (y compris si une requête était en cours).
- **Splash** : splash natif aux couleurs de l'app en clair et en sombre (Android 12+ compris), écran de démarrage Flutter qui suit le thème, plus d'écran blanc pendant la lecture des réglages.
- **Barres système** : couleur des icônes calculée depuis le thème affiché, suit un changement clair/sombre du système app ouverte.

## 🔜 Reste à faire (par priorité)

### Important
1. **Moyennes de notes probablement fausses** : la moyenne d'un cours est la moyenne simple des épreuves (sans coefficients) alors que l'API fournit `inscription_cours.moyenne`, et la moyenne générale est une moyenne simple des cours (sans pondération par crédits ECTS). À vérifier avec un vrai relevé avant de changer.
2. **Signature release** : `build.gradle.kts` signe le release avec la clé debug ; `key.properties` n'est pas branché.
3. ~~**Widget d'écran d'accueil figé** : il ne calcule « aujourd'hui » et « prochain cours » qu'à l'ouverture de l'app. Le lendemain matin il affiche les cours de la veille tant que l'app n'a pas été ouverte. Il faudrait pousser plusieurs jours et choisir le jour/le cours côté Kotlin.~~ ✅
4. **Messages d'erreur API en anglais en dur** (« No internet connection », « Invalid credentials »…) affichés tels quels.

### Qualité / perf
5. ~~**Police Poppins téléchargée au lancement** (`google_fonts`) : sans réseau au premier lancement → police système puis changement de police. L'embarquer dans `assets/fonts` et la définir une fois dans le thème (90 appels `GoogleFonts.poppins(...)` à remplacer par le `textTheme`).~~ ✅
6. ~~**`isDark ? AppColors.x : AppColors.y` répété des centaines de fois** : `core/theme/theme_extensions.dart` existe déjà pour ça (`context.textPrimaryColor`…) mais n'est pas utilisé. Idéalement passer par `Theme.of(context).colorScheme`.~~ ✅
7. ~~**Notes et absences sans cache** : hors ligne, écran d'erreur au lieu des dernières données connues.~~ ✅
8. **~880 Ko d'images inutiles dans l'APK** : `assets/images/ic_launcher_background.png` et `ic_launcher_foreground.png` sont embarqués (tout le dossier est déclaré) mais pas utilisés à l'exécution.
9. ~~**Splash screen** toujours sur fond clair, même en thème sombre.~~ ✅
10. ~~**Thème « système »** : la couleur des barres système est calculée une fois et ne suit pas un changement clair/sombre pendant que l'app est ouverte.~~ ✅
11. Libellés anglais en dur dans les réglages (« School », « Developers », « Year »).
12. `AuthService.login` : `result.when(success: (x) async {...})` mélange Future et valeur ; à réécrire en `switch`.

### Ménage
13. **`app_build/`** : vieille copie de `lib/` versionnée dans git, désynchronisée, inutilisée (génère 22 avertissements d'analyse). À supprimer.
14. `README.md` obsolète (Flutter 3.10.7, mauvais nom de dépôt).
15. Dossier vide `lib/data/background/`.
16. Plateformes non ciblées (`ios/`, `web/`, `linux/`, `macos/`, `windows/`) : peuvent être supprimées si seul Android compte.

### Notes
- Le widget ne se met à jour depuis l'API que quand l'app est ouverte (il garde 3 semaines d'avance). Une synchro en arrière-plan (WorkManager) serait l'étape suivante si besoin.
