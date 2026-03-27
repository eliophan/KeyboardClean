param(
  [Parameter(Mandatory = $false)]
  [int]$Seconds = 45
)

if ($Seconds -le 0) {
  Write-Error "Invalid duration: $Seconds (must be a positive integer)."
  exit 2
}

$signature = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class KeyboardLocker
{
    private const int WH_KEYBOARD_LL = 13;
    private const int PM_REMOVE = 0x0001;

    private static IntPtr _hookId = IntPtr.Zero;
    private static LowLevelKeyboardProc _proc = HookCallback;

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int x;
        public int y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public UIntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public POINT pt;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern bool PeekMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax, uint wRemoveMsg);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage([In] ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage([In] ref MSG lpMsg);

    public static bool Start()
    {
        if (_hookId != IntPtr.Zero)
        {
            return true;
        }

        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule)
        {
            IntPtr moduleHandle = GetModuleHandle(curModule.ModuleName);
            _hookId = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, moduleHandle, 0);
        }

        return _hookId != IntPtr.Zero;
    }

    public static void Stop()
    {
        if (_hookId != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_hookId);
            _hookId = IntPtr.Zero;
        }
    }

    public static void Pump()
    {
        MSG msg;
        while (PeekMessage(out msg, IntPtr.Zero, 0, 0, PM_REMOVE))
        {
            TranslateMessage(ref msg);
            DispatchMessage(ref msg);
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            return (IntPtr)1;
        }

        return CallNextHookEx(_hookId, nCode, wParam, lParam);
    }
}
"@

Add-Type -TypeDefinition $signature -Language CSharp

$locked = $false

try {
  if (-not [KeyboardLocker]::Start()) {
    throw "Failed to lock keyboard input."
  }

  $locked = $true
  Write-Output "Keyboard input locked for $Seconds seconds. Start cleaning now."
  Write-Output "Mouse/trackpad stays active."
  Write-Output "Windows mode does not support Esc early unlock while keyboard lock is active."

  $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
  $lastPrinted = $null

  while ([DateTime]::UtcNow -lt $deadline) {
    [KeyboardLocker]::Pump()
    Start-Sleep -Milliseconds 100

    $remaining = [int][Math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalSeconds)
    if ($remaining -gt 0 -and $remaining -ne $lastPrinted -and ($remaining -le 10 -or $remaining % 10 -eq 0)) {
      Write-Output "Remaining: $remaining seconds"
      $lastPrinted = $remaining
    }
  }
}
finally {
  if ($locked) {
    [KeyboardLocker]::Stop()
    Write-Output "Keyboard unlocked."
  }
}
