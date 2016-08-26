[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Target)

# This script translates the output from robocopy into UTF8. Node has limited
# built-in support for encodings.
#
# Robocopy uses the system default code page (CP_ACP). The system default code
# page varies depending on the locale configuration. On an en-US box, the system
# default code page is Windows-1252.
#
# Note, on a typical en-US box, testing with the 'ç' character is a good way to
# determine whether data is passed correctly between processes. This is because
# the 'ç' character has a different code point across each of the common encodings
# on a typical en-US box, i.e.
#   1) the default console-output code page (IBM437)
#   2) the system default code page (i.e. CP_ACP) (Windows-1252)
#   3) UTF8

$ErrorActionPreference = 'Stop'

# Redefine the wrapper over STDOUT to use UTF8. Node expects UTF8 by default.
$stdout = [System.Console]::OpenStandardOutput()
$utf8 = New-Object System.Text.UTF8Encoding($false) # do not emit BOM
$writer = New-Object System.IO.StreamWriter($stdout, $utf8)
[System.Console]::SetOut($writer)

# Print the ##command.
"##[command]robocopy.exe /E /COPY:DAT /XA:H /NP /R:3 `"$Source`" `"$Target`" *"

# The $OutputEncoding variable (defaults to the system default code page) instructs
# PowerShell how to interpret output from an external command.
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
"##[debug]robocopy exit code '$LASTEXITCODE'"
if ($LASTEXITCODE -ge 8) {
    exit $LASTEXITCODE
}