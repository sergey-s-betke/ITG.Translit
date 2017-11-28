@{
	RootModule = 'ITG.Translit.psm1'
	ModuleVersion = '1.0.0'
	GUID = 'a52b9f21-3c4b-4047-a189-1b5e1aebab05'
	Author = 'Sergey S. Betke'
#	CompanyName = 'IT-Service'
	Copyright = 'Copyright © 2012-2017 Sergey S. Betke'
	PowerShellVersion = '3.0'
	Description = 'Transliteration tools'
	TypesToProcess = @()
	FormatsToProcess = @()
	FunctionsToExport = '*'
	CmdletsToExport = '*'
	VariablesToExport = '*'
	AliasesToExport = '*'
#	ModuleList = @()
#	FileList = @()
#	HelpInfoURI = ''
#	DefaultCommandPrefix = ''
	PrivateData = @{
		# PSData is module packaging and gallery metadata embedded in PrivateData
		# It's for rebuilding PowerShellGet (and PoshCode) NuGet-style packages
		# We had to do this because it's the only place we're allowed to extend the manifest
		# https://connect.microsoft.com/PowerShell/feedback/details/421837
		PSData = @{
			# The primary categorization of this module (from the TechNet Gallery tech tree).
#			Category     = 'Scripting Techniques'
#			ReleaseNotes = 'https://raw.githubusercontent.com/sergey-s-betke/ITG.Translit/master/CHANGELOG.md'
#			ReleaseNotes = 'https://github.com/sergey-s-betke/ITG.Translit/releases/tag/1.0.0'
			LicenseUri   = 'https://raw.githubusercontent.com/sergey-s-betke/ITG.Translit/develop/LICENSE'
#			RequireLicenseAcceptance = ''
			ProjectUri   = 'https://github.com/sergey-s-betke/ITG.Translit'
			Tags         = @('powershell')
#			IconUri      = 'https://raw.githubusercontent.com/sergey-s-betke/ITG.Translit/master/docs/png/icon-256x256.png'
			IsPrerelease = 'False'
		}
	}
}