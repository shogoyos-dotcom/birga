using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.App
{
    public struct LanguageInfo
    {
        public string Code;
        public string NativeName;
        public string EnglishName;
    }

    /// <summary>
    /// Markaziy lokalizatsiya tizimi (Strings).
    /// strings.json faylidan 15 tildagi barcha matnlarni yuklaydi va bir zumda almashtiradi.
    /// </summary>
    public static class Strings
    {
        public static readonly LanguageInfo[] SupportedLanguages = new LanguageInfo[]
        {
            new LanguageInfo { Code = "uz", NativeName = "O'zbekcha", EnglishName = "Uzbek" },
            new LanguageInfo { Code = "ru", NativeName = "Русский", EnglishName = "Russian" },
            new LanguageInfo { Code = "en", NativeName = "English", EnglishName = "English" },
            new LanguageInfo { Code = "tr", NativeName = "Türkçe", EnglishName = "Turkish" },
            new LanguageInfo { Code = "kk", NativeName = "Қазақша", EnglishName = "Kazakh" },
            new LanguageInfo { Code = "de", NativeName = "Deutsch", EnglishName = "German" },
            new LanguageInfo { Code = "fr", NativeName = "Français", EnglishName = "French" },
            new LanguageInfo { Code = "es", NativeName = "Español", EnglishName = "Spanish" },
            new LanguageInfo { Code = "pt", NativeName = "Português", EnglishName = "Portuguese" },
            new LanguageInfo { Code = "ar", NativeName = "العربية", EnglishName = "Arabic" },
            new LanguageInfo { Code = "hi", NativeName = "हिन्दी", EnglishName = "Hindi" },
            new LanguageInfo { Code = "zh", NativeName = "中文", EnglishName = "Chinese" },
            new LanguageInfo { Code = "ja", NativeName = "日本語", EnglishName = "Japanese" },
            new LanguageInfo { Code = "ko", NativeName = "한국어", EnglishName = "Korean" },
            new LanguageInfo { Code = "id", NativeName = "Bahasa Indonesia", EnglishName = "Indonesian" },
        };

        public static string CurrentLanguage { get; private set; } = "ru";

        private static readonly Dictionary<string, Dictionary<string, string>> _catalog = 
            new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);

        public static event Action OnLanguageChanged;

        static Strings()
        {
            try
            {
                string saved = PlayerPrefs.GetString("selected_language", "ru");
                if (!string.IsNullOrEmpty(saved)) CurrentLanguage = saved;
            }
            catch { }
            LoadCatalog();
        }

        private static string LoadFromResources(string path)
        {
            TextAsset jsonAsset = Resources.Load<TextAsset>(path);
            return jsonAsset != null ? jsonAsset.text : null;
        }

        private static string FindDataFilePath(string filename)
        {
            string current = System.IO.Directory.GetCurrentDirectory();
            for (int i = 0; i < 5 && !string.IsNullOrEmpty(current); i++)
            {
                string p = System.IO.Path.Combine(current, "Assets", "Resources", "Data", filename);
                if (System.IO.File.Exists(p)) return p;
                var parent = System.IO.Directory.GetParent(current);
                current = parent?.FullName;
            }

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            for (int i = 0; i < 5 && !string.IsNullOrEmpty(baseDir); i++)
            {
                string p = System.IO.Path.Combine(baseDir, "Assets", "Resources", "Data", filename);
                if (System.IO.File.Exists(p)) return p;
                var parent = System.IO.Directory.GetParent(baseDir);
                baseDir = parent?.FullName;
            }
            return null;
        }

        public static void LoadCatalog()
        {
            _catalog.Clear();
            string jsonText = null;

            try
            {
                jsonText = LoadFromResources("Data/strings");
            }
            catch
            {
                // Standalone test rejimida
            }

            if (string.IsNullOrEmpty(jsonText))
            {
                string path = FindDataFilePath("strings.json");
                if (!string.IsNullOrEmpty(path) && System.IO.File.Exists(path))
                {
                    jsonText = System.IO.File.ReadAllText(path);
                }
            }

            if (string.IsNullOrEmpty(jsonText))
            {
                LogWarning("Strings: strings.json fayli topilmadi!");
                return;
            }

            try
            {
                // Oddiy MiniJSON yoki JsonUtility orqali o'qish
                var root = SimpleJsonParser.Parse(jsonText);
                if (root is Dictionary<string, object> dict)
                {
                    foreach (var langPair in dict)
                    {
                        string lang = langPair.Key;
                        if (langPair.Value is Dictionary<string, object> entries)
                        {
                            var langMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                            foreach (var entry in entries)
                            {
                                langMap[entry.Key] = entry.Value?.ToString() ?? "";
                            }
                            _catalog[lang] = langMap;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.LogError($"Strings: strings.json o'qishda xatolik: {ex.Message}");
            }
        }

        private static void LogWarning(string msg)
        {
            try { Debug.LogWarning(msg); } catch { Console.WriteLine("[WARN] " + msg); }
        }

        private static void LogError(string msg)
        {
            try { Debug.LogError(msg); } catch { Console.WriteLine("[ERR] " + msg); }
        }

        private static void SavePref(string key, string val)
        {
            PlayerPrefs.SetString(key, val);
            PlayerPrefs.Save();
        }

        public static void SetLanguage(string lang)
        {
            if (string.IsNullOrEmpty(lang)) return;
            lang = lang.ToLowerInvariant();
            if (!_catalog.ContainsKey(lang))
            {
                LogWarning($"Strings: Noma'lum til '{lang}', zaxira sifatida 'ru' tanlandi.");
                lang = "ru";
            }

            CurrentLanguage = lang;
            try
            {
                SavePref("selected_language", lang);
            }
            catch
            {
                // Standalone .NET rejimida PlayerPrefs mavjud emas
            }
            OnLanguageChanged?.Invoke();
        }

        public static string T(string key, params object[] args)
        {
            if (string.IsNullOrEmpty(key)) return "";

            string result = null;

            // 1. Joriy tildan qidirish
            if (_catalog.TryGetValue(CurrentLanguage, out var langMap) && langMap.TryGetValue(key, out var val))
            {
                result = val;
            }
            // 2. Rus tili (ru) zaxirasi
            else if (_catalog.TryGetValue("ru", out var ruMap) && ruMap.TryGetValue(key, out var ruVal))
            {
                result = ruVal;
            }
            // 3. Ingliz tili (en) zaxirasi
            else if (_catalog.TryGetValue("en", out var enMap) && enMap.TryGetValue(key, out var enVal))
            {
                result = enVal;
            }
            else
            {
                result = key;
            }

            if (args != null && args.Length > 0)
            {
                try
                {
                    return string.Format(result, args);
                }
                catch
                {
                    return result;
                }
            }

            return result;
        }

        // Ichki sodda JSON lug'at tahlilchisi (qaramliqsiz)
        private static class SimpleJsonParser
        {
            public static object Parse(string json)
            {
                int index = 0;
                return ParseValue(json, ref index);
            }

            private static object ParseValue(string json, ref int index)
            {
                SkipWhitespace(json, ref index);
                if (index >= json.Length) return null;

                char c = json[index];
                if (c == '{') return ParseObject(json, ref index);
                if (c == '"') return ParseString(json, ref index);
                if (char.IsDigit(c) || c == '-') return ParseNumber(json, ref index);
                if (c == 't' || c == 'f') return ParseBool(json, ref index);
                if (c == 'n') return ParseNull(json, ref index);

                return null;
            }

            private static Dictionary<string, object> ParseObject(string json, ref int index)
            {
                var dict = new Dictionary<string, object>();
                index++; // skip '{'

                while (index < json.Length)
                {
                    SkipWhitespace(json, ref index);
                    if (index >= json.Length || json[index] == '}')
                    {
                        index++;
                        break;
                    }

                    string key = ParseString(json, ref index);
                    SkipWhitespace(json, ref index);
                    if (index < json.Length && json[index] == ':') index++;

                    object val = ParseValue(json, ref index);
                    dict[key] = val;

                    SkipWhitespace(json, ref index);
                    if (index < json.Length && json[index] == ',') index++;
                }
                return dict;
            }

            private static string ParseString(string json, ref int index)
            {
                index++; // skip '"'
                int start = index;
                while (index < json.Length && json[index] != '"')
                {
                    if (json[index] == '\\') index++;
                    index++;
                }
                string s = json.Substring(start, index - start);
                if (index < json.Length) index++; // skip closing '"'
                return s;
            }

            private static object ParseNumber(string json, ref int index)
            {
                int start = index;
                while (index < json.Length && (char.IsDigit(json[index]) || json[index] == '.' || json[index] == '-'))
                {
                    index++;
                }
                return json.Substring(start, index - start);
            }

            private static bool ParseBool(string json, ref int index)
            {
                if (json.Substring(index).StartsWith("true")) { index += 4; return true; }
                if (json.Substring(index).StartsWith("false")) { index += 5; return false; }
                return false;
            }

            private static object ParseNull(string json, ref int index)
            {
                if (json.Substring(index).StartsWith("null")) { index += 4; }
                return null;
            }

            private static void SkipWhitespace(string json, ref int index)
            {
                while (index < json.Length && char.IsWhiteSpace(json[index])) index++;
            }
        }
    }
}
