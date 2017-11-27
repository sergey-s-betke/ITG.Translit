[CmdletBinding(
	SupportsShouldProcess = $false
)]

param()

# $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

Install-Module -Name Psake -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop -Verbose;

Import-Module Psake -ErrorAction Stop;

Properties {
	$SourcesPath = Join-Path -Path $PSScriptRoot -ChildPath 'ITG.Translit';
	$TestsPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tests';
	$TestResultsDirPath = Join-Path -Path $TestsPath -ChildPath 'TestsResults';
	$TestResultsPath = Join-Path -Path $TestResultsDirPath -ChildPath 'TestsResults.xml';
	$CodeCoveragePath = Join-Path -Path $TestResultsDirPath -ChildPath 'CodeCoveragePath.xml';
#	$ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
#	$ModuleArtifactPath = "$ArtifactPath\Modules"
}

Task Default -Depends UnitTests

Task InstallModules {
	Install-PackageProvider -Name NuGet -Scope CurrentUser -ErrorAction Stop -Force | Out-Null;
	Import-PackageProvider -Name NuGet -ErrorAction Stop -Force | Out-Null;
	Get-PackageSource -ProviderName PowerShellGet `
	| Set-PackageSource -Trusted `
	| Out-Null `
	;
	'Pester', 'Coveralls' | ForEach-Object {
		If ( -Not ( Get-Module -Name $_ -ListAvailable ) ) {
			Install-Module -Name $_ -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop -Verbose;
			Import-Module -Name $_;
		};
	};
}

Task ScriptAnalysis -Depends InstallModules {
	# Run Script Analyzer
	# "Starting static analysis..."
	# Invoke-ScriptAnalyzer -Path $ConfigPath
}

Task UnitTests -Depends InstallModules, ScriptAnalysis {
	# Run Unit Tests with Code Coverage
	'Starting unit tests...'

	If ( -Not ( Test-Path $TestResultsDirPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $TestResultsDirPath -Parent ) `
			-Name ( Split-Path -Path $TestResultsDirPath -Leaf ) `
			-ItemType Directory `
			-Force `
		;
	};

	$PesterResults = Invoke-Pester `
		-Path $TestsPath `
		-OutputFile $TestResultsPath `
		-OutputFormat NUnitXml `
		-CodeCoverage "$SourcesPath\*.*" `
		-CodeCoverageOutputFile $CodeCoveragePath `
		-CodeCoverageOutputFileFormat JaCoCo `
		-PassThru `
	;

	if ( $env:APPVEYOR -eq 'True' ) {
		( New-Object System.Net.WebClient ).UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			( Resolve-Path $TestResultsPath )
		);
	};

	if (
		( $env:APPVEYOR -eq 'True' ) `
		-and ( $env:COVERALLS_REPO_TOKEN ) `
	) {
		$coverage = Format-Coverage `
			-PesterResults $CodeCoveragePath `
			-CoverallsApiToken $env:COVERALLS_REPO_TOKEN `
			-BranchName $env:APPVEYOR_REPO_BRANCH `
		;
		Publish-Coverage -Coverage $coverage;
	};

	if ( $PesterResults.FailedCount ) {
		$errorID = if ( $TestType -eq 'Unit' ) { 'UnitTestFailure' }
			elseif ( $TestType -eq 'Integration' ) { 'InetegrationTestFailure' }
			else { 'AcceptanceTestFailure' }
		;
		$errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded;
		$errorMessage = "$TestType Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test.";
		$exception = New-Object `
			-TypeName System.SystemException `
			-ArgumentList $errorMessage `
		;
		$errorRecord = New-Object `
			-TypeName System.Management.Automation.ErrorRecord `
			-ArgumentList $exception, $errorID, $errorCategory, $null `
		;
		Write-Output "##vso[task.logissue type=error]$errorMessage";
		Throw $errorRecord;
	}
}

Task Clean {
	'Starting Cleaning enviroment...'

	If ( Test-Path $TestResultsDirPath ) {
		Remove-Item $TestResultsDirPath -Recurse -Force -ErrorAction Continue;
	};

	$Error.Clear();
}
