import std.stdio;
import core.sys.windows.vfw;
import core.sys.windows.winuser;
import core.sys.windows.windows;

import acd.versions : Versions;
mixin Versions;

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
            wc.hbrBackground = cast(HBRUSH) (COLOR_WINDOW + 1);
            wc.lpszClassName = g_szClassName;
            wc.hCursor = LoadCursor(NULL, IDC_ARROW);

            static if (Version.UseMenuResource)
            {
                import resources.menu;
                wc.lpszMenuName = cast(wchar*) IDR_MYMENU;
                wc.hIcon = LoadIcon(hInstance, cast(wchar*) IDI_MYICON);
                wc.hIconSm = LoadImage(hInstance, cast(wchar*) IDI_MYICON, IMAGE_ICON, 16, 16, 0);
            }
            else
            {
                wc.lpszMenuName = NULL;
                wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
                wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);
            }
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

        //  0 = false
        //  1 = true
        // -1 = error
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
    static void DoStuff(HWND hwnd)
    {
        enum maxPathWChar = MAX_PATH / wchar.sizeof;
        wchar[maxPathWChar] szFileName;
        HINSTANCE hInstance = GetModuleHandle(null);
        GetModuleFileName(hInstance, szFileName.ptr, maxPathWChar);
        MessageBox(hwnd, szFileName.ptr, "The program is: "w.ptr, MB_OK | MB_ICONINFORMATION);
    }

    switch (msg)
    {
        static if (Version.DoMenuInCode)
        {
            case WM_CREATE:
            {
                import resources.menu;
                {
                    HMENU hMenu = CreateMenu();
                    {
                        HMENU hSubMenu = CreatePopupMenu();
                        AppendMenu(hSubMenu, MF_STRING, ID_FILE_EXIT, "E&xit");
                        AppendMenu(hMenu, MF_STRING | MF_POPUP, cast(UINT) hSubMenu, "&File");
                    }
                    {
                        HMENU hSubMenu = CreatePopupMenu();
                        AppendMenu(hSubMenu, MF_STRING, ID_STUFF_GO, "&Go");
                        AppendMenu(hMenu, MF_STRING | MF_POPUP, cast(UINT) hSubMenu, "&Stuff");
                    }
                    SetMenu(hwnd, hMenu);
                }

                wstring iconPath = "../resources_test/menu_icon.ico";
                {
                    HICON hIcon = LoadImage(NULL, iconPath.ptr, IMAGE_ICON, 32, 32,
                    LR_LOADFROMFILE);
                    if (hIcon)
                        SendMessage(hwnd, WM_SETICON, ICON_BIG, cast(LPARAM) hIcon);
                    else
                        MessageBox(hwnd, "Could not load large icon!", "Error", MB_OK | MB_ICONERROR);
                }
                {
                    HICON hIconSm = LoadImage(NULL, iconPath.ptr, IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
                    if (hIconSm)
                        SendMessage(hwnd, WM_SETICON, ICON_SMALL, cast(LPARAM) hIconSm);
                    else
                        MessageBox(hwnd, "Could not load small icon!", "Error", MB_OK | MB_ICONERROR);
                }
                break;
            }
        }
        static if (Version.DoMenuInCode || Version.UseMenuResource)
        {
            case WM_COMMAND:
            {
                import resources.menu;
                auto id = LOWORD(wParam);
                switch (id)
                {
                    case ID_HELP_ABOUT:
                    {
                        static extern(Windows) INT_PTR AboutDlgProc(
                            HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
                        {
                            // TRUE means we have processed the message;
                            // FALSE means we don't (like use the default, I guess).
                            switch (message)
                            {
                                case WM_INITDIALOG:
                                    return TRUE;
                                case WM_COMMAND:
                                {
                                    switch (LOWORD(wParam))
                                    {
                                        case IDOK:
                                        {
                                            EndDialog(hwnd, IDOK);
                                            break;
                                        }
                                        case IDCANCEL:
                                        {
                                            EndDialog(hwnd, IDCANCEL);
                                            break;
                                        }
                                        default:
                                            return FALSE;
                                    }
                                    break;
                                }
                                default:
                                    return FALSE;
                            }
                            return TRUE;
                        }

                        const ret = DialogBox(GetModuleHandle(NULL), cast(wchar*) IDD_ABOUT, hwnd, &AboutDlgProc);
                        switch (ret)
                        {
                            case IDOK:
                            {
                                MessageBox(hwnd, "Dialog exited with IDOK.", "Notice",
                                    MB_OK | MB_ICONINFORMATION);
                                break;
                            }
                            case IDCANCEL:
                            {
                                MessageBox(hwnd, "Dialog exited with IDCANCEL.", "Notice",
                                    MB_OK | MB_ICONINFORMATION);
                                break;
                            }
                            case -1:
                            {
                                MessageBox(hwnd, "Dialog failed!", "Error", 
                                    MB_OK | MB_ICONINFORMATION);
                                break;
                            }
                            default:
                                break;
                        }
                        break;
                    }
                    case ID_FILE_EXIT:
                    {
                        PostMessage(hwnd, WM_CLOSE, 0, 0);
                        break;
                    }
                    case ID_STUFF_GO:
                    {
                        DoStuff(hwnd);
                        break;
                    }
                    default: 
                        break;
                }
                break;
            }
        }
        case WM_LBUTTONDOWN:
        case WM_RBUTTONDOWN:
        case WM_MBUTTONDOWN:
        {
            DoStuff(hwnd);
            break;           
        }
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