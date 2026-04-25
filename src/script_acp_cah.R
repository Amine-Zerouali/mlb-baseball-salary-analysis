##############################################################################
##  PROJET STATISTIQUE - Salaires au baseball                               ##
##  PARTIE 6 : ACP et Classification Ascendante Hiérarchique (CAH)          ##
##############################################################################

library(tidyverse)

data_path <- "baseball.dat.txt"

## ── 1. Chargement des données ─────────────────────────────────────────────

baseball <- read_fwf(
  data_path,
  fwf_positions(
    start     = c( 1,  6, 12, 18, 22, 26, 29, 32, 35, 39, 43, 47, 50, 53, 55, 57, 59, 61),
    end       = c( 4, 10, 16, 20, 24, 27, 30, 33, 37, 41, 45, 48, 51, 53, 55, 57, 59, 79),
    col_names = c(
      "Salary",
      "Batting_average",
      "On_base_percentage",
      "Number_of_runs",
      "Number_of_hits",
      "Number_of_doubles",
      "Number_of_triples",
      "Number_of_home_runs",
      "Number_of_runs_batted_in",
      "Number_of_walks",
      "Number_of_strikeouts",
      "Number_of_stolen_bases",
      "Number_of_errors",
      "Free_agency_elig",
      "Free_agent_91_92",
      "Arbitration_elig",
      "Arbitration_91_92",
      "Player_name"
    )
  )
)

## Nettoyage des noms
baseball$Player_name <- trimws(gsub('"', '', baseball$Player_name))

## Log-transformation du salaire
baseball$LogSalary <- log(baseball$Salary)


## ── 2. Sélection des variables de performance pour l'ACP ──────────────────

donnees_acp <- baseball %>%
  select(
    Batting_average, On_base_percentage, Number_of_runs, Number_of_hits,
    Number_of_doubles, Number_of_triples, Number_of_home_runs,
    Number_of_runs_batted_in, Number_of_walks, Number_of_strikeouts,
    Number_of_stolen_bases, Number_of_errors
  ) %>%
  drop_na()

## On conserve aussi les infos complémentaires sur les mêmes joueurs
baseball_propre <- baseball %>% drop_na()


## ── 3. ACP NON NORMÉE  ────────────────────────────────────────────────────

pc_brut <- prcomp(donnees_acp)

plot(pc_brut,
     main = "ACP non normée | Variance par composante",
     col  = "steelblue")

biplot(pc_brut,
       xlabs = rep("·", nrow(donnees_acp)),
       main  = "ACP non normée | Plan factoriel 1-2")


## ── 4. ACP NORMÉE (retenue pour l'analyse) ────────────────────────────────
## scale. = TRUE : chaque variable est centrée-réduite avant l'ACP.

pcs <- prcomp(donnees_acp, scale. = TRUE)

## ---- Variance expliquée par axe ----
plot(pcs,
     main = "ACP normée | Variance par composante",
     col  = "steelblue")

## Résumé : proportion de variance cumulée
summary(pcs)

## Valeurs propres (on retient les axes avec sdev² > 1 (: règle de Kaiser))
cat("\nValeurs propres (sdev²) :\n")
print(round(pcs$sdev^2, 3))

## Coordonnées des variables sur les axes (loadings)
cat("\nLoadings | coordonnées des variables :\n")
print(round(pcs$rotation[, 1:4], 3))

## ---- Biplots ----
## Plan 1-2
biplot(pcs,
       xlabs = rep("·", nrow(donnees_acp)),
       main  = "ACP normée | Plan factoriel 1-2 (variables et joueurs)")

## Plan 2-3
biplot(pcs,
       choices = c(2, 3),
       xlabs   = rep("·", nrow(donnees_acp)),
       main    = "ACP normée | Plan factoriel 2-3")


## ── 5. CHOIX DU NOMBRE OPTIMAL DE CLUSTERS ────────────────────────────────

## ---- CAH avant ACP ----
d_brut   <- dist(donnees_acp)
cah_brut <- hclust(d_brut)

plot(cah_brut,
     labels = rep("", nrow(donnees_acp)),
     main   = "Dendrogramme | avant ACP",
     xlab   = "", sub = "")

plot(rev(cah_brut$height)[1:20],
     type = "b", pch = 16,
     xlab = "Nombre de clusters (k)",
     ylab = "Hauteur de fusion",
     main = "Critère du coude | CAH avant ACP",
     col  = "steelblue")

## ---- CAH après ACP ----
nb_axes <- 4
d_acp   <- dist(pcs$x[, 1:nb_axes])
cah_acp <- hclust(d_acp)

plot(cah_acp,
     labels = rep("", nrow(donnees_acp)),
     main   = "Dendrogramme | après ACP normée",
     xlab   = "", sub = "")

plot(rev(cah_acp$height)[1:20],
     type = "b", pch = 16,
     xlab = "Nombre de clusters (k)",
     ylab = "Hauteur de fusion",
     main = "Critère du coude | CAH après ACP",
     col  = "steelblue")


## ── 6. CLASSIFICATION EN k GROUPES ────────────────────────────────────────

k_opt <- 3
groupes <- cutree(cah_acp, k = k_opt)
baseball_propre$Cluster <- as.factor(groupes)

## ---- Effectif de chaque cluster ----
cat("\nEffectif de chaque cluster :\n")
print(table(baseball_propre$Cluster))

## ---- Profil moyen de performance par cluster ----
cat("\nMoyennes de performance par cluster :\n")
print(round(aggregate(donnees_acp,
                      by  = list(Cluster = groupes),
                      FUN = mean), 3))

## ---- Log-salaire moyen par cluster ----
cat("\nLog-salaire moyen par cluster :\n")
print(round(aggregate(baseball_propre$LogSalary,
                      by  = list(Cluster = groupes),
                      FUN = mean), 3))

## ---- Statut contractuel par cluster ----
cat("\nProportion d'éligibles free agency par cluster :\n")
print(round(tapply(baseball_propre$Free_agency_elig, groupes, mean), 3))

cat("\nProportion d'éligibles arbitrage par cluster :\n")
print(round(tapply(baseball_propre$Arbitration_elig, groupes, mean), 3))


## ── 7. VISUALISATION DES CLUSTERS SUR LE PLAN FACTORIEL ──────────────────

couleurs <- c("firebrick", "steelblue", "forestgreen", "darkorange")

## Plan 1-2
plot(pcs$x[, 1], pcs$x[, 2],
     col  = couleurs[groupes],
     pch  = 16, cex = 0.8,
     xlab = "Composante principale 1",
     ylab = "Composante principale 2",
     main = paste0("Clusters (k = ", k_opt, ") | Plan factoriel 1-2"))
legend("topright",
       legend = paste("Cluster", 1:k_opt),
       col    = couleurs[1:k_opt],
       pch    = 16, bty = "n")

## Top 20 salaires étiquetés sur le plan factoriel
top20 <- order(baseball_propre$Salary, decreasing = TRUE)[1:20]

plot(pcs$x[, 1], pcs$x[, 2],
     col  = couleurs[groupes],
     pch  = 16, cex = 0.8,
     xlab = "CP1", ylab = "CP2",
     main = "Top 20 salaires identifiés sur le plan factoriel 1-2")
text(pcs$x[top20, 1], pcs$x[top20, 2],
     labels = baseball_propre$Player_name[top20],
     cex = 0.55, pos = 3)
legend("topright",
       legend = paste("Cluster", 1:k_opt),
       col    = couleurs[1:k_opt],
       pch    = 16, bty = "n")