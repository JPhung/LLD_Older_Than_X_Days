#======================================================================
#Script Name: LLD_Older_Than_X_Days.ps1
#Script Author: Phung, John
#Script Purpose: Get diabled machine names that have a LastLogonDate value of -30, -60, -90 or -120 days
#Script Creation Date:	08/16/2019
#Script Last Modified Date:	08/26/2019
#Script Notes: 
#======================================================================

#Import Necessary PS Modules
Import-Module ActiveDirectory

#Set Server (Domain) variables
$Script:server01 = "Domain/Server"
$Script:server02 = "Domain/Server"

#get cut-off days function, prompt for range to go back from today's date
function getCutOffChoice
{
    $Script:cutOffChoice = 0
    Write-Host "`nHow far back do you want to scan?"
    Write-Host "Choose an option:"
    Write-Host "1. 30 days"
    Write-Host "2. 60 days"
    Write-Host "3. 90 days"
    Write-Host "4. 120 days"
    Write-Host ""
    $Script:cutOffChoice = Read-Host
    
    Switch ( $Script:cutOffChoice ){
        1{$Script:daysCutOff = "-30"}
        2{$Script:daysCutOff = "-60"}
        3{$Script:daysCutOff = "-90"}
        4{$Script:daysCutOff = "-120"}
        default {Write-Host "`nTry again";getCutOffChoice}
    }
}

#get cut-off date function, calculate the exact cut-off date
function getCutoffDate
{
    $script:dateCutOff = (Get-Date).AddDays($Script:daysCutOff)
    Write-Host "`nCutoff Date: $script:dateCutOff"
}

#end script function, prompt do PS window doesn't immediately close on script completion
function endScript
{
    Write-Host "`nResults were saved to $Script:outputFilePath\$Script:outputFileName`n"
    pause
    exit
}

#set CSV output path function
function setOutputPath
{
    $Script:outputFilePath = "UNC PATH"
    $Script:outputFileDate = Get-Date -UFormat "%Y.%m.%d"
    $script:dateCutOff = get-date $script:dateCutOff -UFormat %Y.%m.%d
    $Script:outputFileName = "$OutputFileDate - LLD Older Than $script:dateCutOff ($Script:daysCutOff days).csv"
}

#get machine LastLogonDate attribute from AD, search AD for disabled computer object and determine the last logon date value
function getMachineLLD
{
    $script:machineLLD = Get-ADcomputer $script:computerName -Properties LastLogonDate | Select-Object LastLogonDate -ExpandProperty LastLogonDate | get-date -UFormat %Y.%m.%d
    if ($script:machineLLD) 
    {
        $script:machineLLD = get-date $script:machineLLD -UFormat %Y.%m.%d
    }
    else 
    {
        $script:machineLLD = Get-Date -UFormat "%Y.%m.%d"
    }
}

#compare machine LLD with cutoff date, if cut off date is greater than machine LLD, export details to CSV
function compareDates
{
    if ($script:dateCutOff -ge $script:machineLLD)
    {
    Get-ADComputer $script:computerName -Properties * | Select-Object name,LastLogonDate,@{Name='OU'; Expression={($_.DistinguishedName -split ',', 2)[1]}} | Export-Csv -Path $Script:outputFilePath"\"$Script:outputFileName -NoTypeInformation -Append
    }
}

#scan each domain for disabled computer objects and run listed functions for each
function scanByDomain
{
    $Script:computers = Get-ADComputer -Filter {(Enabled -eq $False)} -Server $Script:server
    foreach($script:computerName in $Script:computers) 
        {
            getMachineLLD
            compareDates
        }
}

# get days to go back from
getCutoffChoice

# calculate cut off date
getCutoffDate

# set output file path and file name
setOutputPath

# server/domain01
$Script:server = $Script:server01
scanByDomain

# server/domain02
$Script:server = $Script:server02
scanByDomain

endScript