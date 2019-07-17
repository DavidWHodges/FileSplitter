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



function process-File ([string] $sourceFile, [long] $fileLimit, [bool]$includeHeader)
{
    $file = get-childitem -Path $sourceFile #updated for Powershell 2.0 compatability
    $path = $file.DirectoryName
    $basename = $file.BaseName
    $extension = $file.Extension
    $filename = "{0}_{1}{2}"

    $SplitPath = join-path -path $path -childpath $filename

    # Read in source file and grab header row.
    $inData = New-Object -TypeName System.IO.StreamReader -ArgumentList $sourceFile
    
    $header = $inData.ReadLine()

    try
    {
    # Create initial output object
    $fileSize = 0
    $i = 0
    $outData = New-Object -TypeName System.IO.StreamWriter -ArgumentList ( $SplitPath -f $basename, $i, $extension )
    if ($includeHeader)
    {
        [void]$outData.Append("$header`r`n")
        $fileSize = $outData.Length
    }

    

    while( $line = $inData.ReadLine() )
    {
        #write output and keep track of size
        #if size + new info is greater than limit, create new file with header optional. 
        if( ($filesize + $line.Length) -gt $fileLimit )
        {
            #update file number being used
            $i++
            #Create new file to use
            $outData.Close()
            $outData = New-Object -TypeName System.IO.StreamWriter -ArgumentList ( $SplitPath -f $basename, $i, $extension )
            #Reset File Size counter
            $fileSize = 0
            if ($includeHeader)
            {
                [void]$outData.Append("$header`r`n")
                $fileSize = $outData.Length
            }
            
            
        }
    
        Write-Verbose "$currentFile, $line"
        [void]$outData.WriteLine("$line")
        $filesize += $line.Length
        #write-host $filesize
        #$outData.ToString() | Out-File -FilePath ( $SplitPath -f $basename, $i, $extension ) -Encoding ascii -Append
        
    }
    }
    finally
    {
        $outData.Close()
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
        process-File -sourceFile $fullname -fileLimit $filesize -includeHeader $false
        if($deleteFile)
        {
            Remove-Item -Path $fullname
        }
    }
}
