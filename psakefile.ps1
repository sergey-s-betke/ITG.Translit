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
	$TestResultsPath = Join-Path -Path $TestsPath -ChildPath 'TestsResults.xml';
#	$ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
#	$ModuleArtifactPath = "$ArtifactPath\Modules"
}

Task Default -Depends UnitTests

Task InstallModules {
	Install-Module -Name Pester -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop -Verbose;
	Install-Module -Name Psake -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop -Verbose;
}

Task ScriptAnalysis -Depends InstallModules {
	# Run Script Analyzer
	# "Starting static analysis..."
	# Invoke-ScriptAnalyzer -Path $ConfigPath
}

Task UnitTests -Depends InstallModules, ScriptAnalysis {
	# Run Unit Tests with Code Coverage
	'Starting unit tests...'

	$PesterResults = Invoke-Pester `
		-Path $TestsPath `
		-CodeCoverage "$SourcesPath\*.*" `
		-OutputFile $TestResultsPath `
		-OutputFormat NUnitXml `
		-PassThru `
	;

	if ( $env:APPVEYOR -eq 'True' ) {
		( New-Object System.Net.WebClient ).UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			( Resolve-Path $TestResultsPath )
		);
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

	Remove-Item $TestResultsPath -ErrorAction SilentlyContinue;

	$Error.Clear();
}
