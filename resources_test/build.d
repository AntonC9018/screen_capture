int main()
{
    import std.process;
    import std.path;
    import std.stdio;

    const WINDOWS_KITS_PATH = `C:\Program Files (x86)\Windows Kits\10`;
    const WINDOWS_KIT_VERSION = `10.0.19041.0`;

    const rcPath      = buildPath(WINDOWS_KITS_PATH, `bin`, WINDOWS_KIT_VERSION, `x64\rc.exe`);
    const includePath = buildPath(WINDOWS_KITS_PATH, `Include`, WINDOWS_KIT_VERSION);

    auto pid = spawnProcess([
        rcPath,
        "/r",
        "/i", buildPath(includePath, "um"),
        "/i", buildPath(includePath, "shared"),
        "menu.rc"
    ]);

    return wait(pid);
}
