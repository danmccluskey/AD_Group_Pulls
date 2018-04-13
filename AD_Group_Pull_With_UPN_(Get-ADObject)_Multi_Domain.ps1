#Importing the AD Module
Import-Module ActiveDirectory

<#
Declaring the following variables as empty arrays (necessary to support the powershell array invocation 'op_Addition').  More details here:
https://gallery.technet.microsoft.com/scriptcenter/An-Array-of-PowerShell-069c30aa
#>
$DomainList = @("MGT.Group.zone","office.ad.netbenefit.com","dev.group.zone","prd.group.zone")

#Defining ingestion of initial data
$List = @("PRD Domain Admin","Domain Admins")

#Beginning Group List Iteration
ForEach ($Domain in $DomainList)
{

Switch ($Domain)
{
"CSCInfo.com" {$DomainCN = "DC=CSCInfo,DC=com"}
"Taxtech.com" {$DomainCN = "DC=Taxtech,DC=com"}
"prd.group.zone" {$DomainCN = "DC=PRD,DC=Group,DC=Zone"}
"dev.group.zone" {$DomainCN = "DC=DEV,DC=Group,DC=Zone"}
"office.ad.netbenefit.com" {$DomainCN = "DC=Office,DC=AD,DC=Netbenefit,DC=com"}
}

$SearchBase = "CN=ForeignSecurityPrincipals,$DomainCN"

ForEach ($Item in $List) {

    #Definining Variable for pulling Members of each Item in $List
    $ADGroupPull = $Null
    $TotalList = @()
    $ADGroupPull = (Get-ADGroup $Item -Server $Domain -Properties Member -ErrorAction Continue).Member

    #Defining second Foreach that will iterate through individual group member objects.  Note that this is not the same as a user object.
    if ($ADGroupPull) {
    $ADGroupPull | Foreach {
        $TranslateRN = $Null
        $CollProps = @()
        $Translation = [regex]::matches($_,'(?<=\=).+?(?=\,)')[0].Value
        $ADOFilter = "Name -eq `"$Translation`""

        if ($_ -like '*foreignsecurity*')
        {
        $TranslateRN = ([System.Security.Principal.SecurityIdentifier] $Translation).Translate([System.Security.Principal.NTAccount])
        }
        
        $NamePull = (Get-ADObject -filter $ADOFilter -Server $Domain -Properties Name, ObjectClass, objectSID, SAMAccountName, UserPrincipalName, whenCreated)
        
        <#
        Here we're creating a reusable custom object in Powershell, which is fed data through a loop.  This data is overwritten with each "Foreach" cycle, 
        so we need to be sure we output the data before the next cycle...

        Some "light reading": https://kevinmarquette.github.io/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/
        #>

        $CollProps = [pscustomobject][ordered]@{
        'Group Name' = $Item;
        'Full Name' = $NamePull.Name;
        'Object Class' = $NamePull.objectClass;
        'Domain' = $Domain;
        'SAM' = $NamePull.SamAccountName
        'UPN' = $NamePull.userprincipalname;
        'Translated Name' = $TranslateRN;
        }
        
        #...and we accomplish that in the following line, effectively ejecting the data into a brand new, empty array waiting for the data.    
        
        $TotalList += $CollProps
        

        }
        }

        #Don't forget quotes when defining a path as a variable.
        $Result = "C:\Temp\$Domain" + "_" + "$Item.CSV"
        if ($TotalList -ne '')
        {
        $TotalList | Export-CSV $Result -Force 
        }
            
        }
    }

