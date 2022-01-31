using System.Diagnostics;

string root = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)!;
string exeFile = Path.Combine(root, "Telegram.exe");
if (!File.Exists(exeFile))
{
    throw new Exception("Place this program alongside Telegram.exe!");
}

string backupFileName = "Telegram.bak";
try
{
    var info = FileVersionInfo.GetVersionInfo(exeFile);
    var ver = string.Format("{0}.{1}.{2}.{3}", info.FileMajorPart, info.FileMinorPart, info.FileBuildPart, info.FilePrivatePart);
    backupFileName = "Telegram." + ver + ".bak";
} catch { }
string backupFile = Path.Combine(root, backupFileName);

string inputFile = exeFile;
string outputFile = exeFile;
if (File.Exists(backupFile))
{
    inputFile = backupFile;
}

Console.WriteLine("Input: {0}", inputFile);
Console.WriteLine("Backup: {0}", backupFile);
Console.WriteLine("Output: {0}", outputFile);

var bytes = File.ReadAllBytes(inputFile);

if (inputFile != backupFile)
{
    File.Copy(inputFile, backupFile, true);
}

var config = new Config()
{
    RedirectFont = true,
};

if (!string.IsNullOrEmpty(config.ProductName) && config.ProductName != "Telegram")
{
    ReplaceUnicode(bytes, "Telegram", config.ProductName);
    ReplaceUnicode(bytes, "Telegram Desktop", config.ProductName + " Desktop");
    ReplaceUnicode(bytes, "Telegram (%1)", config.ProductName + " (%1)");
}

if (config.RedirectFont) ReplaceUTF8(bytes, ":/gui/fonts/", "./gui/fonts/");
if (config.RedirectLogo) ReplaceUnicode(bytes, ":/gui/art/logo_256.png", "./gui/art/logo_256.png");
if (config.RedirectLogoNoMargin) ReplaceUnicode(bytes, ":/gui/art/logo_256_no_margin.png", "./gui/art/logo_256_no_margin.png");

File.WriteAllBytes(outputFile, bytes);

void ReplaceUTF8(byte[] bytes, string find, string replace)
{
    if (replace.Length > find.Length) throw new ArgumentOutOfRangeException("replace", "replace is too long");

    var f = System.Text.Encoding.UTF8.GetBytes(find);
    Array.Resize(ref f, f.Length + 2);
    var r = System.Text.Encoding.UTF8.GetBytes(replace);
    if (r.Length > f.Length - 2) throw new ArgumentOutOfRangeException("replace", "replace is too long");
    Array.Resize(ref r, f.Length);

    Console.WriteLine("Replace \"{0}\" -> \"{1}\" ({2} -> {3})", find, replace, BitConverter.ToString(f), BitConverter.ToString(r));
    var p = new BoyerMoore(f);
    foreach (var pos in p.SearchAll(bytes))
    {
        Console.WriteLine("  Found @{0:X8}", pos);
        Array.Copy(r, 0, bytes, pos, r.Length);
    }
}

void ReplaceUnicode(byte[] bytes, string find, string replace)
{
    if (replace.Length > find.Length) throw new ArgumentOutOfRangeException("replace", "replace is too long");

    var f = System.Text.Encoding.Unicode.GetBytes(find);
    Array.Resize(ref f, f.Length + 4);
    var r = System.Text.Encoding.Unicode.GetBytes(replace);
    if (r.Length > f.Length - 4) throw new ArgumentOutOfRangeException("replace", "replace is too long");
    Array.Resize(ref r, f.Length);

    Console.WriteLine("Replace \"{0}\" -> \"{1}\" ({2} -> {3})", find, replace, BitConverter.ToString(f), BitConverter.ToString(r));
    var p = new BoyerMoore(f);
    foreach(var pos in p.SearchAll(bytes))
    {
        Console.WriteLine("  Found @{0:X8}", pos);
        Array.Copy(r, 0, bytes, pos, r.Length);
    }
}

class Config
{
    public string? ProductName { get; set; }
    public bool RedirectFont { get; set; }
    public bool RedirectLogo { get; set; }
    public bool RedirectLogoNoMargin { get; set; }
}