using System;
using System.IO;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.App
{
    [Serializable]
    public class SaveData
    {
        public int SchemaVersion = 1;
        public string AppVersion = VersionConfig.CURRENT_VERSION;
        public long LastSaveTimestamp = 0;

        // Iqtisodiyot va profil
        public int Coins = 1000;
        public int Gems = 50;
        public List<string> UnlockedSkins = new List<string> { "default" };
        public string ActiveSkin = "default";

        // Kunlik mukofotlar
        public int DailyRewardDay = 1;
        public long LastDailyRewardTime = 0;

        // O'yin statistikasi
        public int HighScoreTerritory = 0;
        public int TotalKills = 0;
        public int TotalGamesPlayed = 0;

        // Sozlamalar
        public string SelectedLanguage = "ru";
        public bool SoundEnabled = true;
        public bool MusicEnabled = true;
        public bool VibrationEnabled = true;
    }

    /// <summary>
    /// Foydalanuvchi ma'lumotlarini doimiy saqlash va migratsiya qilish menejeri (SaveManager).
    /// Yangilanishlar va orqaga qaytishlar (rollback) vaqtida foydalanuvchi profili,
    /// tangalari, ochilgan liboslari va til parametrlarini to'liq asrab qoladi.
    /// </summary>
    public static class SaveManager
    {
        public const int CURRENT_SCHEMA_VERSION = 1;
        private const string SAVE_FILE_NAME = "save_data.json";
        private const string PREFS_BACKUP_KEY = "colorland_save_backup";

        private static SaveData _current;
        public static SaveData Current
        {
            get
            {
                if (_current == null) Load();
                return _current;
            }
        }

        public static event Action OnDataChanged;

        private static string GetSaveFilePath()
        {
            try
            {
                string dir = Application.persistentDataPath;
                if (!string.IsNullOrEmpty(dir))
                {
                    return Path.Combine(dir, SAVE_FILE_NAME);
                }
            }
            catch
            {
                // Standalone test rejimida
            }

            return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, SAVE_FILE_NAME);
        }

        private static readonly System.Text.Json.JsonSerializerOptions _jsonOptions = new System.Text.Json.JsonSerializerOptions
        {
            IncludeFields = true,
            WriteIndented = true
        };

        private static string SerializeJson(SaveData data)
        {
            try
            {
                return JsonUtility.ToJson(data, true);
            }
            catch
            {
                try
                {
                    return System.Text.Json.JsonSerializer.Serialize(data, _jsonOptions);
                }
                catch (Exception ex)
                {
                    Debug.LogWarning($"[SaveManager] Serializatsiya xatosi: {ex.Message}");
                    return "{}";
                }
            }
        }

        private static SaveData DeserializeJson(string json)
        {
            if (string.IsNullOrEmpty(json)) return null;
            try
            {
                return JsonUtility.FromJson<SaveData>(json);
            }
            catch
            {
                try
                {
                    return System.Text.Json.JsonSerializer.Deserialize<SaveData>(json, _jsonOptions);
                }
                catch (Exception ex)
                {
                    Debug.LogWarning($"[SaveManager] Deserializatsiya xatosi: {ex.Message}");
                    return null;
                }
            }
        }

        [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
        private static void TrySavePlayerPrefs(string key, string val)
        {
            PlayerPrefs.SetString(key, val);
            PlayerPrefs.Save();
        }

        [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
        private static string TryGetPlayerPrefs(string key)
        {
            return PlayerPrefs.GetString(key, null);
        }

        public static void Load()
        {
            string path = GetSaveFilePath();
            string json = null;

            // 1. Asosiy fayldan o'qish
            try
            {
                if (File.Exists(path))
                {
                    json = File.ReadAllText(path);
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[SaveManager] Asosiy fayldan o'qishda xatolik: {ex.Message}");
            }

            // 2. Fayl topilmasa yoki buzilgan bo'lsa, PlayerPrefs zaxirasidan o'qish
            if (string.IsNullOrEmpty(json))
            {
                try
                {
                    json = TryGetPlayerPrefs(PREFS_BACKUP_KEY);
                }
                catch { }
            }

            // 3. Agar zaxira ham bo'lmasa, yangi ma'lumot yaratish
            if (string.IsNullOrEmpty(json))
            {
                _current = CreateDefault();
                Save();
                return;
            }

            try
            {
                _current = DeserializeJson(json);
                if (_current == null)
                {
                    _current = CreateDefault();
                }
                else
                {
                    MigrateIfNeeded(_current);
                }
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SaveManager] JSON tahlil xatosi: {ex.Message}. Boshlang'ich holat tiklanmoqda.");
                _current = CreateDefault();
            }

            OnDataChanged?.Invoke();
        }

        public static void Save()
        {
            if (_current == null) _current = CreateDefault();

            _current.LastSaveTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            _current.AppVersion = VersionConfig.CURRENT_VERSION;

            string json = SerializeJson(_current);

            // A. Faylga xavfsiz yozish (Atomik almashuv)
            try
            {
                string path = GetSaveFilePath();
                string tempPath = path + ".tmp";
                string dir = Path.GetDirectoryName(path);
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }

                File.WriteAllText(tempPath, json);
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
                File.Move(tempPath, path);
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[SaveManager] Faylga yozish xatosi: {ex.Message}");
            }

            // B. PlayerPrefs ga zaxiralash
            try
            {
                TrySavePlayerPrefs(PREFS_BACKUP_KEY, json);
            }
            catch { }

            OnDataChanged?.Invoke();
        }

        public static SaveData CreateDefault()
        {
            return new SaveData
            {
                SchemaVersion = CURRENT_SCHEMA_VERSION,
                AppVersion = VersionConfig.CURRENT_VERSION,
                LastSaveTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                Coins = 1000,
                Gems = 50,
                UnlockedSkins = new List<string> { "default" },
                ActiveSkin = "default",
                DailyRewardDay = 1,
                LastDailyRewardTime = 0,
                HighScoreTerritory = 0,
                TotalKills = 0,
                TotalGamesPlayed = 0,
                SelectedLanguage = "ru",
                SoundEnabled = true,
                MusicEnabled = true,
                VibrationEnabled = true
            };
        }

        private static void MigrateIfNeeded(SaveData data)
        {
            if (data.SchemaVersion < CURRENT_SCHEMA_VERSION)
            {
                Debug.Log($"[SaveManager] Sxema migratsiyasi: v{data.SchemaVersion} -> v{CURRENT_SCHEMA_VERSION}");
                
                // Kelajakdagi migratsiyalar uchun pog'onama-pog'ona yangilash
                // if (data.SchemaVersion == 1) { /* v1 -> v2 */ data.SchemaVersion = 2; }

                data.SchemaVersion = CURRENT_SCHEMA_VERSION;
                Save();
            }

            // Unlocked skins ro'yxatini tekshirish
            if (data.UnlockedSkins == null || data.UnlockedSkins.Count == 0)
            {
                data.UnlockedSkins = new List<string> { "default" };
            }
            if (string.IsNullOrEmpty(data.ActiveSkin))
            {
                data.ActiveSkin = "default";
            }
        }

        public static string ExportBackup()
        {
            if (_current == null) Load();
            return SerializeJson(_current);
        }

        public static bool ImportBackup(string json)
        {
            if (string.IsNullOrEmpty(json)) return false;

            try
            {
                SaveData imported = DeserializeJson(json);
                if (imported == null) return false;

                MigrateIfNeeded(imported);
                _current = imported;
                Save();
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SaveManager] Zaxiradan tiklashda xatolik: {ex.Message}");
                return false;
            }
        }

        public static void ResetToDefaults()
        {
            _current = CreateDefault();
            Save();
        }
    }
}
