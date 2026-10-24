using System;
using UnityEngine;

namespace ColorLand.Logic
{
    /// <summary>
    /// Bot sun'iy intellekti (Bot AI).
    /// O'z hududidan chiqib halqa yasaydi, iz juda uzayganda yoki xavf sezganda o'z hududiga qaytadi.
    /// Suvga tushishdan saqlanadi.
    /// </summary>
    public class BotAI : MonoBehaviour
    {
        public enum BotState { Expanding, Returning }

        public PlayerState State;
        public float DirectionChangeInterval = 0.8f;

        private BotState _currentState = BotState.Expanding;
        private Vector2 _currentDirection = Vector2.up;
        private float _stateTimer = 0f;
        private int _maxTrailLength = 20;
        private GameGrid _grid;

        public void Initialize(GameGrid grid, int personalitySeed)
        {
            _grid = grid;
            System.Random rnd = new System.Random(personalitySeed);
            _maxTrailLength = rnd.Next(12, 28);
            DirectionChangeInterval = (float)(0.5 + rnd.NextDouble() * 0.8);
            _currentDirection = new Vector2((float)(rnd.NextDouble() * 2 - 1), (float)(rnd.NextDouble() * 2 - 1)).normalized;
        }

        private void Update()
        {
            if (State == null || State.Entity == null || !State.Entity.IsAlive || _grid == null) return;

            _stateTimer += Time.deltaTime;
            var entity = State.Entity;

            // 1. Agar iz juda uzaygan bo'lsa, o'z hududiga qaytish holatiga o'tadi
            if (entity.Trail.Count >= _maxTrailLength && _currentState != BotState.Returning)
            {
                _currentState = BotState.Returning;
            }

            // 2. O'z hududiga qaytib kelsa, yana kengayishni boshlaydi
            if (entity.Trail.Count == 0 && _currentState == BotState.Returning)
            {
                _currentState = BotState.Expanding;
                _stateTimer = 0f;
            }

            // 3. Yo'nalishni yangilash
            if (_stateTimer >= DirectionChangeInterval)
            {
                _stateTimer = 0f;
                DecideDirection();
            }

            // 4. Oldinda suv bormi? (Water avoidance)
            AvoidWater();

            // 5. Harakatlanish
            entity.Move(_currentDirection, Time.deltaTime);
        }

        private void DecideDirection()
        {
            var entity = State.Entity;

            if (_currentState == BotState.Returning)
            {
                // Eng yaqin o'z hududi katagini topish va unga qarab yo'nalish olish
                Vector2Int currentGrid = _grid.WorldToGrid(entity.Position);
                Vector2 bestDir = Vector2.zero;
                float closestDistSq = float.MaxValue;

                // 15x15 radius ichida o'z kataklarini qidirish
                for (int dy = -7; dy <= 7; dy++)
                {
                    for (int dx = -7; dx <= 7; dx++)
                    {
                        int gx = currentGrid.x + dx;
                        int gy = currentGrid.y + dy;
                        if (_grid.InBounds(gx, gy) && _grid.GetOwner(gx, gy) == entity.OwnerId)
                        {
                            float dsq = dx * dx + dy * dy;
                            if (dsq < closestDistSq)
                            {
                                closestDistSq = dsq;
                                bestDir = new Vector2(dx, dy).normalized;
                            }
                        }
                    }
                }

                if (bestDir.sqrMagnitude > 0.01f)
                {
                    _currentDirection = bestDir;
                    return;
                }
            }

            // Expanding holatida: biroz burchakni burish (yoy / halqa yasash uchun)
            float angle = UnityEngine.Random.Range(-45f, 45f) * Mathf.Deg2Rad;
            float cos = Mathf.Cos(angle);
            float sin = Mathf.Sin(angle);
            _currentDirection = new Vector2(
                _currentDirection.x * cos - _currentDirection.y * sin,
                _currentDirection.x * sin + _currentDirection.y * cos
            ).normalized;
        }

        private void AvoidWater()
        {
            var entity = State.Entity;
            Vector3 forwardCheck = entity.Position + new Vector3(_currentDirection.x, 0, _currentDirection.y) * 2.5f;
            Vector2Int checkGrid = _grid.WorldToGrid(forwardCheck);

            if (!_grid.IsLand(checkGrid.x, checkGrid.y))
            {
                // O'ngga yoki chapga 90 gradus burilish
                _currentDirection = new Vector2(-_currentDirection.y, _currentDirection.x);
            }
        }
    }
}
