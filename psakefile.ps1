[CmdletBinding(
	SupportsShouldProcess = $false
)]

param()

@(
	@{ ModuleName = 'Psake'; ModuleVersion = '4.7.0' }
) | Foreach-Object {
	if ( -not ( Get-Module -FullyQualifiedName $_ -ListAvailable ) ) {
		Install-Module -Name $_.ModuleName -MinimumVersion $_.ModuleVersion -SkipPublisherCheck -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop;
	};
	Import-Module -FullyQualifiedName $_ -ErrorAction Stop -Verbose:$false;
};

Properties {
	$ModuleName = 'ITG.Translit';

	$SourcesPath = Join-Path -Path $PSScriptRoot -ChildPath $ModuleName;
	$ModulePath = Join-Path -Path $SourcesPath -ChildPath "$($ModuleName).psm1";

	$TestsPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tests';
	$TestResultsDirPath = Join-Path -Path $TestsPath -ChildPath 'TestsResults';
	$TestResultsPath = Join-Path -Path $TestResultsDirPath -ChildPath 'TestsResults.xml';

	$CodeQualityTestsPath = Join-Path -Path $PSScriptRoot -ChildPath 'CodeQualityTests';
	$CodeQualityTestResultsDirPath = Join-Path -Path $CodeQualityTestsPath -ChildPath 'TestsResults';
	$ScriptAnalyzerResultsPath = Join-Path -Path $CodeQualityTestResultsDirPath -ChildPath 'ScriptAnalyzerResults.xml';

	$DocsPath = Join-Path -Path $PSScriptRoot -ChildPath 'docs';
	$MdDocsPath = Join-Path -Path $DocsPath -ChildPath 'markdown';
	$ExtHelpSrcPath = $SourcesPath;
	$ExtHelpCabPath = Join-Path -Path $DocsPath -ChildPath 'Help.cab';
    $HelpLocale = 'ru-RU';

#	$ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
#	$ModuleArtifactPath = "$ArtifactPath\Modules"

	$RequiredModules = @(
		@{ ModuleName = 'Psake'; ModuleVersion = '4.7.0' }
		@{ ModuleName = 'Pester'; ModuleVersion = '4.1.0' }
		@{ ModuleName = 'Coveralls'; ModuleVersion = '1.0.25' }
		@{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.16.1' }
		@{ ModuleName = 'PlatyPS'; ModuleVersion = '0.8.3' }
	);
}

Task Default -Depends UnitTests

Task InstallModules {
	Write-Information 'Install modules...';

	If ( -Not ( Get-PackageProvider -Name NuGet -ListAvailable ) ) {
		Install-PackageProvider `
			-Name NuGet `
			-Scope CurrentUser `
			-ErrorAction Stop `
			-Force `
			-Verbose:$VerbosePreference `
		| Out-Null;
		Import-PackageProvider `
			-Name NuGet `
			-ErrorAction Stop `
			-Force `
			-Verbose:$VerbosePreference `
		| Out-Null;
	};
	if ( -not ( Get-PSRepository -Name PSGallery ).Trusted ) {
		Set-PSRepository `
			-Name PSGallery `
			-InstallationPolicy Trusted `
			-Verbose:$VerbosePreference `
		;
	};
	$RequiredModules `
	| Foreach-Object {
		if ( -not ( Get-Module -FullyQualifiedName $_ -ListAvailable ) ) {
			Install-Module `
				-Name $_.ModuleName `
				-MinimumVersion $_.ModuleVersion `
				-SkipPublisherCheck `
				-Scope CurrentUser `
				-Force `
				-AllowClobber `
				-ErrorAction Stop `
				-Verbose:$VerbosePreference `
			;
		};
		Import-Module `
			-FullyQualifiedName $_ `
			-ErrorAction Stop `
			-Verbose:$false `
		;
	};
}

Task ScriptAnalysis -Depends InstallModules {
	Write-Information 'Starting static analysis...';

	If ( -Not ( Test-Path $CodeQualityTestResultsDirPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $CodeQualityTestResultsDirPath -Parent ) `
			-Name ( Split-Path -Path $CodeQualityTestResultsDirPath -Leaf ) `
			-ItemType Directory `
			-Force `
			-ErrorAction Stop `
			-Verbose:$VerbosePreference `
		| Out-Null `
		;
	};

	$PesterResults = Invoke-Pester `
		-Path $CodeQualityTestsPath `
		-OutputFile $ScriptAnalyzerResultsPath `
		-OutputFormat NUnitXml `
		-PassThru `
	;

	if ( $env:APPVEYOR ) {
		Write-Verbose 'updloading PSScriptAnalizer results to AppVeyor console...';
		( New-Object System.Net.WebClient ).UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			( Resolve-Path $ScriptAnalyzerResultsPath )
		);
	};

	if ( $PesterResults.FailedCount ) {
		Write-Error `
			-ErrorId 'AcceptanceTestFailure' `
			-Message "Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test." `
			-Category ( [System.Management.Automation.ErrorCategory]::LimitsExceeded ) `
		;
	}
}

Task UnitTests -Depends InstallModules {
	Write-Information 'Starting unit tests...';

	If ( -Not ( Test-Path $TestResultsDirPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $TestResultsDirPath -Parent ) `
			-Name ( Split-Path -Path $TestResultsDirPath -Leaf ) `
			-ItemType Directory `
			-Force `
			-ErrorAction Stop `
			-Verbose:$VerbosePreference `
		| Out-Null `
		;
	};

	$PesterResults = Invoke-Pester `
		-Path $TestsPath `
		-OutputFile $TestResultsPath `
		-OutputFormat NUnitXml `
		-CodeCoverage ( Join-Path -Path $SourcesPath -ChildPath '*.*' ) `
		-PassThru `
	;

	if ( $env:APPVEYOR ) {
		Write-Verbose 'updloading Pester unit tests results to AppVeyor console...';
		( New-Object System.Net.WebClient ).UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			( Resolve-Path $TestResultsPath )
		);
	};

	if (
		( $env:APPVEYOR ) `
		-and ( $env:COVERALLS_REPO_TOKEN ) `
	) {
		$coverage = Format-Coverage `
			-PesterResults $PesterResults `
			-CoverallsApiToken $env:COVERALLS_REPO_TOKEN `
			-BranchName $env:APPVEYOR_REPO_BRANCH `
			-Verbose:$VerbosePreference `
		;
		Publish-Coverage `
            -Coverage $coverage `
			-Verbose:$VerbosePreference `
		;
	};

	if ( $PesterResults.FailedCount ) {
		Write-Error `
			-ErrorId 'UnitTestFailure' `
			-Message "Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test." `
			-Category ( [System.Management.Automation.ErrorCategory]::LimitsExceeded ) `
		;
	};
}

Task CreateMarkdownHelp -Depends InstallModules {
	Write-Information 'Create markdown help files...';

	If ( -Not ( Test-Path $MdDocsPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $MdDocsPath -Parent ) `
			-Name ( Split-Path -Path $MdDocsPath -Leaf ) `
			-ItemType Directory `
			-Force `
			-ErrorAction Stop `
			-Verbose:$VerbosePreference `
		| Out-Null `
		;
	};

	Import-Module `
		-Name $ModulePath `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	;
	New-MarkdownHelp `
		-Module $ModuleName `
		-WithModulePage `
		-OutputFolder $MdDocsPath `
		-Locale $HelpLocale `
		-Force `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	| Out-Null;
}

Task UpdateMarkdownHelp -Depends InstallModules {
	Write-Information 'Update markdown help files...';

	Import-Module `
		-Name $ModulePath `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	;
	Update-MarkdownHelp `
		-Path $MdDocsPath `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	| Out-Null;
	Update-MarkdownHelpModule `
		-Path $MdDocsPath `
		-RefreshModulePage `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	| Out-Null;
}

Task BuildHelp -Depends UpdateMarkdownHelp {
	Write-Information 'Build external help files...';

	If ( -Not ( Test-Path $ExtHelpCabPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $ExtHelpCabPath -Parent ) `
			-Name ( Split-Path -Path $ExtHelpCabPath -Leaf ) `
			-ItemType Directory `
			-Force `
			-ErrorAction Stop `
			-Verbose:$VerbosePreference `
		| Out-Null `
		;
	};

	New-ExternalHelp `
		-Path $MdDocsPath `
		-OutputPath ( Join-Path -Path $ExtHelpSrcPath -ChildPath $HelpLocale ) `
		-Force `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	| Out-Null;
	New-ExternalHelpCab `
		-CabFilesFolder ( Join-Path -Path $ExtHelpSrcPath -ChildPath $HelpLocale )  `
		-OutputFolder $ExtHelpCabPath `
		-LandingPagePath ( Join-Path -Path $MdDocsPath -ChildPath "$($ModuleName).md" ) `
		-ErrorAction Stop `
		-Verbose:$VerbosePreference `
	| Out-Null;
    ;
}

Task Clean {
	Write-Information 'Starting Cleaning enviroment...';

	If ( Test-Path $TestResultsDirPath ) {
		Remove-Item $TestResultsDirPath -Recurse -Force -ErrorAction Continue -Verbose:$VerbosePreference;
	};
	If ( Test-Path $CodeQualityTestResultsDirPath ) {
		Remove-Item $CodeQualityTestResultsDirPath -Recurse -Force -ErrorAction Continue -Verbose:$VerbosePreference;
	};
	If ( Test-Path $ExtHelpCabPath ) {
		Remove-Item $ExtHelpCabPath -Recurse -Force -ErrorAction Continue -Verbose:$VerbosePreference;
	};

	$Error.Clear();
}
