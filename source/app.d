import std.stdio;
import win32.vfw;
import win32.winuser;

void main()
{
    // HWND VFWAPI capCreateCaptureWindowA(
    //     LPCSTR lpszWindowName,
    //     DWORD  dwStyle,
    //     int    x,
    //     int    y,
    //     int    nWidth,
    //     int    nHeight,
    //     HWND   hwndParent,
    //     int    nID
    // );

    // auto handle = {
    //     const windowName = "Test";
    //     const style
    //     return capCreateCaptureWindowA("Test", );
    // }();

    auto desktopWindow = GetDesktopWindow();
    writeln(desktopWindow);
}