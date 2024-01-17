# Install Vivacious Lush ReShade

Write-Host 'Welcome to the Vivacious Lush ReShade Installer for Guild Wars 2. Enjoy your stay!!!'
Write-Host "`nRunning in" (Get-Location)
function Find-Executable {
    param (
        [string]$searchPath
    )

    $executable = Get-ChildItem -Path $searchPath -Filter "Gw2-64.exe" -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1
    if ($executable) {
        $executable.FullName
    } else {
        $null
    }
}

# Define common installation paths
$pathsToSearch = @(
    "C:\Program Files\Guild Wars 2",
    "C:\Program Files (x86)\Guild Wars 2",
    "C:\Program Files (x86)\Steam\steamapps\common\Guild Wars 2",
	"B:\Guild Wars 2"
)

# Search for the executable
$foundPath = $null
foreach ($path in $pathsToSearch) {
    $foundPath = Find-Executable -searchPath $path
    if ($foundPath) {
        break
    }
}


# Check if the executable was found
if (-not $foundPath) {
    while ($true) {
        $userPath = Read-Host "Guild Wars 2 is not located in default install directories.`n`nFind where Guild Wars is installed and copy the path. The path can be found with a Windows Explorer window and be copied from the top of the window. It should look something like C:\Some Folder\Guild Wars 2`n`nPlease Enter the Guild Wars 2 base directory path"
        if ($userPath -eq "Q") {
            Write-Host "Search cancelled by the user."
            exit
        }
        
        $foundPath = Find-Executable -searchPath $userPath
        if ($foundPath) {
            break
        } else {
            Write-Host "Gw2-64.exe not found in the specified path. Please try again."
        }
    }
}

# Display the found path and store the directory
if ($foundPath) {
    Write-Host "Gw2-64.exe found at: $foundPath"
    $guildWars2InstallDir = Split-Path -Path $foundPath
	# Check for dxgi.dll in the install directory and rename it if exists
	$dxgiPath = Join-Path -Path $guildWars2InstallDir -ChildPath "dxgi.dll"
	if (Test-Path -Path $dxgiPath) {
		$d3d11Path = Join-Path -Path $guildWars2InstallDir -ChildPath "d3d11.dll"
		Rename-Item -Path $dxgiPath -NewName $d3d11Path
		Write-Host "Renamed '$dxgiPath' to 'd3d11.dll because Guild Wars 2 hook now uses directX 11'"
	}
	
	# Get the script's or executable's current directory
	# Determine if running as a script or as an executable
	if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
		# Running as a .ps1 script
		$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
	}
	else {
		# Running as an executable
		$scriptDir = [System.AppDomain]::CurrentDomain.BaseDirectory
	}
	
	Write-Host 'debug' $scriptDir
	# Check if the path is valid
	if (-not (Test-Path -Path $scriptDir)) {
		Write-Host "Unable to determine the script's directory."
		exit
	}

	# Define the folders to copy
	$foldersToCopy = @("reshade-presets", "reshade-shaders")

	# Copy each folder if it exists
	foreach ($folder in $foldersToCopy) {
		$sourcePath = Join-Path -Path $scriptDir -ChildPath $folder
		$destinationPath = Join-Path -Path $guildWars2InstallDir -ChildPath $folder

		if (Test-Path -Path $sourcePath) {
			# Ensure the destination folder exists
			if (-not (Test-Path -Path $destinationPath)) {
				New-Item -Path $destinationPath -ItemType Directory | Out-Null
			}

			# Copy items from the source folder to the destination folder
			Get-ChildItem -Path $sourcePath | Copy-Item -Destination $destinationPath -Recurse -Force -ErrorAction SilentlyContinue
			Write-Host "Merged contents of '$folder' into '$destinationPath'"
		} else {
			Write-Host "Error: Expected folder '$folder' does not exist in the script's directory."
		}
	}

	# Copy Vivacious_Lush_README.txt if it exists
	$sourceFile = Join-Path -Path $scriptDir -ChildPath "Vivacious_Lush_README.txt"
	$destinationFile = Join-Path -Path $guildWars2InstallDir -ChildPath "Vivacious_Lush_README.txt"

	if (Test-Path -Path $sourceFile) {
		Copy-Item -Path $sourceFile -Destination $destinationFile -Force
		Write-Host "Copied 'Vivacious_Lush_README.txt' to '$guildWars2InstallDir'"
	} else {
		Write-Host "Error: 'Vivacious_Lush_README.txt' does not exist in the script's directory."
	}
	
	Write-Host "`nSuccessfully installed Vivacious Lush ReShade to Guild Wars 2`n`nDon't forget to read the Vivacious_Lush_README.txt!"
	
} else {
    Write-Host "Gw2-64.exe not found."
}

# Optional: Pause script
Read-Host -Prompt "Press any enter to continue..."

