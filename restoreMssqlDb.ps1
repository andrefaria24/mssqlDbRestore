Param
(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$server,
    [Parameter(Mandatory=$true,Position=2)]
    [string]$dbname,
    [Parameter(Mandatory=$true,Position=3)]
    [string]$backup
)

#Set time and current path variables
$currentTimeAbr = Get-Date -Format yyyMMdd
$currentPath = (Get-Location).path

#Info logging function
function infoOutput($message)
{
    $currentTime = Get-Date -Format g
    Write-Host $message
    Write-Output "$currentTime`tINF`t$message" >> $currentPath\$currentTimeAbr"restore.log"
}

function warningOutput($message)
{
    $currentTime = Get-Date -Format g
    Write-Host $message
    Write-Output "$currentTime`tWAR`t$message" >> $currentPath\$currentTimeAbr"restore.log"
}

#Error logging function
function errorOutput
{
    $currentTime = Get-Date -Format g
    Write-Host "An error occurred. Please review "$currentPath\$currentTimeAbr"restore.log file"
    Write-Output "$currentTime`tERR`t$_.Exception.Message" >> $currentPath\$currentTimeAbr"restore.log"
    break
}

#Verify that required modules are installed on machine and install them if not present
$message = "Verifying that required modules are installed..."
infoOutput($message)

foreach($item in (Get-Content -Path $currentPath\requiredModules.txt))
{
    if(Get-Module -ListAvailable -Name $item)
    {
        $message = "Importing $item module..."
        infoOutput($message)

        try
        {
            Import-Module $item
        }
        catch
        {
            errorOutput
        }
    }
    else
    {
        $message = "$item module not installed. Now installing $item..."
        infoOutput($message)

        try
        {
            Install-Module -Name $item -AllowClobber -Verbose:$false
        }
        catch
        {
            errorOutput
        } 
    }
}

#Prompt user for credentials to be used for database restore
$dbcreds = Get-Credential -Message "Please insert credentials to be used for database restore"

#Test connectivity to provided instance
$message = "Testing connectivity to $server..."
infoOutput($message)

try
{
    $testconn = Test-DbaConnection -SqlInstance $server -SqlCredential $dbcreds
    if($testconn.ConnectSuccess -eq "True")
    {
        $message = "Successfully connected to $server"
        infoOutput($message)
    }
    else
    {
        #Known issue where incorrect output is logged
        errorOutput
    }
}
catch
{
    errorOutput
}

#If a database with the same name is already present on the server, prompt user if existing db should be replaced from selected backup
$checkdbs = Get-DbaDatabase -SqlInstance $server -Database $dbname -SqlCredential $dbcreds
if($checkdbs.IsAccessible -eq "True")
{
    $message = "A database named $dbname already exists on $server"
    warningOutput($message)

    [char]$dbreplace = Read-Host "Would you like to replace the existing database with the new restore? (Y/N)"
    if($dbreplace -eq "N")
    {
        $message = "$env:USERNAME chose not to replace the existing $dbname database. The restore process will now terminate"
        warningOutput($message)
        break
    }
    elseif($dbreplace -eq "Y")
    {
        $message = "$env:USERNAME chose to replace the existing $dbname database with the $backup backup file. The existing database will now be deleted"
        warningOutput($message)

        try
        {
            Remove-DbaDatabase -SqlInstance $server -Database $dbname -Confirm:$false -SqlCredential $dbcreds | Out-Null
            if($?)
            {
                $message = "The $server - $dbname database was successfully deleted"
                infoOutput($message)
            }
        }
        catch
        {
            errorOutput
        }
    }
    else
    {
        $message = "An incorrect value was inserted during the prompt. Please rerun the script and select a valid input (Y or N)"
        warningOutput($message)
        break
    }
}

#Begin database restore process
$message = "Restoring $server - $dbname database from $backup backup file"
infoOutput($message)

try
{
    Restore-DbaDatabase -SqlInstance $server -DatabaseName $dbname -Path $backup -ReplaceDbNameInFile -SqlCredential $dbcreds | Out-Null
    if($?)
    {
        $message = "The $server - $dbname database was successfully restored from $backup"
        infoOutput($message)
    }
}
catch
{
    errorOutput
}