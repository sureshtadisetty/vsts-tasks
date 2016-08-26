[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Target)

# This script translates the output from robocopy into UTF8.
#
# Robocopy does not respect the active console output code page for a process
# (set using chcp.com) and instead appears to always follow the higher level
# global setting. For example, on an en-US box, this would be the code page '437'.
#
# Node has limited built-in support for encodings. For example, does not support
# code page 437.
#
# On an en-US box, testing with the 'ç' character is a good way to determine
# whether data is passed correctly between processes. This is because the
# 'ç' character has a different code point across each of the common encodings
# on an en-US box:
#   1) the system default code page (i.e. CP_ACP) (Windows-1252)
#   2) the default console-output code page (IBM437)
#   3) UTF8

$ErrorActionPreference = 'Stop'

# Redefine the wrapper over STDOUT to use UTF8. Node expects UTF8 by default.
$stdout = [System.Console]::OpenStandardOutput()
$utf8 = New-Object System.Text.UTF8Encoding($false) # do not emit BOM
$writer = New-Object System.IO.StreamWriter($stdout, $utf8)
[System.Console]::SetOut($writer)

# Print the ##command.
"##[command]robocopy.exe /E /COPY:DAT /XA:H /NP /R:3 `"$Source`" `"$Target`" *"

# Robocopy writes output using the default console-output code page. PowerShell
# by default expects external commands to use the default console-output code page.
#
# The output from robocopy needs to be iterated over. Otherwise PowerShell.exe
# will launch the external command in such a way that it inherits the streams.
& robocopy.exe /E /COPY:DAT /XA:H /NP /R:3 $Source $Target * 2>&1 |
    ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            $_.Exception.Message
        }
        else {
            $_
        }
    }
"##[debug]exit code '$LASTEXITCODE'"
if ($LASTEXITCODE -ge 8) {
    exit $LASTEXITCODE
}