param(
  [Parameter(Mandatory = $false)]
  [int]$Seconds = 45
)

if ($Seconds -le 0) {
  Write-Error "Invalid duration: $Seconds (must be a positive integer)."
  exit 2
}

$signature = @"
using System.Runtime.InteropServices;

public static class InputBlocker
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool BlockInput(bool fBlockIt);
}
"@

Add-Type -TypeDefinition $signature -Language CSharp

$locked = $false

try {
  if (-not [InputBlocker]::BlockInput($true)) {
    throw "Failed to lock input. Try running the terminal as Administrator."
  }

  $locked = $true
  Write-Output "Keyboard and mouse input locked for $Seconds seconds. Start cleaning now."
  Write-Output "Windows mode does not support Esc early unlock while input is blocked."

  for ($remaining = $Seconds; $remaining -gt 0; $remaining--) {
    Start-Sleep -Seconds 1
    $next = $remaining - 1

    if ($next -gt 0 -and ($next -le 10 -or $next % 10 -eq 0)) {
      Write-Output "Remaining: $next seconds"
    }
  }
}
finally {
  if ($locked) {
    [void][InputBlocker]::BlockInput($false)
    Write-Output "Input unlocked."
  }
}
