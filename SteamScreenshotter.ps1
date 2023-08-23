#conner-s
#8-21-23

#This script will iterate over each game in your steam library, translate the app id to the game title and move the screenshots from that game to a directory of that game name.

#code style: param values appended with P
#Beyond that, I'm sorry for now it's very gross, uhhhh


#Open file dialog to select the folder to move the screenshots to and focus that window
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog 
$folderBrowser.SelectedPath = ${env:USERPROFILE} + "\Desktop"
$folderBrowser.ShowDialog() | Out-Null
$PcurrentFolder = $folderBrowser.SelectedPath

function Get-SteamGameNameFromAppId {
    param($PappId, $PgameList)
    #return the name of the game from the appid
    $PgameList | Where-Object {$_.appid -eq $PappId} | Select-Object -ExpandProperty name
}

#Getting folders in the userdata path, if there's 1 other folder other than a folder named 0, that's the user id, if there's more than one, prompt the user to select the correct one
$userDataPath = ${env:ProgramFiles(x86)}+"\Steam\userdata"
$userDataFolders = Get-ChildItem -Path $userDataPath -Directory
if($userDataFolders.Count -eq 2) {
    $PuserID = $userDataFolders | Where-Object {$_.Name -ne "0"} | Select-Object -ExpandProperty Name
}
elseif($userDataFolders.Count -gt 2) {
    $userFolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $userFolderBrowser.SelectedPath = $userDataPath
    $userFolderBrowser.ShowDialog() | Out-Null
    $PuserID = $userFolderBrowser.SelectedPath | Split-Path -Leaf
}

#getting the steam screenshot path, taking the list of files in that directory and iterating over them
$steamScrotPath = ${env:ProgramFiles(x86)}+"\Steam\userdata\" + $PuserID + "\760\remote\*"

$gameScrotList = Get-ChildItem -Path $steamScrotPath

$gameList = Invoke-WebRequest "https://api.steampowered.com/ISteamApps/GetAppList/v2/" | ConvertFrom-Json | Select-Object -ExpandProperty applist | Select-Object -ExpandProperty apps

#TODO: Make this async, give it a progress bar, make it not gross
$gameScrotList | ForEach-Object {
    $gameName = Get-SteamGameNameFromAppId -PappId $_.name -PgameList $gameList
    #sanitize the game name
    $gameName = $gameName -replace "[\\/:*?""<>|]", ""
    $newPath = $PcurrentFolder + "\" + [String]$gameName
    if(!(Test-Path $newPath)) {
        New-Item -ItemType Directory -Path $newPath
    }
    $copyPath = $_.FullName + "\screenshots\*"
    Copy-Item -Path $copyPath -Destination $newPath -Exclude "thumbnails" -Recurse  
}