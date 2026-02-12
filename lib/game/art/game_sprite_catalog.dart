part of '../base_defense_game.dart';

class GameSpriteCatalog {
  GameSpriteCatalog._({
    required this.base,
    required this.barracks,
    required this.watchtower,
    required this.player,
    required this.sceneryTree,
    required this.sceneryRock,
    required this.terrainGroundTile,
    required this.terrainPathStraight,
    required this.terrainPathCorner,
    required this.enemySprites,
  });

  final Sprite? base;
  final Sprite? barracks;
  final Sprite? watchtower;
  final Sprite? player;
  final Sprite? sceneryTree;
  final Sprite? sceneryRock;
  final Sprite? terrainGroundTile;
  final Sprite? terrainPathStraight;
  final Sprite? terrainPathCorner;
  final Map<EnemyType, Sprite> enemySprites;

  Sprite? enemyFor(EnemyType type) {
    return enemySprites[type] ?? enemySprites[EnemyType.grunt];
  }

  static Future<GameSpriteCatalog> load(Images images) async {
    final base = await _loadOptional(images, 'sprites/quarter/base.png');
    final barracks = await _loadOptional(
      images,
      'sprites/quarter/barracks.png',
    );
    final watchtower = await _loadOptional(
      images,
      'sprites/quarter/watchtower.png',
    );
    final player = await _loadOptional(images, 'sprites/quarter/player.png');
    final sceneryTree = await _loadOptional(
      images,
      'sprites/quarter/scenery/tree.png',
    );
    final sceneryRock = await _loadOptional(
      images,
      'sprites/quarter/scenery/rock.png',
    );
    final terrainGroundTile = await _loadOptional(
      images,
      'sprites/quarter/terrain/ground_tile.png',
    );
    final terrainPathStraight = await _loadOptional(
      images,
      'sprites/quarter/terrain/path_straight.png',
    );
    final terrainPathCorner = await _loadOptional(
      images,
      'sprites/quarter/terrain/path_corner.png',
    );

    final enemySprites = <EnemyType, Sprite>{};
    final grunt = await _loadOptional(
      images,
      'sprites/quarter/enemy_grunt.png',
    );
    final brute = await _loadOptional(
      images,
      'sprites/quarter/enemy_brute.png',
    );
    final elite = await _loadOptional(
      images,
      'sprites/quarter/enemy_elite.png',
    );
    final boss = await _loadOptional(images, 'sprites/quarter/enemy_boss.png');

    if (grunt != null) {
      enemySprites[EnemyType.grunt] = grunt;
    }
    if (brute != null) {
      enemySprites[EnemyType.brute] = brute;
    }
    if (elite != null) {
      enemySprites[EnemyType.elite] = elite;
    }
    if (boss != null) {
      enemySprites[EnemyType.boss] = boss;
    }

    return GameSpriteCatalog._(
      base: base,
      barracks: barracks,
      watchtower: watchtower,
      player: player,
      sceneryTree: sceneryTree,
      sceneryRock: sceneryRock,
      terrainGroundTile: terrainGroundTile,
      terrainPathStraight: terrainPathStraight,
      terrainPathCorner: terrainPathCorner,
      enemySprites: enemySprites,
    );
  }

  static Future<Sprite?> _loadOptional(Images images, String path) async {
    try {
      final image = await images.load(path);
      return Sprite(image);
    } catch (error) {
      debugPrint('[GameSpriteCatalog] Failed to load $path: $error');
      return null;
    }
  }
}
