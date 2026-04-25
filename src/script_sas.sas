/*===========================================================================
  PROJET STATISTIQUE - Salaires au baseball
  Données : 337 joueurs MLB, saison 1992
  Variable à expliquer : Salary (en milliers de dollars)

    Partie 1  - Lecture et analyse descriptive globale
    Partie 2  - Analyses univariées
    Partie 3  - Liaisons avec Salary
    Partie 4  - Régressions simples
    Partie 5  - Régression multiple
===========================================================================*/


/*===========================================================================
  CONFIGURATION DU CHEMIN D'ACCÈS
  Remplacez le chemin ci-dessous par le dossier contenant vos données
===========================================================================*/
/* %LET chemin = /home/votre-identifiant/PROJET/Data; */
%LET chemin = .; /* Par défaut, cherche dans le répertoire courant */


/*===========================================================================
  PARTIE 1 - Lecture et analyse descriptive globale
===========================================================================*/
DATA baseball;
  INFILE "&chemin./baseball.dat.txt";
  
  INPUT Salary 1-4
        Batting_avg 6-10
   	 	OBP 12-16
    	Runs 18-20
    	Hits 22-24
    	Doubles 26-27
    	Triples 29-30
    	HR 32-33
    	RBI 35-37
    	Walks 39-41
    	Strike_outs 43-45
    	Stolen_Bases 47-48
    	Errors 50-51
    	Free_agency_elig 53
    	Free_agent_91_92 55
    	Arbitration_elig 57
    	Arbitration_91_92 59
    	Player_name $ 61-79;
    
  Player_name = STRIP(COMPRESS(Player_name, '"'));

  LogSalary = LOG(Salary);
RUN;

PROC CONTENTS DATA=baseball;
  TITLE "Structure du jeu de données baseball";
RUN;

PROC MEANS DATA=baseball NMISS N MEAN MEDIAN STD MIN MAX;
  var Salary LogSalary Batting_avg OBP Runs Hits Doubles Triples
      HR RBI Walks Strike_outs Stolen_Bases Errors;
  TITLE "Valeurs manquantes et statistiques descriptives | variables continues";
RUN;

PROC FREQ DATA=baseball;
  TABLES Free_agency_elig Free_agent_91_92 Arbitration_elig Arbitration_91_92
         Free_agency_elig*Free_agent_91_92
         Arbitration_elig*Arbitration_91_92;
  TITLE "Répartition des variables de statut contractuel";
RUN;




/*===========================================================================
  PARTIE 2 - Analyses univariées
===========================================================================*/
PROC UNIVARIATE DATA=baseball NORMAL;
  VAR Salary LogSalary;
  HISTOGRAM Salary   / NORMAL(MU=EST SIGMA=EST) KERNEL;
  HISTOGRAM LogSalary / NORMAL(MU=EST SIGMA=EST) KERNEL;
  QQPLOT Salary    / NORMAL(MU=EST SIGMA=EST);
  QQPLOT LogSalary / NORMAL(MU=EST SIGMA=EST);
  INSET N MEAN STD SKEWNESS KURTOSIS / POSITION=NE;
  TITLE "Distribution du salaire (brut et log)";
RUN;

PROC UNIVARIATE DATA=baseball NORMAL;
  VAR Batting_avg OBP Runs Hits Doubles Triples HR RBI Walks Strike_outs
      Stolen_Bases Errors;
  HISTOGRAM / NORMAL(MU=EST SIGMA=EST) KERNEL;
  TITLE "Distribution des variables de performance";
RUN;

PROC SORT DATA=baseball OUT=top5salary;
  BY DESCENDING Salary;
RUN;

PROC PRINT DATA=top5salary (OBS=10);
  VAR Player_name Salary Hits HR RBI Free_agency_elig Free_agent_91_92;
  TITLE "Top 10 salaires";
RUN;

PROC SGPLOT DATA=baseball;
  VBOX LogSalary / CATEGORY=Free_agency_elig;
  TITLE "LogSalary selon le statut de free agency";
RUN;

PROC SGPLOT DATA=baseball;
  VBOX LogSalary / CATEGORY=Arbitration_elig;
  TITLE "LogSalary selon le statut d'arbitrage";
RUN;



/*===========================================================================
  PARTIE 3 - Liaisons avec Salary
===========================================================================*/

PROC SGSCATTER DATA=baseball;
  MATRIX LogSalary Hits HR RBI Walks Batting_avg OBP;
  TITLE "Matrice de nuages de points";
RUN;

/* Pour voir le détail de SGS pour chaque
  PROC GPLOT DATA=baseball;
  PLOT LogSalary * Hits;
  TITLE "Lien entre le nombre de Hits et le Log(Salaire)";
RUN;
QUIT;
*/

PROC CORR DATA=baseball;
  VAR LogSalary;
  WITH Batting_avg OBP Runs Hits Doubles Triples HR RBI Walks Strike_outs
       Stolen_Bases Errors Free_agency_elig Free_agent_91_92 Arbitration_elig Arbitration_91_92;
  TITLE "Corrélations avec LogSalary";
RUN;


/*
  Variables bien corrélées : Hits, RBI, HR, Walks, Runs
  Statut contractuel (Free_agency_elig, Arbitration_elig) aussi important
*/

/* Moyennes de LogSalary par statut contractuel */
PROC MEANS DATA=baseball MEAN STD N;
  CLASS Free_agency_elig Free_agent_91_92 Arbitration_elig Arbitration_91_92;
  VAR LogSalary;
  TITLE "Salaire moyen (log) selon le statut contractuel";
RUN;

PROC TTEST DATA=baseball;
  CLASS Free_agency_elig;
  VAR LogSalary;
  TITLE "Test de Student : LogSalary selon Free_agency_elig";
RUN;

PROC TTEST DATA=baseball;
  CLASS Free_agent_91_92;
  VAR LogSalary;
  TITLE "Test de Student : LogSalary selon Free_agent_91_92";
RUN;


/*===========================================================================
  PARTIE 4 - Régressions simples
===========================================================================*/

PROC REG DATA=baseball;
  MODEL LogSalary = Hits;
  MODEL LogSalary = HR;
  MODEL LogSalary = RBI;
  MODEL LogSalary = Batting_avg;
  TITLE "Comparaison des régressions simples";
RUN; QUIT;

PROC REG DATA=baseball;
  MODEL LogSalary = Hits;
  
  /* Résidus pour calculer l'écart entre le salaire réel et le salaire prédit */
  OUTPUT OUT=analyse_outliers p=prevision r=residus; 
  TITLE "Régression simple sur Hits et détection visuelle des outliers";
RUN; QUIT;

/* On trie les joueurs pour trouver ceux qui s'éloignent le plus du modèle */
PROC SORT DATA=analyse_outliers;
  BY DESCENDING residus; /* Chercher ceux qui gagnent plus que prévu */
RUN;

PROC PRINT DATA=analyse_outliers (OBS=10);
  VAR Player_name LogSalary prevision residus Hits;
  TITLE "Top 10 des joueurs surpayés par rapport à leurs Hits";
RUN;



/* ==========================================================================
  PARTIE 5  - Régression multiple
===========================================================================*/

/* Fusion de l'éligibilité à l'agence libre et à l'arbitrage*/
DATA baseball;
    SET baseball;
    IF Free_agency_elig = 0 AND Arbitration_elig = 0 THEN Statut = "0_Aucun";
    IF Arbitration_elig = 1                          THEN Statut = "1_Arbitrage";
    IF Free_agency_elig = 1                          THEN Statut = "2_AgentLibre";
RUN;

/* Approche n°1 : Variables binaires séparées */
PROC GLMSELECT DATA=baseball;
    CLASS Free_agency_elig Free_agent_91_92 
          Arbitration_elig Arbitration_91_92;
    MODEL LogSalary = Hits RBI Walks HR Runs Doubles
          Free_agency_elig Free_agent_91_92 
          Arbitration_elig Arbitration_91_92
          / SELECTION=STEPWISE;
    TITLE "Modèle n°1 : Variables d'éligibilité séparées";
RUN;

/* Approche n°2 : Variable Statut consolidée */
PROC GLMSELECT DATA=baseball;
    CLASS Statut Free_agent_91_92 Arbitration_91_92;
    MODEL LogSalary = Hits RBI Walks HR Runs Doubles
          Statut Free_agent_91_92 Arbitration_91_92
          / SELECTION=STEPWISE;
    TITLE "Modèle n°2 : Variable Statut consolidée";
RUN;

/* Modèle Final : Inclusion des interactions Performance x Statut */
/* On teste si la valeur d'un Hit dépend de la liberté contractuelle */
PROC GLMSELECT DATA=baseball;
    CLASS Statut Free_agent_91_92 Arbitration_91_92;
    MODEL LogSalary = 
          Batting_avg OBP Runs Hits Doubles Triples HR RBI Walks Strike_outs 
          Stolen_Bases Errors 
          Statut Free_agent_91_92 Arbitration_91_92
          Hits*Statut RBI*Statut HR*Statut
          / SELECTION=STEPWISE DETAILS=ALL;
    TITLE "Modèle Final : Sélection Stepwise avec interactions";
RUN;