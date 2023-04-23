<userdata>
#Logging
function Logging($String){
    Write-Output "$(Get-Date -Format G): $String" | Out-File "C:/userdata/log/userdata.log" -Append
}

#Check working dir
if (!(Test-path "C:/userdata/")){
    mkdir C:/userdata/
    mkdir C:/userdata/log
}
Set-Location "C:/userdata/"
Logging "Start Userdata"

#Set params
$driveLetter = "D"

#Get EC2 tagdatas

Logging "Get Tagdatas"
try {
    $hostName = (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/tags/instance/HostName)
    $instanceID = (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
    [string]$phase1 = (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/tags/instance/Phase1)
    [string]$phase2 = (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/tags/instance/Phase2)

} catch {
    Logging "**ERROR** Failuer Get Tagdata..."
    Logging $_.Exception.Message
}

#Phase skip
if ($phase1 -ceq "True"){
    Logging "Skip Phase1"
}

#Phase1
if ($phase1 -ceq "False"){
    Logging "Start Phase1"
    #Join Activedirectory
    Logging "Start Join Activedirectory"
    try {
        Add-Computer -NewName $hostName -DomainName "<DomainName>" -Credential 
        Logging "Complete Join Activedirectory"
    } catch {
        Logging "**ERROR** Failuer join Activedirectory..."
        Logging $_.Exception.Message
    }

    #Set tag data
    aws ec2 create-tags --resources $instanceID --tags "Key=Phase1,Value=True"
    #Restart
    Logging "Complete Phase1"
    Logging "Restart Computer"
    Restart-Computer -Force
}

#Phase skip
if ($phase2 -ceq "True"){
    Logging "Skip Phase2"
}

#Phase2
if ($phase2 -ceq "False"){
    Logging "Start Phase2"
    #Attach FSx
    Logging "Start attach FSx"
    try {
        New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "<FSxPath>"
        Logging "Complete attach FSx"
    } catch {
        Logging "**ERROR** Failuer attach FSx..."
        Logging $_.Exception.Message
    }
    
    #Set tag data
    aws ec2 create-tags --resources $instanceID --tags "Key=Phase2,Value=True"
    Logging "Complete Phase2"
    #Restart (If need it then disable comment out next command-line.)
    #Restart-Computer
}

#Finishing
Logging "Complete Userdata!"

</userdata>
<persist>true</persist>