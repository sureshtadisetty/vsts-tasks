[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Target)

# This script translates the output from robocopy into UTF8.
#
# Node has limited support for encodings, and robocopy writes output using the
# default console-output code page. For example, on an en-US box, this is code
# page '437', which nodejs does not support.
#
# On an en-US box, testing with the 'ç' character is a good way to determine
# whether the data is passed correctly between processes. This is because the
# 'ç' character has a different code point across each of the common encodings
# on an en-US box:
#   1) the system default code page (i.e. CP_ACP) (Windows-1252)
#   2) the default console-output code page (IBM437)
#   3) UTF8

$ErrorActionPreference = 'Stop'

# Redefine the wrapper over STDOUT to use UTF8. Node expects UTF8 by default.
$stdout = [System.Console]::OpenStandardOutput()
$utf8 = [System.Text.Encoding]::UTF8
$writer = New-Object System.IO.StreamWriter($stdout, $utf8)
[System.Console]::SetOut($writer)

# Print the ##command.
"##[command]robocopy.exe /E /COPY:DAT /XA:H /NP /R:3 `"$Source`" `"$Target`" *"

# Robocopy writes output using the default console-output code page. Powershell
# by default expects external commands to use the default console-output code page.
& robocopy.exe /E /COPY:DAT /XA:H /NP /R:3 $Source $Target *
"##[debug]exit code '$LASTEXITCODE'"
if ($LASTEXITCODE -ge 8) {
    exit $LASTEXITCODE
}