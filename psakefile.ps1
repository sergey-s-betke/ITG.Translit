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
	$CodeQualityTestsPath = Join-Path -Path $PSScriptRoot -ChildPath 'CodeQualityTests';
	$CodeQualityTestResultsDirPath = Join-Path -Path $CodeQualityTestsPath -ChildPath 'TestsResults';
	$ScriptAnalyzerResultsPath = Join-Path -Path $CodeQualityTestResultsDirPath -ChildPath 'ScriptAnalyzerResults.xml';
#	$ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
#	$ModuleArtifactPath = "$ArtifactPath\Modules"
	$RequiredModules = @(
		@{ ModuleName = 'Pester'; ModuleVersion = '4.1' }
		@{ ModuleName = 'Coveralls'; ModuleVersion = '1.0' }
		@{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.0' }
	);
}

Task Default -Depends UnitTests

Task InstallModules {
	If ( -Not ( Get-PackageProvider -Name NuGet -ListAvailable ) ) {
		Install-PackageProvider -Name NuGet -Scope CurrentUser -ErrorAction Stop -Force | Out-Null;
		Import-PackageProvider -Name NuGet -ErrorAction Stop -Force | Out-Null;
	};
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
	$RequiredModules `
	| Foreach-Object {
		if ( -not ( Get-Module -FullyQualifiedName $_ -ListAvailable ) ) {
			Install-Module -Name $_.ModuleName -RequiredVersion $_.ModuleVersion -SkipPublisherCheck -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop -Verbose;
		};
		Import-Module -FullyQualifiedName $_;
	};
}

Task ScriptAnalysis -Depends InstallModules {
	# Run Script Analyzer
	'Starting static analysis...'

	If ( -Not ( Test-Path $CodeQualityTestResultsDirPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $CodeQualityTestResultsDirPath -Parent ) `
			-Name ( Split-Path -Path $CodeQualityTestResultsDirPath -Leaf ) `
			-ItemType Directory `
			-Force `
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
		( New-Object System.Net.WebClient ).UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			( Resolve-Path $ScriptAnalyzerResultsPath )
		);
	};

	if ( $PesterResults.FailedCount ) {
		$errorID = 'AcceptanceTestFailure';
		$errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded;
		$errorMessage = "Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test.";
		$exception = New-Object `
			-TypeName System.SystemException `
			-ArgumentList $errorMessage `
		;
		$errorRecord = New-Object `
			-TypeName System.Management.Automation.ErrorRecord `
			-ArgumentList $exception, $errorID, $errorCategory, $null `
		;
		Write-Output "##vso[task.logissue type=warning]$errorMessage";
		Throw $errorRecord;
	}
}

Task UnitTests -Depends InstallModules {
	# Run Unit Tests with Code Coverage
	'Starting unit tests...'

	If ( -Not ( Test-Path $TestResultsDirPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $TestResultsDirPath -Parent ) `
			-Name ( Split-Path -Path $TestResultsDirPath -Leaf ) `
			-ItemType Directory `
			-Force `
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
		;
		Publish-Coverage -Coverage $coverage -Verbose;
	};

	if ( $PesterResults.FailedCount ) {
		$errorID = 'UnitTestFailure';
		$errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded;
		$errorMessage = "Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test.";
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
	If ( Test-Path $CodeQualityTestResultsDirPath ) {
		Remove-Item $CodeQualityTestResultsDirPath -Recurse -Force -ErrorAction Continue;
	};

	$Error.Clear();
}
