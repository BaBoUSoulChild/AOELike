## iso_utils.gd
## Utilitaires de conversion de coordonnées isométriques.
## Toutes les fonctions sont statiques — pas besoin d'instancier.

class_name IsoUtils

const TILE_WIDTH: int = 128
const TILE_HEIGHT: int = 64

## Convertit des coordonnées de tuile (grille) en position écran (pixels).
## L'origine écran correspond à la tuile (0, 0).
static func tile_to_screen(tile_x: float, tile_y: float) -> Vector2:
	var sx: float = (tile_x - tile_y) * TILE_WIDTH / 2.0
	var sy: float = (tile_x + tile_y) * TILE_HEIGHT / 2.0
	return Vector2(sx, sy)

## Convertit une position écran en coordonnées de tuile (résultat non arrondi).
static func screen_to_tile(screen: Vector2) -> Vector2:
	var tx: float = (screen.x / (TILE_WIDTH / 2.0) + screen.y / (TILE_HEIGHT / 2.0)) / 2.0
	var ty: float = (screen.y / (TILE_HEIGHT / 2.0) - screen.x / (TILE_WIDTH / 2.0)) / 2.0
	return Vector2(tx, ty)

## Arrondit un vecteur de tuile à la tuile la plus proche.
static func round_tile(tile: Vector2) -> Vector2i:
	return Vector2i(int(round(tile.x)), int(round(tile.y)))

## Retourne vrai si les coordonnées de tuile sont dans les limites de la carte.
static func in_bounds(tile: Vector2i, map_size: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size.x and tile.y < map_size.y
