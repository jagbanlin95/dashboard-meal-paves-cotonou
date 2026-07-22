/*==============================================================================
    ÉTUDE SOCIO-ÉCONOMIQUE ET ENVIRONNEMENTALE
    Valorisation des déchets plastiques en pavés préfabriqués - Cotonou
    Do-file d'analyse complet — Joël AGBANLIN

    INSTRUCTIONS AVANT DE LANCER :
    1. Place ce fichier .do et les 2 fichiers .csv dans le MÊME dossier
    2. Modifie le chemin ci-dessous (ligne "cd") pour qu'il pointe vers ce dossier
    3. Lance le do-file en entier (bouton "Execute (do)" ou Ctrl+D) ou section par
       section (sélectionne le bloc de code puis Ctrl+D)
==============================================================================*/

clear all
set more off

* --- ÉTAPE 0 : Définir le dossier de travail --------------------------------
* Remplace le chemin ci-dessous par le dossier où tu as mis les fichiers

cd "C:\Users\Joel AGBANLIN\Desktop\Etude_Paves_Cotonou"


/*==============================================================================
    PARTIE 1 — DONNÉES MÉNAGES (N=120) : acceptabilité et déterminants
==============================================================================*/

* --- 1.1 Import des données ménages -----------------------------------------
import delimited "donnees_menages.csv", clear varnames(1) encoding("utf-8")

* Vérification rapide : nombre d'observations, aperçu
describe
list in 1/5
count

* --- 1.2 Recodage des variables qualitatives en indicatrices (0/1) ----------
gen tri_bin      = (tri == "Oui")
gen connait_bin  = (connait == "Oui")
gen achat_bin    = (achat == "Oui")

* Variable quartier en numérique pour Stata (encode transforme le texte en
* catégories numériques tout en gardant les libellés)
encode quartier, gen(quartier_num)

* Revenu en milliers de FCFA (plus lisible dans les résultats)
gen revenu_k = revenu / 1000

label variable tri_bin     "Pratique le tri à la source (1=Oui)"
label variable connait_bin "Connaît la filière pavé recyclé (1=Oui)"
label variable achat_bin   "Disposé à acheter un pavé recyclé (1=Oui)"
label variable revenu_k    "Revenu mensuel estimé (milliers FCFA)"

* --- 1.3 Statistiques descriptives -------------------------------------------
summarize taille_menage revenu tri_bin connait_bin achat_bin

* Taux clés par quartier (équivalent aux indicateurs du classeur Excel)
tabstat tri_bin connait_bin achat_bin, by(quartier) statistics(mean) format(%9.3f)

* Tableaux croisés utiles
tabulate quartier tri,    row
tabulate quartier achat,  row

* --- 1.4 Graphique descriptif : taux d'acceptabilité par quartier -----------
graph bar (mean) tri_bin connait_bin achat_bin, over(quartier) ///
    legend(label(1 "Tri à la source") label(2 "Connaît la filière") label(3 "Disposé à acheter")) ///
    title("Indicateurs d'acceptabilité par quartier") ///
    ytitle("Proportion de ménages") ///
    blabel(bar, format(%9.2f))
graph export "graphique_indicateurs_quartier.png", replace width(1200)

* --- 1.5 Modèle Logit : déterminants de la disposition à acheter ------------
* Variable dépendante binaire (achat_bin) -> modèle logit standard
logit achat_bin i.quartier_num taille_menage revenu_k connait_bin tri_bin

* Odds ratios (plus faciles à interpréter que les coefficients bruts)
logit, or

* Effets marginaux (variation de probabilité pour chaque variable)
margins, dydx(*)

* Qualité d'ajustement du modèle
estat classification
estat gof


*    Édition > Copier, puis colle-le dans ton document Word/rapport.
estimates store modele_logit
estimates table modele_logit, eform b(%9.3f) star(0.05 0.01 0.001)



/*==============================================================================
    PARTIE 2 — ACTEURS DE LA CHAÎNE DE VALEUR (N=25) : emploi, revenu, environnement
==============================================================================*/

* --- 2.1 Import des données acteurs ------------------------------------------
import delimited "acteurs_chaine_valeur.csv", clear varnames(1) encoding("utf-8")

describe
list in 1/5

* --- 2.2 Emplois recensés par type d'acteur ----------------------------------
tabulate type_acteur

* --- 2.3 Revenu actuel vs revenu potentiel (scénario projeté) ---------------
* Rappel : le revenu potentiel est une PROJECTION (+15-25%), pas une mesure
* réelle - ce point doit être répété dans ton rapport final.
summarize revenu_actuel revenu_potentiel variation_pct

tabstat revenu_actuel revenu_potentiel variation_pct, by(type_acteur) ///
    statistics(mean) format(%9.0f)

* Test de différence de moyenne (revenu actuel vs revenu potentiel)
* ttest apparié car c'est la MÊME personne avant/après (projection)
ttest revenu_actuel == revenu_potentiel

* --- 2.4 Volume de plastique traité (proxy environnemental) -----------------
summarize volume_kg_mois
tabstat volume_kg_mois, by(type_acteur) statistics(sum mean) format(%9.0f)

* Volume total mensuel et projection annuelle
egen volume_total_mois = total(volume_kg_mois)
display "Volume total traité par l'échantillon : " volume_total_mois " kg/mois"
display "Projection annuelle (échantillon) : " volume_total_mois*12 " kg/an"

* --- 2.5 Graphique : revenu actuel vs potentiel par type d'acteur -----------
graph bar (mean) revenu_actuel revenu_potentiel, over(type_acteur) ///
    legend(label(1 "Revenu actuel") label(2 "Revenu potentiel (projeté)")) ///
    title("Revenu actuel vs potentiel par type d'acteur") ///
    ytitle("FCFA / mois") ///
    blabel(bar, format(%9.0f))
graph export "graphique_revenus_acteurs.png", replace width(1200)

/*==============================================================================
    FIN — Résultats exportés :
    - resultats_logit.doc         (tableau du modèle logit, prêt à coller dans Word)
    - graphique_indicateurs_quartier.png
    - graphique_revenus_acteurs.png
==============================================================================*/
