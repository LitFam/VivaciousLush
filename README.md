# VivaciousLush

## Steps to run the program in powershell

1. You may need to relax your security policy to allow local only powershell development.
	a. `Get-ExecutionPolicy` Should show at least RemoteSigned and not Restricted.
	b. If restricted run `Set-ExecutionPolicy` RemoteSigned
2. Run the program within \project
	a. & '.\Vivacious Lush ReShade.ps1'
	
## Steps to convert to .exe
1. Install ps2exe
	a. `Install-Module -Name ps2exe -Scope CurrentUser -Force`
	b. Run the program with two arguments, the .ps1 file and the to-be newly minted .exe file
		i. `Invoke-ps2exe .\'Vivacious Lush ReShade.ps1' .\'Vivacious Lush ReShade'.exe`
		
## Install the ReShade preset
1. Look at this additional readme for more information at \project\Vivacious_Lush_README.txt