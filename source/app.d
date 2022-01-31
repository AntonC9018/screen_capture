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
        static struct LocalStuff
        {
            HWND[] goodWindows;
        }
        LocalStuff locals;

        // BOOL EnumWindows(
        //     [in] WNDENUMPROC lpEnumFunc,
        //     [in] LPARAM      lParam
        // );

        locals.foreachWindow!((handle, locals) 
        {
            if (!IsWindowVisible(handle))
                return true;

            WINDOWINFO windowInfo;
            windowInfo.cbSize = WINDOWINFO.sizeof;

            if (GetWindowInfo(handle, &windowInfo) == 0)
                return true;
            if (windowInfo.dwStyle & WS_POPUP)
                return true;
            if (!(windowInfo.dwExStyle & WS_EX_OVERLAPPEDWINDOW))
                return true;

            locals.goodWindows ~= handle;
            return true;
        });
        // EnumWindows(&windowsAdapter!(, WNDENUMPROC), cast(LPARAM) &locals);


        {
            foreach (handle; locals.goodWindows)
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


BOOL foreachWindow(alias func, T)(ref T context)
{
    import std.traits : Parameters, ReturnType;

    extern(Windows) static BOOL wrapper(HWND handle, LPARAM param) nothrow
    {
        try return func(handle, cast(T*) param);
        catch(Exception e) 
        {
            try writeln(e);
            catch (Exception e2){}
            return 0;
        }
    }
    return EnumWindows(&wrapper, cast(LPARAM) &context);
}
