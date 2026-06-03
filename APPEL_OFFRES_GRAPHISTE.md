# Appel à contribution — Graphiste Pixel Art Isométrique
## Projet : AOELike — Jeu de stratégie en temps réel open source

---

## 1. Présentation du projet

**AOELike** est un jeu de stratégie en temps réel (RTS) open source inspiré d'Age of Empires II et StarCraft, développé sous Godot 4 et distribué gratuitement via navigateur web (HTML5 / GitHub Pages).

Le projet est communautaire par nature : chaque civilisation est un pack indépendant (assets + code + config) que n'importe quel contributeur peut créer et soumettre. L'objectif est de construire un jeu extensible à l'infini, enrichi progressivement par des graphistes, développeurs et game designers du monde entier.

**Ambition :** Un RTS accessible, épique et modulaire — chaque civilisation est un univers visuel autonome, du médiéval humain à l'extraterrestre en passant par des peuples animaux ou fantastiques.

**Licence :** Open source — tes contributions seront publiées sous la même licence que le projet.

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

### Outil de travail
**Aseprite** (version stable actuelle) — recommandé pour la cohérence du projet
- Fichiers source `.aseprite` avec calques organisés
- Export PNG en spritesheets

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

### Structure de contribution
```
/civilisation_nom
    /units
        /villager       → spritesheet PNG + source .aseprite
        /warrior        → spritesheet PNG + source .aseprite
        /...
    /buildings
        /town_center    → PNG + source .aseprite
        /...
    /terrain
        /tiles          → spritesheet PNG + source .aseprite
    palette.aseprite         → palette de couleurs officielle
    README.md                → notes de direction artistique
```

> Ce format est le standard du projet. Toutes les civilisations futures devront le respecter pour assurer la cohérence et la maintenabilité.

### Contraintes techniques Godot 4
- Fond transparent (PNG avec canal alpha)
- Origine du sprite cohérente entre toutes les animations d'une même unité
- Spritesheets avec métadonnées JSON compatibles Godot (exportables depuis Aseprite)
- Palette de couleurs fixe par civilisation, fournie en fichier `.aseprite` séparé

---

## 4. Périmètre MVP — ce qu'on cherche à créer ensemble

### Terrain partagé
- 20 tiles de terrain minimum : herbe, neige/glace, terre, eau, sable, forêt
- 5 tiles de ressources : arbre, mine d'or, rocher, baie alimentaire, poisson

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

Tu peux contribuer sur l'ensemble ou sur une seule partie — chaque élément est utile.

---

## 5. Profil idéal

- Intérêt pour le **pixel art isométrique** (exemples dans ton portfolio bienvenus)
- À l'aise avec **Aseprite** ou équivalent
- Sensibilité aux jeux de stratégie (connaissance d'AOE2, StarCraft ou similaires est un plus)
- Envie de poser une **charte graphique durable** : le travail sur les deux premières civilisations servira de référence à tous les contributeurs futurs
- Disponible pour des échanges ponctuels de validation

Débutants motivés bienvenus — la qualité de l'intention compte autant que l'expérience.

---

## 6. Pourquoi contribuer

- Ton nom et ton portfolio dans les **crédits du jeu**
- Tes assets deviennent le **standard visuel** suivi par tous les contributeurs futurs
- Un projet vivant, jouable dans le navigateur, avec des retours réguliers de vrais joueurs
- Liberté créative dans un cadre clair — la direction artistique est posée, pas figée
- Communauté accueillante, projet piloté avec méthode

---

## 7. Comment contribuer

1. Explore le repo : **github.com/babousoulchild/aoelike**
2. Ouvre une **Issue** pour te présenter et indiquer sur quoi tu veux travailler
3. On échange pour aligner les visions
4. Tu soumets une première ébauche (ex : un villageois Viking) pour valider la direction
5. Pull Request → review → merge

Pas besoin de tout faire d'un coup. Une icône, un tile, une unité — chaque contribution compte.

---

*Document version 2.0 — Juin 2026*
*Projet AOELike — github.com/babousoulchild/aoelike*
