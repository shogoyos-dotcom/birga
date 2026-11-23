/// O'yinchi o'limining sababi.
enum DeathCause {
  none,

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
  const DeathEvent(this.playerId, this.cause, this.killerId, this.clearedCells);

  final int playerId;
  final DeathCause cause;
  final int? killerId;

  /// Bo'shagan hudud kataklari — o'lim animatsiyasi uchun.
  final List<int> clearedCells;
}

class RespawnEvent extends GameEvent {
  const RespawnEvent(this.playerId);

  final int playerId;
}
