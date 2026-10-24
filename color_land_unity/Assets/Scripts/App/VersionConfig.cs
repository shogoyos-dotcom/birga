using System;
using System.Text.RegularExpressions;

namespace ColorLand.App
{
    /// <summary>
    /// Markaziy versiya boshqaruvi va doimiy konfiguratsiya (VersionConfig).
    /// Versiya formati: MAJOR.MINOR.PATCH (masalan, "1.00.000").
    /// </summary>
    public static class VersionConfig
    {
        public const string CURRENT_VERSION = "1.00.001";
        public const int CURRENT_VERSION_CODE = 1000001;
        public const string PACKAGE_NAME = "com.shogoyos.colorland3d";
        public const string ENGINE_VERSION = "Unity 6 (6000.6.7f1)";
        public const string TARGET_PLATFORM = "Android ARM64 (IL2CPP)";

        private static readonly Regex VersionRegex = new Regex(@"^(\d+)\.(\d{2})\.(\d{3})$", RegexOptions.Compiled);

        public static bool IsValidVersion(string version)
        {
            if (string.IsNullOrEmpty(version)) return false;
            return VersionRegex.IsMatch(version.Trim());
        }

        public static (int major, int minor, int patch) ParseVersion(string version)
        {
            if (string.IsNullOrEmpty(version))
                throw new ArgumentException("Versiya matni bo'sh bo'lishi mumkin emas.", nameof(version));

            var match = VersionRegex.Match(version.Trim());
            if (!match.Success)
            {
                throw new FormatException($"Noto'g'ri versiya formati: '{version}'. Kutilgan format: 'MAJOR.MINOR.PATCH' (masalan: '1.00.000')");
            }

            int major = int.Parse(match.Groups[1].Value);
            int minor = int.Parse(match.Groups[2].Value);
            int patch = int.Parse(match.Groups[3].Value);

            return (major, minor, patch);
        }

        public static string FormatVersion(int major, int minor, int patch)
        {
            if (major < 0 || minor < 0 || patch < 0)
                throw new ArgumentOutOfRangeException("Versiya komponentlari manfiy bo'lishi mumkin emas.");

            return $"{major}.{minor:D2}.{patch:D3}";
        }

        public static string BumpPatch(string currentVersion)
        {
            var (maj, min, patch) = ParseVersion(currentVersion);
            return FormatVersion(maj, min, patch + 1);
        }

        public static string BumpMinor(string currentVersion)
        {
            var (maj, min, _) = ParseVersion(currentVersion);
            return FormatVersion(maj, min + 1, 0);
        }

        public static string BumpMajor(string currentVersion)
        {
            var (maj, _, _) = ParseVersion(currentVersion);
            return FormatVersion(maj + 1, 0, 0);
        }

        public static string GetAboutDisplay()
        {
            return $"Color Land 3D\nVersion {CURRENT_VERSION}\n{ENGINE_VERSION}\nPlatform: {TARGET_PLATFORM}\n{PACKAGE_NAME}";
        }
    }
}
