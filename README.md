# ⚾ Analyse des salaires de la MLB (1992)

![SAS](https://img.shields.io/badge/SAS-9.4%20%2F%20Viya-blue)
![R](https://img.shields.io/badge/R-%3E%3D%204.0-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Status](https://img.shields.io/badge/Status-Completed-success)

-----
## Présentation du projet 
Ce projet propose une étude approfondie des déterminants des salaires des joueurs de la Ligue Majeure de Baseball (MLB) en 1992. À l'aide de statistiques de performance de la saison 1991, nous cherchons à quantifier l'impact de la réussite sportive face aux barrières et opportunités contractuelles (agence libre, arbitrage). 

Ce travail a été réalisé dans le cadre de la Licence 3 pour l'UE **"Outils pour la Data Science"** à l'Université Paris Cité.
-----
## Technologies & Méthodologie
Le projet suit une approche rigoureuse inspirée des travaux de **Watnik (1998)** et des manuels de référence de **Neter et al.** et **Christensen**.

### SAS
* **Traitement des données** : Lecture par positions fixes et nettoyage des chaînes de caractères.
* **Transformation Log** : Application de $LogSalary = \ln(Salary)$ pour corriger l'asymétrie forte de la distribution brute et stabiliser la variance.
* **Tests d'hypothèses** : Comparaisons de moyennes via `PROC TTEST` pour mesurer l'avantage financier de la liberté de mouvement.
* **Sélection Stepwise** : Utilisation de `PROC GLMSELECT` (critère SBC) pour identifier les variables prédictives et les interactions entre performance et statut contractuel.

### R
* **ACP Normée** : Réduction de dimension sur les 12 variables de performance. Elle permet de séparer les joueurs selon leur **volume de jeu** (PC1), leur **puissance** et leur **précision** (PC2/PC3).
* **CAH** : Classification Ascendante Hiérarchique sur les composantes principales pour segmenter la population en 3 clusters homogènes.
* **Visualisation** : Cartographie des profils types et identification des "outliers" (joueurs surpayés ou sous-payés par rapport à leurs statistiques).
-----
## Résultats clés (Executive Summary)
1. **Le volume prime sur la qualité** : Le nombre de coups sûrs (*Hits*) est le meilleur prédicteur simple du salaire ($R^2=0.446$), servant de "proxy" pour le temps de jeu effectif.
2. **Prime à la liberté** : À performance égale, un agent libre perçoit un salaire en moyenne 4 fois supérieur à celui d'un joueur sous contrat restreint
3. **L'effet levier de l'arbitrage** : L'interaction montre que c'est lors de l'éligibilité à l'arbitrage que chaque *Hit* supplémentaire rapporte le plus (+0.68% de hausse salariale marginale).
4. **Segmentation** : La CAH isole parfaitement les titulaires réguliers (hauts salaires) des remplaçants et des profils atypiques (haute précision mais faible temps de jeu).
-----
## Structure du dépôt
* **/data** : Contient le jeu de données `baseball.dat.txt` (337 observations) et son dictionnaire.
* **/src** : 
    * `analyse_sas.sas` : Script complet des régressions et tests de normalité.
    * `script_r_acp_cah.R` : Analyse multidimensionnelle et classification.
* **/report** : 
    * `rapport_final.pdf` : Analyse détaillée et interprétations économiques.
    * `rapport_final.tex` : Code source LaTeX du rapport.
    * `/Image` : Graphiques et visualisations générés.
-----
## Utilisation
1. Clonez le dépôt.
2. Pour SAS : Exécutez le script `.sas` en configurant le chemin vers le fichier dans `/data`.
3. Pour R : Ouvrez le projet et lancez le script `.R`. Les chemins sont configurés pour être relatifs au répertoire de travail.
-----
## Auteurs
* **AIT MESSAOUD Mohamed Said**
* **TAKENNE MEKEM Simeon**
* **ZEROUALI Amine**

-----
**Source des données** : Watnik, M. R. (1998). "Pay for Play: Are Baseball Salaries Based on Performance?", *Journal of Statistics Education*.
