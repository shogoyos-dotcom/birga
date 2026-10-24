using System;
using System.Collections.Generic;
using UnityEngine;
using ColorLand.Render;
using ColorLand.App;

namespace ColorLand.Logic
{
    /// <summary>
    /// O'yin dunyosi boshqaruvchisi (GameWorld).
    /// Grid, Player, 20 ta Bot, PaintLayer, shaharlar va kamerani sinxron boshqaradi.
    /// Multfilm 3D vizual qahramonlar, bayroqlar va palitrani GPU bilan bog'laydi.
    /// </summary>
    public class GameWorld : MonoBehaviour
    {
        public static GameWorld Instance { get; private set; }

        [Header("Settings")]
        public int GridWidth = 120;
        public int GridHeight = 120;
        public float CellSize = 1.0f;
        public int BotCount = 20;

        [Header("Prefabs & References")]
        public GameObject PlayerPrefab;
        public GameObject BotPrefab;
        public PaintLayer PaintLayer;
        public Material ArenaMaterial;
        public CityRenderer CityRenderer;

        public GameGrid Grid { get; private set; }
        public TerritoryCapture CaptureSystem { get; private set; }
        public CitySystem CitySystem { get; private set; }
        public PlayerEntity Player { get; private set; }
        public List<PlayerEntity> Bots { get; private set; } = new List<PlayerEntity>();

        private static readonly string[] BotCountryCodes = new string[]
        {
            "RU", "KZ", "TR", "DE", "FR", "JP", "US", "BR", "CN", "GB",
            "IT", "ES", "IN", "KR", "EG", "SA", "AE", "CA", "AU", "ZA"
        };

        private void Awake()
        {
            Instance = this;
        }

        private void Start()
        {
            InitializeGame();
        }

        public void InitializeGame()
        {
            Grid = new GameGrid(GridWidth, GridHeight, CellSize);
            CitySystem = new CitySystem(Grid);
            CitySystem.LoadDefaultCities(GridWidth, GridHeight);
            CaptureSystem = new TerritoryCapture(Grid, CitySystem);

            if (CityRenderer != null)
            {
                CityRenderer.Initialize(CitySystem);
            }

            CitySystem.OnCityCaptured += (city, capturerId, reward) =>
            {
                if (capturerId == 1)
                {
                    if (ColorLand.UI.CityNotificationManager.Instance != null)
                    {
                        ColorLand.UI.CityNotificationManager.Instance.NotifyCityCaptured(city, reward);
                    }
                }
            };

            if (PaintLayer != null)
            {
                PaintLayer.Initialize(Grid, ArenaMaterial);
            }

            // 1. O'yinchi
            Vector2Int playerSpawn = new Vector2Int(GridWidth / 2, GridHeight / 2);
            Player = new PlayerEntity(Grid, CaptureSystem, playerSpawn, 1)
            {
                PlayerName = "SHO",
                CountryCode = "UZ",
                PlayerColor = new Color(0.15f, 0.65f, 1.0f)
            };

            if (PaintLayer != null)
            {
                PaintLayer.SetPaletteColor(Player.OwnerId, Player.PlayerColor);
            }

            Player.OnTerritoryCaptured += (count) =>
            {
                if (PaintLayer != null) PaintLayer.UpdateFull();
            };

            Player.OnDied += (p) =>
            {
                ClearOwnerCells(p.OwnerId);
                if (p.LastAttackerId > 1)
                {
                    var attacker = Bots.Find(b => b.OwnerId == p.LastAttackerId);
                    if (attacker != null) attacker.Kills++;
                }
            };

            GameObject playerObj = PlayerPrefab != null ? Instantiate(PlayerPrefab) : CreateDefaultCharacterObject("Player", Player.PlayerColor, "UZ");
            var playerState = playerObj.GetComponent<PlayerState>() ?? playerObj.AddComponent<PlayerState>();
            playerState.Bind(Player);

            var playerRibbon = playerObj.GetComponent<TrailRibbon>() ?? playerObj.AddComponent<TrailRibbon>();
            playerRibbon.State = playerState;
            playerRibbon.Initialize(Grid, Player.PlayerColor);

            // Kamera kuzatuvi
            var cam = Camera.main;
            if (cam != null)
            {
                var follow = cam.GetComponent<CameraFollow>() ?? cam.gameObject.AddComponent<CameraFollow>();
                follow.Target = playerObj.transform;
            }

            // 2. 20 ta Bot
            Bots.Clear();
            System.Random rnd = new System.Random(12345);

            Color[] presetColors = new Color[]
            {
                new Color(0.96f, 0.26f, 0.21f), // Qizil
                new Color(1.00f, 0.60f, 0.00f), // Sabzirang
                new Color(1.00f, 0.85f, 0.00f), // Sariq
                new Color(0.61f, 0.15f, 0.69f), // Binafsha
                new Color(0.91f, 0.12f, 0.39f), // Pushti
                new Color(0.00f, 0.75f, 0.65f), // Teal
                new Color(0.20f, 0.80f, 0.20f), // Yashil
                new Color(0.40f, 0.20f, 0.60f), // To'q binafsha
                new Color(1.00f, 0.40f, 0.60f), // Och pushti
                new Color(0.10f, 0.85f, 0.90f), // Moviy
                new Color(0.85f, 0.65f, 0.13f), // Oltin
                new Color(0.70f, 0.30f, 0.10f), // Jigarrang
                new Color(0.10f, 0.50f, 0.80f), // Kobalt
                new Color(0.80f, 0.10f, 0.50f), // Fuksia
                new Color(0.30f, 0.70f, 0.90f), // Havorang
                new Color(0.60f, 0.80f, 0.20f), // Laym
                new Color(0.95f, 0.50f, 0.30f), // Shaftoli
                new Color(0.50f, 0.50f, 0.90f), // Nilrang
                new Color(0.90f, 0.20f, 0.40f), // Malina
                new Color(0.15f, 0.75f, 0.45f), // Zumrad
            };

            for (int i = 0; i < BotCount; i++)
            {
                byte botId = (byte)(i + 2);
                Vector2Int botSpawn = FindSafeSpawn(rnd);

                Color botColor = (i < presetColors.Length) ? presetColors[i] : UnityEngine.Random.ColorHSV(0f, 1f, 0.6f, 0.9f, 0.7f, 1.0f);
                string bCountry = (i < BotCountryCodes.Length) ? BotCountryCodes[i] : "UN";

                var botEntity = new PlayerEntity(Grid, CaptureSystem, botSpawn, botId)
                {
                    PlayerName = $"Bot_{i + 1}",
                    CountryCode = bCountry,
                    PlayerColor = botColor
                };

                if (PaintLayer != null)
                {
                    PaintLayer.SetPaletteColor(botId, botColor);
                }

                botEntity.OnTerritoryCaptured += (count) =>
                {
                    if (PaintLayer != null) PaintLayer.UpdateFull();
                };

                botEntity.OnDied += (b) =>
                {
                    ClearOwnerCells(b.OwnerId);
                    if (b.LastAttackerId == Player.OwnerId)
                    {
                        Player.Kills++;
                    }
                    else if (b.LastAttackerId > 1)
                    {
                        var attacker = Bots.Find(a => a.OwnerId == b.LastAttackerId);
                        if (attacker != null) attacker.Kills++;
                    }
                };

                GameObject botObj = BotPrefab != null ? Instantiate(BotPrefab) : CreateDefaultCharacterObject($"Bot_{botId}", botColor, bCountry);
                var botState = botObj.GetComponent<PlayerState>() ?? botObj.AddComponent<PlayerState>();
                botState.Bind(botEntity);

                var botRibbon = botObj.GetComponent<TrailRibbon>() ?? botObj.AddComponent<TrailRibbon>();
                botRibbon.State = botState;
                botRibbon.Initialize(Grid, botColor);

                var botAI = botObj.GetComponent<BotAI>() ?? botObj.AddComponent<BotAI>();
                botAI.State = botState;
                botAI.Initialize(Grid, i * 77 + 13);

                Bots.Add(botEntity);
            }

            if (PaintLayer != null)
            {
                PaintLayer.UpdateFull();
            }
        }

        private GameObject CreateDefaultCharacterObject(string name, Color color, string countryCode)
        {
            return ColorLand.Render.CharacterModel.BuildCuteCartoonBall(name, color, countryCode);
        }

        private Vector2Int FindSafeSpawn(System.Random rnd)
        {
            for (int attempts = 0; attempts < 100; attempts++)
            {
                int x = rnd.Next(10, GridWidth - 10);
                int y = rnd.Next(10, GridHeight - 10);

                if (Grid.IsLand(x, y) && Grid.GetOwner(x, y) == GameGrid.OWNER_NONE)
                {
                    return new Vector2Int(x, y);
                }
            }
            return new Vector2Int(GridWidth / 2, GridHeight / 2);
        }

        private void Update()
        {
            if (Player != null && Player.IsAlive)
            {
                Vector2 inputDir = ColorLand.UI.VirtualJoystick.Instance != null 
                    ? ColorLand.UI.VirtualJoystick.Instance.GetMovementVector() 
                    : new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));

                if (inputDir.sqrMagnitude > 0.01f)
                {
                    Player.Move(inputDir, Time.deltaTime);
                }

                Player.UpdateDanger(Time.deltaTime);
            }

            foreach (var bot in Bots)
            {
                if (bot != null && bot.IsAlive)
                {
                    bot.UpdateDanger(Time.deltaTime);
                }
            }

            CheckCollisions();
        }

        private void CheckCollisions()
        {
            if (Player != null && Player.IsAlive)
            {
                Vector2Int playerHead = Grid.WorldToGrid(Player.Position);

                foreach (var bot in Bots)
                {
                    if (!bot.IsAlive) continue;

                    // O'yinchi botning iziga tegsa -> xavf to'lqini boshlanadi
                    if (bot.CheckTrailCollision(playerHead))
                    {
                        bot.TriggerTrailDanger(Player.OwnerId, playerHead);
                    }

                    // Bot o'yinchining iziga tegsa -> xavf to'lqini boshlanadi
                    Vector2Int botHead = Grid.WorldToGrid(bot.Position);
                    if (Player.CheckTrailCollision(botHead))
                    {
                        Player.TriggerTrailDanger(bot.OwnerId, botHead);
                    }

                    // Boshlar to'qnashuvi
                    if (playerHead == botHead)
                    {
                        Player.Die();
                        bot.Die();
                    }
                }
            }

            // Botlar o'zaro bir-birining izini kesishi
            for (int i = 0; i < Bots.Count; i++)
            {
                var botA = Bots[i];
                if (!botA.IsAlive) continue;
                Vector2Int headA = Grid.WorldToGrid(botA.Position);

                for (int j = 0; j < Bots.Count; j++)
                {
                    if (i == j) continue;
                    var botB = Bots[j];
                    if (!botB.IsAlive) continue;

                    if (botB.CheckTrailCollision(headA))
                    {
                        botB.TriggerTrailDanger(botA.OwnerId, headA);
                    }
                }
            }
        }

        public void ClearOwnerCells(byte ownerId)
        {
            int total = Grid.Width * Grid.Height;
            for (int y = 0; y < Grid.Height; y++)
            {
                for (int x = 0; x < Grid.Width; x++)
                {
                    if (Grid.GetOwner(x, y) == ownerId)
                    {
                        Grid.SetOwner(x, y, GameGrid.OWNER_NONE);
                        if (PaintLayer != null)
                        {
                            PaintLayer.SetCell(x, y, GameGrid.OWNER_NONE);
                        }
                    }
                }
            }
            if (PaintLayer != null) PaintLayer.UpdateFull();
        }

        public float GetPlayerTerritoryPercentage()
        {
            if (Grid == null || Player == null) return 0f;
            int totalLand = Grid.TotalLandCells();
            if (totalLand == 0) return 0f;
            return (float)Grid.CountOwnedCells(Player.OwnerId) / totalLand * 100f;
        }
    }
}
