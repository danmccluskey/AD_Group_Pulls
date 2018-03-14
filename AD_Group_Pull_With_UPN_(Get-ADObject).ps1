#Importing the AD Module
Import-Module ActiveDirectory

<#
Declaring the following variables as empty arrays (necessary to support the powershell array invocation 'op_Addition').  More details here:
https://gallery.technet.microsoft.com/scriptcenter/An-Array-of-PowerShell-069c30aa
#>
$CollProps = @()

#Defining ingestion of initial data
$List = Get-Content C:\Temp\Test.csv

#Beginning Group List Iteration
ForEach ($Item in $List) {

    #Definining Variable for pulling Members of each Item in $List
    $TotalList = @()
    $ADGroupPull = Get-ADGroupMember $Item
    
    #Defining second Foreach that will iterate through individual users
    $ADGroupPull | Foreach {
        
        <#
        You'll notice that the cmdlet breaks some traditional rules in Powershell, namely that single-quotes are literal strings rather than normal strings.
        Reading: https://docs.microsoft.com/en-us/powershell/module/addsadministration/get-adobject?view=win10-ps 
        #>
        $NamePull = Get-ADObject -Filter 'SamAccountName -eq $_.SamAccountName' -Properties Name, ObjectClass, SamAccountName, UserPrincipalName

        <#
        Here we're creating a reusable custom object in Powershell, which is fed data through the loop.  This data is overwritten with each "Foreach" cycle, 
        so we need to be sure we output the data before the next cycle...

        Some "light reading": https://kevinmarquette.github.io/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/
        #>
        $CollProps = [pscustomobject][ordered]@{
        'Group Name' = $Item;
        'Full Name' = $NamePull.Name;
        'Object Class' = $NamePull.objectClass;
        'SAM' = $NamePull.SamAccountName
        'UPN' = $NamePull.userprincipalname;
        }
    
        #...and we accomplish that in the following line, effectively injecting the data into a brand new, empty array waiting for the data.    
        $TotalList += $CollProps

        #Don't forget quotes when defining a path as a variable.
        $Result = "C:\Temp\$Item.CSV"
        $TotalList | Export-CSV $Result -Force 
    }
}
