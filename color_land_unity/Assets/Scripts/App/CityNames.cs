using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.App
{
    /// <summary>
    /// Shahar nomlarini 15 tilda mahalliylashtirish (CityNames).
    /// city_names.json faylidan tanlangan tilga mos tarjimani qaytaradi.
    /// Rus tili tanlanganda: "Tashkent" -> "Ташкент", "Port Sudan" -> "Порт-Судан".
    /// </summary>
    public static class CityNames
    {
        private static readonly Dictionary<string, Dictionary<string, string>> _tables =
            new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);

        private static bool _loaded = false;

        static CityNames()
        {
            LoadData();
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

        public static void LoadData()
        {
            _tables.Clear();
            string jsonText = null;

            try
            {
                TextAsset asset = Resources.Load<TextAsset>("Data/city_names");
                if (asset != null) jsonText = asset.text;
            }
            catch
            {
                // Standalone test
            }

            if (string.IsNullOrEmpty(jsonText))
            {
                string path = FindDataFilePath("city_names.json");
                if (!string.IsNullOrEmpty(path) && System.IO.File.Exists(path))
                {
                    jsonText = System.IO.File.ReadAllText(path);
                }
            }

            if (string.IsNullOrEmpty(jsonText))
            {
                _loaded = true;
                return;
            }

            try
            {
                var root = MiniJson.Deserialize(jsonText) as Dictionary<string, object>;
                if (root != null)
                {
                    foreach (var langPair in root)
                    {
                        string lang = langPair.Key;
                        if (langPair.Value is Dictionary<string, object> dict)
                        {
                            var map = new Dictionary<string, string>(dict.Count, StringComparer.OrdinalIgnoreCase);
                            foreach (var entry in dict)
                            {
                                map[entry.Key] = entry.Value?.ToString() ?? entry.Key;
                            }
                            _tables[lang] = map;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"CityNames yuklashda xatolik: {ex.Message}");
            }

            _loaded = true;
        }

        public static string GetName(string englishName)
        {
            if (string.IsNullOrEmpty(englishName)) return "";
            if (!_loaded) LoadData();

            string lang = Strings.CurrentLanguage ?? "ru";

            if (_tables.TryGetValue(lang, out var map) && map.TryGetValue(englishName, out var localized))
            {
                return localized;
            }

            // Agar joriy tilda topilmasa, lekin inglizchadan farq qilmasa yoki yo'q bo'lsa
            return englishName;
        }

        // Mini JSON Parser
        private static class MiniJson
        {
            public static object Deserialize(string json)
            {
                if (string.IsNullOrEmpty(json)) return null;
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
                    if (index >= json.Length) break;
                    if (json[index] == '}') { index++; break; }

                    if (json[index] == ',') { index++; continue; }

                    string key = ParseString(json, ref index);
                    SkipWhitespace(json, ref index);
                    if (index < json.Length && json[index] == ':') index++;

                    object val = ParseValue(json, ref index);
                    if (key != null) dict[key] = val;
                }
                return dict;
            }

            private static string ParseString(string json, ref int index)
            {
                if (index >= json.Length || json[index] != '"') return null;
                index++; // skip '"'
                int start = index;
                var sb = new System.Text.StringBuilder();

                while (index < json.Length)
                {
                    char c = json[index++];
                    if (c == '"') return sb.ToString();
                    if (c == '\\' && index < json.Length)
                    {
                        char escaped = json[index++];
                        if (escaped == '"') sb.Append('"');
                        else if (escaped == '\\') sb.Append('\\');
                        else if (escaped == '/') sb.Append('/');
                        else if (escaped == 'b') sb.Append('\b');
                        else if (escaped == 'f') sb.Append('\f');
                        else if (escaped == 'n') sb.Append('\n');
                        else if (escaped == 'r') sb.Append('\r');
                        else if (escaped == 't') sb.Append('\t');
                        else if (escaped == 'u' && index + 4 <= json.Length)
                        {
                            string hex = json.Substring(index, 4);
                            index += 4;
                            sb.Append((char)Convert.ToInt32(hex, 16));
                        }
                    }
                    else
                    {
                        sb.Append(c);
                    }
                }
                return sb.ToString();
            }

            private static object ParseNumber(string json, ref int index)
            {
                int start = index;
                while (index < json.Length && (char.IsDigit(json[index]) || json[index] == '.' || json[index] == '-' || json[index] == '+' || json[index] == 'e' || json[index] == 'E'))
                {
                    index++;
                }
                string numStr = json.Substring(start, index - start);
                if (long.TryParse(numStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out long lVal)) return lVal;
                if (double.TryParse(numStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double dVal)) return dVal;
                return 0;
            }

            private static bool ParseBool(string json, ref int index)
            {
                if (json.Substring(index).StartsWith("true", StringComparison.OrdinalIgnoreCase)) { index += 4; return true; }
                if (json.Substring(index).StartsWith("false", StringComparison.OrdinalIgnoreCase)) { index += 5; return false; }
                return false;
            }

            private static object ParseNull(string json, ref int index)
            {
                if (json.Substring(index).StartsWith("null", StringComparison.OrdinalIgnoreCase)) { index += 4; }
                return null;
            }

            private static void SkipWhitespace(string json, ref int index)
            {
                while (index < json.Length && char.IsWhiteSpace(json[index])) index++;
            }
        }
    }
}
