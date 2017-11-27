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
	$ScriptAnalyzerResultsPath = Join-Path -Path $TestResultsDirPath -ChildPath 'ScriptAnalyzerResults.xml';
#	$ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
#	$ModuleArtifactPath = "$ArtifactPath\Modules"
}

Task Default -Depends UnitTests

Task InstallModules {
	If ( -Not ( Get-PackageProvider -Name NuGet -ListAvailable ) ) {
		Install-PackageProvider -Name NuGet -Scope CurrentUser -ErrorAction Stop -Force | Out-Null;
		Import-PackageProvider -Name NuGet -ErrorAction Stop -Force | Out-Null;
	};
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
	'Pester', 'Coveralls', 'PSScriptAnalyzer' | ForEach-Object {
		If ( -Not ( Get-Module -Name $_ -ListAvailable ) ) {
			Install-Module -Name $_ -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop -Verbose;
			Import-Module -Name $_;
		};
	};
}

Task ScriptAnalysis -Depends InstallModules {
	# Run Script Analyzer
	'Starting static analysis...'

	If ( -Not ( Test-Path $TestResultsDirPath ) ) {
		New-Item `
			-Path ( Split-Path -Path $TestResultsDirPath -Parent ) `
			-Name ( Split-Path -Path $TestResultsDirPath -Leaf ) `
			-ItemType Directory `
			-Force `
		| Out-Null `
		;
	};

	$ScriptAnalyzerResults = Invoke-ScriptAnalyzer -Path $SourcesPath -Recurse;

	[xml]$TestResults = "<testsuite tests=`"$($ScriptAnalyzerResults.Count)`"></testsuite>";
	$ScriptAnalyzerResults | ForEach-Object {
		[xml]$TestCase = "<testcase classname=`"analyzer`" name=`"$($_.RuleName)`"><failure type=`"$($_.ScriptName)`">$($_.Message)</failure></testcase>";
		$TestResults.testsuite.AppendChild( $TestResults.ImportNode( $TestCase.testcase, $True ) );
	};
	$Writer = [System.Xml.XmlWriter]::Create(
		$ScriptAnalyzerResultsPath `
		, ( New-Object `
			-TypeName System.Xml.XmlWriterSettings `
			-Property @{
				Indent = $True;
				OmitXmlDeclaration = $False;
				NamespaceHandling = [System.Xml.NamespaceHandling]::OmitDuplicates;
				NewLineOnAttributes = $False;
				CloseOutput = $True;
				IndentChars = "`t";
			} `
		) `
	);
	$TestResults.WriteTo( $Writer );
	$Writer.Close();

	if ( $env:APPVEYOR -eq 'True' ) {
		( New-Object System.Net.WebClient ).UploadFile(
			"https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
			( Resolve-Path $ScriptAnalyzerResultsPath )
		);
	};

	if ( $ScriptAnalyzerResults.Count ) {
		$errorID = 'ScriptAnalyzerTestFailure';
		$errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded;
		$errorMessage = "Script Analyzer issues: $($ScriptAnalyzerResults.Count).";
		$exception = New-Object `
			-TypeName System.SystemException `
			-ArgumentList $errorMessage `
		;
		$errorRecord = New-Object `
			-TypeName System.Management.Automation.ErrorRecord `
			-ArgumentList $exception, $errorID, $errorCategory, $null `
		;
		Write-Output "##vso[task.logissue type=warning]$errorMessage";
		Write-Output $ScriptAnalyzerResults;
		Throw $errorRecord;
	}
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
		| Out-Null `
		;
	};

	$PesterResults = Invoke-Pester `
		-Path $TestsPath `
		-OutputFile $TestResultsPath `
		-OutputFormat NUnitXml `
		-CodeCoverage ( Join-Path -Path $SourcesPath -ChildPath '*.*' ) `
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
			-PesterResults $PesterResults `
			-CoverallsApiToken $env:COVERALLS_REPO_TOKEN `
			-BranchName $env:APPVEYOR_REPO_BRANCH `
		;
		Publish-Coverage -Coverage $coverage -Verbose;
	};

	if ( $PesterResults.FailedCount ) {
		$errorID = if ( $TestType -eq 'Unit' ) { 'UnitTestFailure' }
			elseif ( $TestType -eq 'Integration' ) { 'InetegrationTestFailure' }
			else { 'AcceptanceTestFailure' }
		;
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

	$Error.Clear();
}
