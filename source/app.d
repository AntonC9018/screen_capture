import std.stdio;
import core.sys.windows.vfw;
import core.sys.windows.winuser;
import core.sys.windows.windows;

// extern (Windows) int WinMain(
//     HINSTANCE hInstance,
//     HINSTANCE hPrevInstance,
//     LPSTR lpCmdLine,
//     int nCmdShow)
// {
//     MessageBox(NULL, "Goodbye, cruel world!", "Note", MB_OK);
//     return 0;
// }

extern(Windows) int WinMain(
    HINSTANCE hInstance,
    HINSTANCE,
    LPSTR,
    int nCmdShow)
{
    enum g_szClassName = "myWindowClass";

    //Step 1: Registering the Window Class
    {
        WNDCLASSEX wc;
        {
            wc.cbSize = WNDCLASSEX.sizeof;
            wc.style = 0;
            wc.lpfnWndProc = &WndProc;
            wc.cbClsExtra = 0;
            wc.cbWndExtra = 0;
            wc.hInstance = hInstance;
            wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
            wc.hCursor = LoadCursor(NULL, IDC_ARROW);
            wc.hbrBackground = cast(HBRUSH) (COLOR_WINDOW + 1);
            wc.lpszMenuName = NULL;
            wc.lpszClassName = g_szClassName;
            wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);
        }

        if (!RegisterClassEx(&wc))
        {
            MessageBox(NULL, "Window Registration Failed!", "Error!",
                MB_ICONEXCLAMATION | MB_OK);
            return 0;
        }
    }

    // Step 2: Creating the Window
    {
        HWND hwnd = 
        (){
            // HWND CreateWindowExW(
            //     [in]           DWORD     dwExStyle,
            //     [in, optional] LPCWSTR   lpClassName,
            //     [in, optional] LPCWSTR   lpWindowName,
            //     [in]           DWORD     dwStyle,
            //     [in]           int       X,
            //     [in]           int       Y,
            //     [in]           int       nWidth,
            //     [in]           int       nHeight,
            //     [in, optional] HWND      hWndParent,
            //     [in, optional] HMENU     hMenu,
            //     [in, optional] HINSTANCE hInstance,
            //     [in, optional] LPVOID    lpParam);

            DWORD     dwExStyle    = WS_EX_CLIENTEDGE;
            LPCWSTR   lpClassName  = g_szClassName;
            LPCWSTR   lpWindowName = "The title of my window";
            DWORD     dwStyle      = WS_OVERLAPPEDWINDOW;
            int       X            = CW_USEDEFAULT;
            int       Y            = CW_USEDEFAULT;
            int       nWidth       = 240;
            int       nHeight      = 120;
            HWND      hWndParent   = null;
            HMENU     hMenu        = null;
            HINSTANCE hInstance    = hInstance;
            LPVOID    lpParam      = null;

            auto result = CreateWindowEx(
                dwExStyle,
                lpClassName,
                lpWindowName,
                dwStyle,
                X,
                Y,
                nWidth,
                nHeight,
                hWndParent,
                hMenu,
                hInstance,
                lpParam);

            return result;
        }();

        if (hwnd is null)
        {
            MessageBox(null, "Window Creation Failed!", "Error!",
                MB_ICONEXCLAMATION | MB_OK);
            return 0;
        }
        ShowWindow(hwnd, nCmdShow);
        UpdateWindow(hwnd);
    }
 
    // Step 3: The Message Loop
    {
        MSG msg;
        uint filterMin = 0; 
        uint filterMax = 0; 
        while (GetMessage(&msg, null, filterMin, filterMax) > 0)
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        return cast(int) msg.wParam;
    }
}

// Step 4: the Window Procedure
extern(Windows) LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) nothrow
{
    switch (msg)
    {
        case WM_CLOSE: 
            DestroyWindow(hwnd);
            break;
        case WM_DESTROY: 
            PostQuitMessage(0);
            break;
        default: 
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}