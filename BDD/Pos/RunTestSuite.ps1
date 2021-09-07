Param(
    [Parameter(Position = 0)]
    [String]
    $PythonPackageFolder,

    [Parameter(Position = 1)]
    [String]
    $TestSuite,
    
    [Parameter(Position = 2)]
    [String]
    $ConfigPathName,
    
    [Parameter(Position = 3)]
    [String]
    $JunitPathName
)

$test_suite = "@testSuites\" + $TestSuite + ".txt"

Write-Host "Setting python package path to $($PythonPackageFolder)";
Set-Location -Path $PythonPackageFolder

Write-Host "About to call behave for suite $($TestSuite) with config $($ConfigPathName)";

if ($TestSuite -match "RPOS_PosBddSmoke") {
    & behave $test_suite -D bdd_config=$ConfigPathName --tags=@smoke --tags=@pos --tags=~@waitingforfix --tags=~@manual --junit --junit-directory $JunitPathName
}
else {
    & behave $test_suite -D bdd_config=$ConfigPathName --tags=@pos --tags=~@waitingforfix --tags=~@manual --junit --junit-directory $JunitPathName
}