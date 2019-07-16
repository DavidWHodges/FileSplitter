# in building this file i consulted the following web pages to gather information:
# https://sumtips.com/tips-n-tricks/find-files-larger-than-a-specific-size-with-powershell-command-prompt/ 
# https://community.spiceworks.com/topic/1495955-split-file-csv-by-size
#
# Sample file povided by: 
# http://eforexcel.com/wp/downloads-18-sample-csv-files-data-sets-for-testing-sales/



param (
    [string] $folderPath,
    [double] $filesize = 200MB,
    [bool] $deleteFile = $false,
    [bool] $includeHeaders = $false
)



function process-File ([string] $sourceFile, [long] $filesize, [bool]$includeHeader)
{
    $file = get-childitem -File $sourceFile
    $path = $file.DirectoryName
    $basename = $file.BaseName
    $extension = $file.Extension
    $filename = "{0}_{1}{2}"

    $SplitPath = join-path -path $path -childpath $filename

    # Read in source file and grab header row.
    $inData = New-Object -TypeName System.IO.StreamReader -ArgumentList $sourceFile
    $header = $inData.ReadLine()

    # Create initial output object
    $outData = New-Object -TypeName System.Text.StringBuilder
    if ($includeHeader)
    {
        [void]$outData.Append("$header`r`n")
    }

    $i = 0

    while( $line = $inData.ReadLine() ){
        # If the object is longer than 600MB then output the content of the object and create a new one.
        if( ($outData.Length + $line.Length) -gt $filesize )
        {
            $outData.ToString() | Out-File -FilePath ( $SplitPath -f $basename, $i, $extension ) -Encoding ascii
        
            $outData = New-Object -TypeName System.Text.StringBuilder
            if ($includeHeader)
            {
                [void]$outData.Append("$header`r`n")
            }

            $i++
        }
    
        Write-Verbose "$currentFile, $line"
    
        #[void]$outData.Append("`r`n$($line)")
        [void]$outData.Append("$($line)`r`n")
        }

    # Write contents of final object 
    $outData.ToString() | Out-File -FilePath ( $SplitPath -f $basename, $i, $extension ) -Encoding ascii
}

if (!$folderPath)
{
    Write-Host "Please provide a value to the -FolderPath parameter"
    return
}

if (Test-Path -Path $folderPath) #check to make sure the path exists
{
    $FileList = Get-ChildItem $folderpath -Recurse | where-object {($_.Length -gt $filesize) -and ($_.Extension -eq '.csv') } #| ft fullname

    foreach ($f in $FileList)
    {
        $fullname = $f.fullname
        process-File -sourceFile $fullname -filesize $filesize -includeHeader $false
        if($deleteFile)
        {
            Remove-Item -Path $fullname
        }
    }
}
