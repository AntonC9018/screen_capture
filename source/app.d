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
            wstring[] names;
        }
        LocalStuff locals;

        static bool func(HWND handle, LocalStuff* locals) 
        {
            if (!IsWindowVisible(handle))
                return true;

            WINDOWINFO windowInfo;
            windowInfo.cbSize = WINDOWINFO.sizeof;

            if (GetWindowInfo(handle, &windowInfo) == 0)
                return true;
            if (windowInfo.dwStyle & WS_POPUP)
                return 1;
            if (!(windowInfo.dwExStyle & WS_EX_OVERLAPPEDWINDOW))
                return 1;

            enum int maxBufferLength = 512;
            wchar[maxBufferLength] textBuffer;
            GetWindowText(handle, textBuffer.ptr, maxBufferLength); 

            import std.string : fromStringz;
            writeln("Inspecting window: ", fromStringz(textBuffer.ptr));

            if (windowInfo.dwExStyle & WS_EX_APPWINDOW)
                writeln(":: Forces Taskbar");

            return true;
        }

        // BOOL EnumWindows(
        //     [in] WNDENUMPROC lpEnumFunc,
        //     [in] LPARAM      lParam
        // );
        EnumWindows(&windowsAdapter!(func, WNDENUMPROC), cast(LPARAM) &locals);

        foreach (wstring str; locals.names)
        {
            writeln(str);
        }
    }
}

/// Does a function that wraps the given function, forwarding all parameters,
/// but mapping them with a cast to the type that the given function expects.
/// In the end you get an adapter function that has the signature of `TTargetType`
/// that forwards to `func`.
template windowsAdapter(alias func, TTargetType)
{
    import std.traits : Parameters, ReturnType;
    alias windowsAdapter = windowsParamsAdapter!(func, ReturnType!TTargetType, Parameters!TTargetType);
}

template windowsParamsAdapter(alias func, TReturnType, TArgumentTypes...)
{
    extern(Windows) TReturnType windowsParamsAdapter(TArgumentTypes args) nothrow
    {
        import std.traits : Parameters;
        import std.array : join;
        import std.conv : text, to;

        alias Params = Parameters!func;
        static assert(Params.length == TArgumentTypes.length);
        
        enum argsString = 
        (){
            string[] result;
            static foreach (index; 0 .. Params.length)
                result ~= text(`cast(Params[`, index, `]) args[`, index, `]`);
            
            return result.join(",");
        }();

        try
        {
            mixin(`return cast(TReturnType) func(`, argsString, `);`);
        }
        catch (Exception exception)
        {
            try writeln(exception);
            catch(Exception exception) {}
        }
        return TReturnType.init;
    }
}
