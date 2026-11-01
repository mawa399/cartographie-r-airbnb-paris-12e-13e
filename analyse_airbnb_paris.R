################################################################################
# Analyse des prix des locations Airbnb dans les 12e et 13e arrondissements
# de Paris (septembre 2024)
#
# Auteur  : Mawa DIAW
# Données : data/bnb.gpkg
#   - arrdts : limites des 12e et 13e arrondissements (BD CARTO®, IGN, 2021)
#   - parc   : espaces verts (© contributeurs OpenStreetMap, 2021)
#   - route  : réseau viaire (© contributeurs OpenStreetMap, 2021)
#   - rail   : réseau ferré (© contributeurs OpenStreetMap, 2021)
#   - airbnb : locations Airbnb hors hôtels, prix < 1 000 € (Inside Airbnb, sept. 2024)
#
# Sorties : figures/*.png
################################################################################


################################################################################
# 0. Préparation
################################################################################

# Bibliothèques nécessaires
library(sf)
library(mapsf)
library(dplyr)
library(classInt)

# Dossier des figures
dir.create("figures", showWarnings = FALSE)

# Paramètres communs aux cartes
FOND    <- "#2E3947"   # couleur de fond (bleu-gris foncé)

# Thème sombre défini une fois pour toutes les cartes
mf_theme(background = FOND, foreground = "#dfdfdf", highlight = "#dfdfdf",
         mar = c(0.5, 0.5, 2, 0.5), title_pos = "left", title_tab = TRUE,
         title_cex = 1.1, title_font = 2)
SOURCES <- paste0("Auteur : Mawa DIAW, ", format(Sys.Date(), "%Y"), "\n",
                  "Sources : BD CARTO®, IGN, 2021 / © contributeurs OpenStreetMap, 2021 / ",
                  "Inside Airbnb, septembre 2024")


################################################################################
# 1. Import des couches
################################################################################

bnb_gpkg <- "data/bnb.gpkg"

arrdts <- st_read(bnb_gpkg, layer = "arrdts", quiet = TRUE)   # arrondissements
parc   <- st_read(bnb_gpkg, layer = "parc",   quiet = TRUE)   # espaces verts
route  <- st_read(bnb_gpkg, layer = "route",  quiet = TRUE)   # réseau viaire
rail   <- st_read(bnb_gpkg, layer = "rail",   quiet = TRUE)   # réseau ferré
airbnb <- st_read(bnb_gpkg, layer = "airbnb", quiet = TRUE)   # locations Airbnb

# Nettoyage des locations et calcul du prix par personne
airbnb <- airbnb %>%
  filter(!is.na(price), price > 0, !is.na(accommodates), accommodates > 0) %>%
  mutate(prix_pers = price / accommodates)


################################################################################
# 2. Fonctions d'habillage (réutilisées sur toutes les cartes)
################################################################################

# Fond de carte : espaces verts, routes, voies ferrées
fond_de_carte <- function() {
  mf_init(arrdts)
  mf_map(parc,  col = "#2E8B57", border = NA, add = TRUE)
  mf_map(route, col = "#53575C", lwd = 0.5,   add = TRUE)
  mf_map(rail,  col = "#6B6B6B", lwd = 1,     add = TRUE)
}

# Contours, étiquettes, titre, échelle, orientation et sources
habillage <- function(titre) {
  mf_map(arrdts, col = NA, border = "#FFFFFF", lwd = 1.5, add = TRUE)
  mf_label(arrdts, var = "NOM", col = "white", halo = TRUE, bg = FOND,
           cex = 0.9, font = 2)
  mf_title(titre, tab = TRUE, fg = "#dfdfdf")
  mf_scale(col = "white")
  mf_arrow(pos = "topleft")
  mf_credits(SOURCES, col = "#f6f6f6", cex = 0.6)
}


################################################################################
# 3. Carte de situation des locations Airbnb
################################################################################

png("figures/01_carte_locations_airbnb.png", width = 800, height = 600,
    res = 100, bg = FOND)

fond_de_carte()
mf_map(airbnb, col = "#FF4C4C", pch = 20, cex = 0.5, add = TRUE)
habillage(paste0(format(nrow(airbnb), big.mark = " "),
                 " locations Airbnb à Paris 12e et 13e (sept. 2024)"))

dev.off()


################################################################################
# 4. Carte des prix des locations (prix de la nuitée)
################################################################################

# Statistiques descriptives
cat("\n--- Prix de la nuitée (€) ---\n")
print(summary(airbnb$price))
cat("Écart-type :", round(sd(airbnb$price), 1), "€\n")
cat("Écart interquartile :", round(IQR(airbnb$price), 1), "€\n")

# Distribution des prix : histogramme + boxplot
png("figures/02_distribution_prix.png", width = 750, height = 600, res = 100)
par(mfrow = c(2, 1))
hist(airbnb$price, breaks = 50, col = "#69b3a2", border = "white",
     main = "Distribution des prix de la nuitée", xlab = "Prix (€)", ylab = "Effectif")
abline(v = median(airbnb$price), col = "#c0392b", lwd = 2, lty = 2)
boxplot(airbnb$price, col = "#ffcc5c", horizontal = TRUE,
        main = "Boîte à moustaches des prix", xlab = "Prix (€)")
dev.off()

# Justification de la discrétisation :
# La distribution est très dissymétrique à droite (voir figures/02_distribution_prix.png) :
# la majorité des prix se concentre sous 200 €, avec une longue traîne jusqu'à 999 €.
# Des classes d'amplitude égale laisseraient presque toutes les locations dans
# une ou deux classes. La méthode des quantiles (6 classes de même effectif)
# fait ressortir les différences au sein du cœur de la distribution.
breaks_prix <- quantile(airbnb$price, probs = seq(0, 1, length.out = 7))
pal_prix    <- hcl.colors(6, "Zissou 1")   # bleu = prix bas, rouge = prix élevés

png("figures/03_carte_prix_nuitee.png", width = 750, height = 600,
    res = 100, bg = FOND)

fond_de_carte()
mf_map(airbnb, var = "price", type = "choro",
       breaks = breaks_prix, pal = pal_prix,
       pch = 20, cex = 0.6, leg_pos = NA,   # légende ajoutée ci-dessous
       add = TRUE)

# Légende en cases colorées (plus lisible que des petits points)
mf_legend(type = "choro", val = breaks_prix, pal = pal_prix,
          title = "Prix de la nuitée (€)\n(quantiles)", val_rnd = 0,
          pos = "topright", frame = TRUE, bg = "#1F2733", fg = "#f0f0f0",
          frame_border = "#dfdfdf")
habillage("Prix de la nuitée des locations Airbnb (sept. 2024)")

dev.off()


################################################################################
# 5. Prix médian par personne autour du MK2 Bibliothèque (600 m)
################################################################################

# Point MK2 Bibliothèque (WGS84) projeté dans le système des données (Lambert-93)
mk2 <- st_sfc(st_point(c(2.3752, 48.8326)), crs = 4326) %>%
  st_transform(st_crs(airbnb))

zone_mk2   <- st_buffer(mk2, dist = 600)
airbnb_mk2 <- airbnb[st_intersects(airbnb, zone_mk2, sparse = FALSE), ]

prix_med_mk2  <- median(airbnb_mk2$prix_pers)
prix_med_zone <- median(airbnb$prix_pers)

cat("\n--- Voisinage du MK2 Bibliothèque (600 m) ---\n")
cat("Locations dans la zone :", nrow(airbnb_mk2), "\n")
cat("Prix médian par personne et par nuit :", round(prix_med_mk2, 0), "€\n")
cat("Pour comparaison, sur l'ensemble des 12e et 13e :", round(prix_med_zone, 0), "€\n")


################################################################################
# 6. Prix médian par personne sur un maillage régulier de 200 m
################################################################################

# Remarque : les données Inside Airbnb ne contiennent pas la surface des
# logements. Le prix au m² n'est donc pas calculable ; on utilise le prix
# par personne (prix / capacité d'accueil) comme indicateur de prix comparable.

# Maillage de carreaux de 200 m couvrant les deux arrondissements
grille <- st_make_grid(arrdts, cellsize = 200, what = "polygons") %>%
  st_sf(geometry = .) %>%
  mutate(id_carreau = row_number())

# Rattachement de chaque location à son carreau, puis agrégation
stats_carreaux <- st_join(airbnb, grille) %>%
  st_drop_geometry() %>%
  group_by(id_carreau) %>%
  summarise(nb_locations = n(),
            prix_med_pers = median(prix_pers))

# On ne garde que les carreaux de plus de 5 locations (médiane plus fiable)
grille_prix <- grille %>%
  inner_join(stats_carreaux, by = "id_carreau") %>%
  filter(nb_locations > 5)

cat("\n--- Maillage de 200 m ---\n")
cat("Carreaux retenus (> 5 locations) :", nrow(grille_prix), "\n")
print(summary(grille_prix$prix_med_pers))

# Discrétisation de Jenks en 6 classes
breaks_jenks <- classIntervals(grille_prix$prix_med_pers, n = 6, style = "jenks")$brks

# Justification de la discrétisation :
# Les prix médians par carreau sont concentrés sur des valeurs moyennes, avec
# quelques carreaux nettement plus chers (voir figures/04_distribution_carreaux.png).
# La méthode de Jenks place les seuils là où les écarts entre valeurs sont les
# plus forts : elle forme des classes homogènes et isole les carreaux
# exceptionnels sans écraser les différences entre les autres.
png("figures/04_distribution_carreaux.png", width = 750, height = 400, res = 100)
hist(grille_prix$prix_med_pers, breaks = 30, col = "#f4a261", border = "white",
     main = "Prix médian par personne par carreau, seuils de Jenks",
     xlab = "Prix médian par personne (€)", ylab = "Nombre de carreaux")
abline(v = breaks_jenks, col = "#264653", lwd = 2, lty = 2)
dev.off()

png("figures/05_carte_prix_carreaux.png", width = 750, height = 600,
    res = 100, bg = FOND)

fond_de_carte()
mf_map(grille_prix, var = "prix_med_pers", type = "choro",
       breaks = breaks_jenks, pal = hcl.colors(6, "YlOrBr", rev = TRUE),
       border = NA,
       leg_title = "Prix médian par personne\npar nuit (€, Jenks)",
       leg_val_rnd = 0, leg_pos = "topright", leg_frame = TRUE,
       leg_bg = "#1F2733", leg_fg = "#f0f0f0", leg_frame_border = "#dfdfdf",
       add = TRUE)
habillage("Prix médian par personne, carreaux de 200 m (> 5 locations)")

dev.off()
