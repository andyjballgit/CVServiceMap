#
# GenerateReadMe.ps1
#
Import-Module $PSScriptRoot\..\CVServiceMapAPI.psm1 -Force -verbose -Debug
Get-CVMarkDownFileForCmdLets -Module CVServiceMapAPI -OutputFileName "$PSScriptRoot\..\ReadMe.md" -ReadMeMarkdownHeaderFileName "$PSScriptRoot\..\ReadMeHeader.md" -Verbose