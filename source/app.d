import std.stdio;
import win32.vfw;
import win32.winuser;
import win32.windows;


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
    //     const style = 
    //     const desktopWindow = GetDesktopWindow();
    //     const 
    //     return capCreateCaptureWindowA(
    //         windowName,
    //         style);
    // }();


    {
        HWND[] goodWindows;

        BOOL foreachFunc(HWND handle)
        {
            if (!IsWindowVisible(handle))
                return 1;

            WINDOWINFO windowInfo;
            windowInfo.cbSize = WINDOWINFO.sizeof;

            if (GetWindowInfo(handle, &windowInfo) == 0)
                return 1;
            if (windowInfo.dwStyle & WS_POPUP)
                return 1;
            if (!(windowInfo.dwExStyle & WS_EX_OVERLAPPEDWINDOW))
                return 1;

            goodWindows ~= handle;
            return 1;
        }

        foreachWindow(&CrashOnThrow!foreachFunc);


        {
            foreach (handle; goodWindows)
            {   
                enum int maxBufferLength = 512;
                wchar[maxBufferLength] textBuffer;
                GetWindowText(handle, textBuffer.ptr, maxBufferLength); 

                import std.string : fromStringz;
                writeln("Inspecting window: ", fromStringz(textBuffer.ptr));
            }
        }
    }
}


template CrashOnThrow(alias func)
{
    import std.traits : Parameters;

    auto CrashOnThrow(Parameters!func things) nothrow
    {
        try return func(things);
        catch (Exception e)
        {
            try writeln(e);
            catch (Exception e1)
            {
                import core.stdc.stdlib;
                exit(-1);
            }
            return typeof(func(things)).init;
        }
    }
}

BOOL foreachWindow(scope BOOL delegate(HWND) nothrow func)
{
    static struct CallbackContext
    {
        BOOL delegate(HWND) nothrow callback;
    }
    extern(Windows) static BOOL wrapper(HWND handle, LPARAM param) nothrow
    {
        return (cast(CallbackContext*) param).callback(handle);
    }

    auto context = CallbackContext(func);
    // BOOL EnumWindows(
    //     [in] WNDENUMPROC lpEnumFunc,
    //     [in] LPARAM      lParam
    // );
    return EnumWindows(&wrapper, cast(LPARAM) &context);
}
