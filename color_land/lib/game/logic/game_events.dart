/// O'yinchi o'limining sababi.
enum DeathCause {
  none,

  /// Xarita chegarasiga urildi.
  wall,

  /// O'z izini kesib o'tdi.
  selfCross,

  /// Raqib iziga tegdi (izning egasi o'ladi).
  trailHit,

  /// Butun hududi raqib tomonidan egallandi.
  territoryLost,
}

/// Mantiq qatlami rendering uchun chiqaradigan hodisalar.
sealed class GameEvent {
  const GameEvent();
}

class CaptureEvent extends GameEvent {
  const CaptureEvent(this.playerId, this.cells);

  final int playerId;
  final List<int> cells;
}

class DeathEvent extends GameEvent {
  const DeathEvent(this.playerId, this.cause, this.killerId);

  final int playerId;
  final DeathCause cause;
  final int? killerId;
}

class RespawnEvent extends GameEvent {
  const RespawnEvent(this.playerId);

  final int playerId;
}
