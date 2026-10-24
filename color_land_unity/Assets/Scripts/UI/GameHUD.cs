using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using ColorLand.Logic;
using ColorLand.App;

namespace ColorLand.UI
{
    /// <summary>
    /// O'yin HUD va interfeys boshqaruvchisi (GameHUD).
    /// </summary>
    public class GameHUD : MonoBehaviour
    {
        public static GameHUD Instance { get; private set; }

        [Header("Top Bar")]
        public Text PlayerNameText;
        public Text TerritoryPercentText;
        public Text KillsText;
        public Button LanguageButton;
        public Text LanguageButtonText;

        [Header("Leaderboard")]
        public Text LeaderboardTitleText;
        public Text LeaderboardContentText;

        [Header("Game Over Dialog")]
        public GameObject GameOverPanel;
        public Text GameOverTitleText;
        public Text GameOverStatsText;
        public Button PlayAgainButton;
        public Text PlayAgainButtonText;

        private float _leaderboardTimer = 0f;

        private void Awake()
        {
            Instance = this;

            if (LanguageButton != null)
            {
                LanguageButton.onClick.AddListener(OnLanguageButtonClicked);
            }

            if (PlayAgainButton != null)
            {
                PlayAgainButton.onClick.AddListener(RestartGame);
            }

            if (GameOverPanel != null)
            {
                GameOverPanel.SetActive(false);
            }
        }

        private void Start()
        {
            Strings.OnLanguageChanged += OnLanguageChanged;
            OnLanguageChanged();

            if (GameWorld.Instance != null && GameWorld.Instance.Player != null)
            {
                GameWorld.Instance.Player.OnDied += OnPlayerDied;
            }
        }

        private void OnDestroy()
        {
            Strings.OnLanguageChanged -= OnLanguageChanged;
            if (GameWorld.Instance != null && GameWorld.Instance.Player != null)
            {
                GameWorld.Instance.Player.OnDied -= OnPlayerDied;
            }
        }

        private void OnLanguageButtonClicked()
        {
            if (LanguagePickerModal.Instance != null)
            {
                LanguagePickerModal.Instance.Toggle();
            }
        }

        public void OnLanguageChanged()
        {
            string lang = Strings.CurrentLanguage ?? "ru";

            if (LanguageButtonText != null)
            {
                LanguageButtonText.text = $"🌐 {lang.ToUpperInvariant()}";
            }

            if (LeaderboardTitleText != null)
            {
                LeaderboardTitleText.text = Strings.T("leaderboard").ToUpperInvariant();
            }

            if (GameOverTitleText != null)
            {
                GameOverTitleText.text = Strings.T("gameOver").ToUpperInvariant();
            }

            if (PlayAgainButtonText != null)
            {
                PlayAgainButtonText.text = Strings.T("playAgain").ToUpperInvariant();
            }
        }

        private void Update()
        {
            if (GameWorld.Instance == null || GameWorld.Instance.Player == null) return;

            var player = GameWorld.Instance.Player;

            // 1. O'yinchi statistikasi
            if (PlayerNameText != null)
            {
                PlayerNameText.text = $"[UZ] {player.PlayerName}";
            }

            if (TerritoryPercentText != null)
            {
                float pct = GameWorld.Instance.GetPlayerTerritoryPercentage();
                TerritoryPercentText.text = $"{pct:F1}%";
            }

            if (KillsText != null)
            {
                KillsText.text = $"☠ {player.Kills}";
            }

            // 2. Leaderboard har 0.3 soniyada yangilanadi
            _leaderboardTimer += Time.deltaTime;
            if (_leaderboardTimer >= 0.3f)
            {
                _leaderboardTimer = 0f;
                UpdateLeaderboard();
            }

            // Agar o'yinchi o'lgan bo'lsa
            if (!player.IsAlive && GameOverPanel != null && !GameOverPanel.activeSelf)
            {
                OnPlayerDied(player);
            }
        }

        private void UpdateLeaderboard()
        {
            if (GameWorld.Instance == null || LeaderboardContentText == null) return;

            var entries = new List<(string Name, float Pct, bool IsPlayer)>();

            int totalLand = GameWorld.Instance.Grid.TotalLandCells();
            if (totalLand <= 0) totalLand = 1;

            if (GameWorld.Instance.Player != null)
            {
                float pPct = (float)GameWorld.Instance.Grid.CountOwnedCells(GameWorld.Instance.Player.OwnerId) / totalLand * 100f;
                entries.Add((GameWorld.Instance.Player.PlayerName, pPct, true));
            }

            foreach (var bot in GameWorld.Instance.Bots)
            {
                if (bot == null || !bot.IsAlive) continue;
                float bPct = (float)GameWorld.Instance.Grid.CountOwnedCells(bot.OwnerId) / totalLand * 100f;
                entries.Add((bot.PlayerName, bPct, false));
            }

            entries.Sort((a, b) => b.Pct.CompareTo(a.Pct));

            var sb = new System.Text.StringBuilder();
            int top = Mathf.Min(5, entries.Count);
            for (int i = 0; i < top; i++)
            {
                var e = entries[i];
                string prefix = e.IsPlayer ? "<b><color=#22d3ee>" : "<color=#e2e8f0>";
                string suffix = e.IsPlayer ? "</color></b>" : "</color>";
                sb.AppendLine($"{prefix}{i + 1}. {e.Name}: {e.Pct:F1}%{suffix}");
            }

            LeaderboardContentText.text = sb.ToString();
        }

        private void OnPlayerDied(PlayerEntity p)
        {
            if (GameOverPanel != null)
            {
                GameOverPanel.SetActive(true);
                float finalPct = GameWorld.Instance.GetPlayerTerritoryPercentage();
                if (GameOverStatsText != null)
                {
                    GameOverStatsText.text = $"{Strings.T("territory")}: {finalPct:F1}%\n{Strings.T("kills")}: {p.Kills}";
                }
            }
        }

        public void RestartGame()
        {
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        }
    }
}
