import std.stdio;
import win32.vfw;
import win32.winuser;
import win32.windows;


void main()
{
    // Ideally this should buffer, but I don't write much UTF-16, so at this point I don't care.
    static HANDLE hConsole;
    static void writew(const(wchar)[] buffer)
    {
        while (buffer.length > 0)
        {
            DWORD written;
            WriteConsoleW(hConsole, buffer.ptr, cast(DWORD) buffer.length, &written, null);
            buffer = buffer[written .. $];
        }
    }
    hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

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

        while (true)
        {
            goodWindows.length = 0;
            foreachWindow(&CrashOnThrow!foreachFunc);
            
            foreach (size_t index, handle; goodWindows[])
            {   
                enum int maxBufferLength = 512;
                wchar[maxBufferLength] textBuffer;
                GetWindowText(handle, textBuffer.ptr, maxBufferLength); 

                import std.string;
                import std.algorithm;
                import std.utf;

                write(index, ": ");
                writew(fromStringz(textBuffer.ptr));
                writeln();
            }

            enum ShortCircuitInputs
            {
                success = 0, // Returned if the int parsed.
                requery = 1, // Command to requery windows.
                close = 2,   // Close the app.
            }

            alias promptIntInRange = Prompt!(128).intInRange!(ShortCircuitInputs);
            
            const indexInputResult = promptIntInRange(0, cast(int) goodWindows.length - 1);

            final switch (indexInputResult.type)
            {
                case ShortCircuitInputs.success:
                {
                    // writeln("Selected window: ", indexInputResult.value);
                    break;
                }
                case ShortCircuitInputs.close:
                {
                    return;
                }
                case ShortCircuitInputs.requery:
                {
                    continue;
                }
            }
            {
                
                void writeLastError()
                {
                    const errorCode = GetLastError();
                    writeln("Error code: ", errorCode);
                }

                writeLastError();

                // Yeah, this is something totally different.
                auto handle = 
                (){
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

                    LPCWSTR windowName = "Test";
                    auto style = WS_OVERLAPPEDWINDOW;
                    int x = 100;
                    int y = 100;
                    int width = 200;
                    int height = 200;
                    auto parentHandle = goodWindows[indexInputResult.value];
                    int id = 0;

                    return capCreateCaptureWindow(
                        windowName,
                        style,
                        x,
                        y,
                        width,
                        height,
                        parentHandle,
                        id);
                }();

                writeln("Handle: ", handle);
                writeLastError();
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


template Prompt(size_t maxBufferSize)
{
    import std.string;

    static auto tryConvertInputToIntInRange(const(char)[] input, int start, int end)
    {
        static struct Result
        {
            int value;
            bool success;
        }

        int index;

        import std.conv;
        
        try index = input.to!int;
        catch (ConvOverflowException e)
        {
            writeln("Number overflowed. It must be contained within [", start, ", ", end, "].");
            return Result(0, false);
        }
        catch (ConvException e)
        {
            writeln("The given input string is not a number.");
            return Result(0, false);
        }

        if (index < start)
        {
            writeln("The number is too small. It must be contained within [", start, ", ", end, "].");
            return Result(0, false);
        }

        if (index > end)
        {
            writeln("The number is too large. It must be contained within [", start, ", ", end, "].");
            return Result(0, false);
        }

        return Result(index, true);
    }

    char[] getMeaningfulUserInput(char[] buffer)
    {
        while (true)
        {
            char[] input = buffer;
            readln(input);
            input = input.strip();
            if (input.length > 0)
                return input;
        }
    }

    auto intInRange(ShortCircuitInputEnum, ShortCircuitInputEnum successMember = ShortCircuitInputEnum.success)
        (int start, int end)
    {
        static struct Result
        {
            int value;
            ShortCircuitInputEnum type;
        }
        // static assert(is(typeof(ShortCircuitInputEnum) == enum));
        do
        {
            char[maxBufferSize] buffer;
            char[] input = getMeaningfulUserInput(buffer[]);

            static foreach (field; __traits(allMembers, ShortCircuitInputEnum))
            {
                static if (__traits(getMember, ShortCircuitInputEnum, field) != successMember)
                if (input == field)
                {
                    return Result(0, __traits(getMember, ShortCircuitInputEnum, field));
                }
            }

            const result = tryConvertInputToIntInRange(input, start, end);
            if (result.success)
                return Result(result.value, successMember);
        }
        while (true);
    }

    int intInRange(int start, int end)
    {
        do
        {
            char[maxBufferSize] buffer;
            char[] input = getMeaningfulUserInput(buffer[]);
            const result = tryConvertInputToIntInRange(input, start, end);
            if (result.success)
                return result.value;
        }
        while (true);
    }
}
