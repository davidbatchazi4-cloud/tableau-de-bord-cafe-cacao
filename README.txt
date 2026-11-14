========================================================================
 TABLEAU DE BORD R SHINY - FILIERE CAFE-CACAO EN COTE D'IVOIRE
 Projet AS2 - Conception de tableaux de bord - ENSEA 2025/2026
 Division DAS
========================================================================

CONTENU DU DOSSIER
------------------
  app.R                                   -> l'application Shiny
  Base_Donnees_AS2_2026_Cafe_Cacao_CI.xlsx -> les donnees (lues par l'app)
  www/                                    -> logos (ENSEA, DAS)
  Lancer_Dashboard.bat                    -> lancement rapide (Windows)
  README.txt                              -> ce fichier

  IMPORTANT : garder tous ces fichiers ensemble, sans changer la
  structure (le dossier www/ doit rester a cote de app.R).


PREREQUIS
---------
  - R (version 4.x) installe
  - Les packages R suivants :
      shiny, shinydashboard, readxl, dplyr, tidyr, plotly, DT, scales

  Pour installer les packages (a faire une seule fois), ouvrir R et
  copier-coller :

    install.packages(c("shiny","shinydashboard","readxl","dplyr",
                       "tidyr","plotly","DT","scales"))


COMMENT LANCER L'APPLICATION
----------------------------
  METHODE 1 (recommandee) - avec RStudio :
    1. Ouvrir le fichier app.R dans RStudio
    2. Cliquer sur le bouton "Run App" (en haut a droite de l'editeur)
    3. Le tableau de bord s'ouvre dans le navigateur

  METHODE 2 - Windows, double-clic :
    Double-cliquer sur "Lancer_Dashboard.bat"
    (laisser la fenetre noire ouverte pendant l'utilisation)

  METHODE 3 - console R :
    setwd("chemin/vers/ce/dossier")
    shiny::runApp("app.R", launch.browser = TRUE)


L'APPLICATION
-------------
  5 onglets : Vue d'ensemble, Production, Exportations, Impact
  socio-economique, Donnees.
  8 indicateurs cles (KPI), 16 graphiques interactifs et 3 filtres
  dynamiques (region, culture, campagne).

  Donnees simulees a des fins pedagogiques - periode 2018-2024.
========================================================================
