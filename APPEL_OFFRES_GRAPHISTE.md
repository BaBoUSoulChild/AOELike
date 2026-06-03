# Appel d'offres — Graphiste Pixel Art Isométrique
## Projet : AOELike — Jeu de stratégie en temps réel

---

## 1. Présentation du projet

**AOELike** est un jeu de stratégie en temps réel (RTS) inspiré d'Age of Empires II et StarCraft, développé sous Godot 4 et distribué via navigateur web (HTML5 / GitHub Pages).

Le projet est porté par un développeur-chef de projet avec une vision à long terme : construire un jeu extensible à l'infini, dont les civilisations seront progressivement enrichies par une communauté de contributeurs (graphistes, développeurs, game designers).

**Ambition :** Un RTS accessible, épique et modulaire — chaque civilisation est un univers visuel autonome, du médiéval humain à l'extraterrestre en passant par des peuples animaux ou fantastiques.

**Public cible initial :** Joueurs fans d'AOE2 / RTS classiques.

**Plateforme :** Navigateur web (HTML5), potentiellement desktop ensuite.

---

## 2. Direction artistique

### Style général
- **Pixel art isométrique semi-réaliste**
- Références directes : Age of Empires II (lisibilité, unités expressives) + StarCraft (cohérence entre civilisations radicalement différentes)
- Tonalité : **épique, contrastée, moralement ambiguë** — l'apparence visuelle d'une civilisation ne préjuge pas de son alignement moral

### Règle fondamentale
Chaque civilisation possède son **propre langage visuel** (palette, matériaux, architecture, silhouettes d'unités). L'identification ami/ennemi en jeu se fait via un **overlay couleur joueur** superposé aux sprites, comme dans AOE2 — non par un code couleur imposé au design.

### Civilisations du MVP

#### Civilisation 1 — Vikings
| Élément | Direction |
|---|---|
| Palette | Gris fer, brun bois sombre, bleu nordique profond, rouge sang |
| Matériaux | Bois brut, fer forgé, peaux, runes gravées |
| Terrain | Fjords, forêts denses, neige, brume maritime |
| Unités | Silhouettes massives, lourdes, expressives, imposantes |
| Bâtiments | Mead hall en rondins, longships à quai, tours en bois brut, forge |
| Mood | Brut, puissant, mythologique, nordique |

#### Civilisation 2 — Japon Féodal
| Élément | Direction |
|---|---|
| Palette | Blanc, rouge torii, vert bambou et pin, or, gris pierre volcanique |
| Matériaux | Bois lacqué, papier washi, pierre taillée, soie, acier poli |
| Terrain | Montagnes brumeuses, cerisiers en fleur, rizières, bambouseraies |
| Unités | Silhouettes légères, précises, épurées, rapides |
| Bâtiments | Pagodes, torii, dojos, château (tenshu), jardins zen |
| Mood | Élégant, discipliné, spirituel, raffiné |

---

## 3. Spécifications techniques

### Outil de travail obligatoire
**Aseprite** (version stable actuelle)
- Fichiers source `.aseprite` avec calques organisés obligatoires
- Export PNG en spritesheets organisées

### Résolutions

| Élément | Taille (px) | Notes |
|---|---|---|
| Tile de terrain | 128 × 64 | Isométrique standard, losange |
| Unité / personnage | 64 × 96 | Marge pour animations expressives |
| Petit bâtiment | 128 × 128 | Ferme, tour de guet, atelier |
| Grand bâtiment | 256 × 256 | Town center, mead hall, château |
| Icône UI | 64 × 64 | Ressources, boutons, portraits |

### Animations requises par unité
Chaque unité doit être animée dans **8 directions** (standard isométrique) avec les états suivants :

| Animation | Frames minimum |
|---|---|
| Idle (repos) | 4 — 6 frames |
| Walk (déplacement) | 8 — 12 frames |
| Attack (attaque) | 8 — 12 frames |
| Death (mort) | 8 — 10 frames |

> Le villageois (unité de récolte) inclut un état supplémentaire : **Gather** (récolte) — 8 frames.

### Format de livraison
```
/vikings
    /units
        /villager       → spritesheet PNG + source .aseprite
        /warrior        → spritesheet PNG + source .aseprite
        /archer         → ...
        /...
    /buildings
        /town_center    → PNG + source .aseprite
        /barracks       → ...
        /...
    /terrain
        /tiles          → spritesheet PNG + source .aseprite
    palette_vikings.aseprite   → palette de couleurs officielle
    README_vikings.md          → notes de direction artistique

/japan
    /units
        /...
    /buildings
        /...
    /terrain
        /...
    palette_japan.aseprite
    README_japan.md

/shared
    /ui
        /icons          → ressources, boutons
        /...
```

> Cette structure est le standard du projet : chaque future civilisation ajoutée par la communauté devra respecter exactement ce format.

### Contraintes techniques Godot 4
- Fond transparent (PNG avec canal alpha)
- Origine du sprite cohérente entre toutes les animations d'une même unité
- Spritesheets avec métadonnées JSON compatibles Godot (exportables depuis Aseprite)
- Palette de couleurs fixe par civilisation, fournie en fichier `.aseprite` séparé

---

## 4. Livrables attendus — MVP

### Terrain partagé
- 20 tiles de terrain minimum : herbe, neige/glace (Vikings), terre, eau, sable, forêt (déclinaisons)
- 5 tiles de ressources : arbre, mine d'or, rocher (pierre), baie alimentaire, poisson

### Civilisation Vikings
**Unités :** Villageois, Guerrier (hache), Archer, Berserker (unité spéciale)
**Bâtiments :** Town Center, Caserne, Ferme, Tour de guet, Forge, Quai

### Civilisation Japon Féodal
**Unités :** Villageois, Samouraï, Archer (Yumi), Ninja (unité spéciale)
**Bâtiments :** Town Center, Dojo (caserne), Rizière (ferme), Tour de guet, Forge, Sanctuaire

### UI de base (partagée)
- Icônes des 4 ressources : Bois, Nourriture, Or, Pierre
- Portraits des unités (64×64 px)
- Icônes de bâtiments pour le menu de construction

---

## 5. Profil recherché

- Expérience confirmée en **pixel art isométrique** (portfolio obligatoire avec exemples isométriques)
- Maîtrise d'**Aseprite**
- Sensibilité aux jeux de stratégie (connaissance d'AOE2, StarCraft ou similaires est un plus)
- Capacité à **définir et tenir une charte graphique** : le travail produit sur le MVP servira de référence pour tous les contributeurs futurs
- Disponibilité pour des échanges réguliers de validation (1 à 2 points par semaine)
- Autonomie et force de proposition sur la direction artistique dans le cadre défini

---

## 6. Budget & modalités

**Budget cible MVP :** 5 000€ — 10 000€

**Mode de travail :**
- Paiement par jalons validés (terrain, civ 1, civ 2, UI)
- Validation visuelle à chaque livrable avant passage au suivant
- Contrat de cession de droits inclus (le graphiste conserve la mention de son travail dans les crédits)

**Durée estimée :** 3 à 6 mois selon disponibilité

**Premier jalon :** Concept art (non animé) d'un villageois Viking et d'un Samouraï pour valider la direction artistique avant de s'engager sur l'ensemble.

---

## 7. Pourquoi rejoindre ce projet

- Ton nom dans les crédits d'un jeu **distribué publiquement**
- Travail de référence : tes assets deviennent le **standard visuel** suivi par tous les contributeurs futurs
- Projet open-source et communautaire avec potentiel de croissance
- Direction artistique claire et cadre de travail structuré

---

## 8. Processus de sélection

1. Envoi du portfolio + tarif journalier ou forfait estimé
2. Échange de 30 minutes pour aligner les visions
3. Livraison du premier jalon test (concept art 2 unités) — rémunéré
4. Décision d'engagement sur le MVP complet

---

*Document version 1.0 — Juin 2026*
*Projet AOELike — github.com/babousoulchild/aoelike*
