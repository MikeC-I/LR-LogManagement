<#
.NAME
Get-LR-Archives
.SYNOPSIS
Utility to manage LogRhythm Archives files
.DESCRIPTION
100% unofficial.  If it were possible to have more than 100% it'd be in that range!
LogRhythm, by default, doesn't delete Inactive Archives, ever!  For storage or compliance reasons you may wish to automatically delete or move InactiveArchives after a certain period. 
The Get-LR-Archives function enables you to do just that.   
This should be run on the XM, DP or SAN that stores archives.  The default location for Archives is "C:\LogRhythmArchives\Inactive" and days to delete is 1 year.
Archive Naming Convention: 20131114_3_1_1_635199840557441540.lca
20131114               < Year, Month, Day
_3                     < Log Source ID
_1                     < Agent ID
_1                     < Mediator
_635199840557441540    < Probably Means Something
.lca                   < File Extension
.EXAMPLE
Delete InactiveArchives older than 365 days
.\ArchiveManagement.ps1 -action dryrun -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than "10" -filter "*2017*"
Delete InactiveArchives for 2015 
.\ArchiveManagement.ps1 -action dryrun -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than "9999" -filter "2015****_"
Delete InactiveArchives for LogSource ID 2 from 2017
.\ArchiveManagement.ps1 -action dryrun -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than "9999" -filter "2017****_2_*"
Size InactiveArchives for all log sources over 9999 days
.\ArchiveManagement.ps1 -action size -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than 9999
.PARAMETER action
Dryrun = Test without making changes, a good place to start
Delete = Delete archives, be really sure you want do this!
Move = Move archives, note you need include the trailing \ on your new path or will error
Size = Calculates the size of InactiveArchive files in MB
.NOTES
June 2017 @chrismartin
.LINK
https://github.com/lrchma/
#>
    
param(
  [Parameter(Mandatory=$true)]
  [string]$action,
  [Parameter(Mandatory=$true)]
  [string]$inactive_archives_location = 'C:\LogRhythmArchives\Inactive',
  [Parameter(Mandatory=$true)]
  [int]$archives_older_than = 365,
    [Parameter(Mandatory=$false)]
  [string]$filter = '*',
  [Parameter(Mandatory=$false)]
  [string]$new_inactive_archives_location = ''
)


################################################################################
# MAIN
################################################################################

try
{

# Test the provided path

if ((Test-Path -Path $inactive_archives_location) -eq 0) {
    Write-Host "Invalid path provided.  Exiting"
    Exit
}


# Set the date of archives to be deleted, defaults to 1 year
$then = (get-date).AddDays(-$archives_older_than).ToString("yyyyMMdd")

    switch ($action)
    {
        delete 
              {
                  $choice = "y"
                    #while ($choice -notmatch "[y|n]"){
                    #    $choice = read-host "This action will permanently delete data, are you sure you want to continue? (Y/N)"
                    #    }

                    if ($choice -eq "y"){
                        Get-ChildItem $inactive_archives_location -recurse -filter $filter| ForEach {
                                if ($_.name.split("_")[0] -lt $then) #wish I could remember why I wrote this, but sure it does something
                                    {
                                        Remove-Item $_.FullName -whatif -Recurse
                                        Remove-Item $_.FullName -Force -Recurse
                                    }
                            }
                        }
                    else {
                        exit
                    }
                }
        dryrun 
               {
                Get-ChildItem $inactive_archives_location -recurse -filter $filter | ForEach {
                        if ($_.name.split("_")[0] -lt $then)
                            {
                                # Write-Host $then
                                Remove-Item $_.FullName -whatif -Recurse
                            }
                    }
               }
        move
               {
                Get-ChildItem $inactive_archives_location -recurse -filter $filter | ForEach {
                        if ($_.name.split("_")[0] -lt $then)
                            {
                                Move-Item $inactive_archives_location\$_ $new_inactive_archives_location
                            }
                    }
               }
        size
               {
                Get-ChildItem $inactive_archives_location -recurse -filter $filter| ForEach {
                        if ($_.name.split("_")[0] -lt $then)
                            {
                                 foreach ($file in Get-ChildItem $inactive_archives_location\$_ -Recurse) 
                                    { 
                                        "File:{0},Size:{1}" -f $file.ToString(), ((Measure-Object -inputObject $file -Property Length -Sum -ErrorAction Stop).Sum / 1MB) 
                                    }
                            }
                    }
               }
        }
}
   catch
   {
            $ErrorMessage = $_.Exception.Message
            write-host $ErrorMessage 
    }

# SIG # Begin signature block
# MIIFxQYJKoZIhvcNAQcCoIIFtjCCBbICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsdpRL2zjQNHwTwt4WnW8eTrn
# CY2gggNLMIIDRzCCAjOgAwIBAgIQMXHmxbDB679A3WwU2OUDSjAJBgUrDgMCHQUA
# MC8xLTArBgNVBAMTJFMzIFBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9v
# dDAeFw0xODAzMjIxNjAzMjNaFw0zOTEyMzEyMzU5NTlaMB0xGzAZBgNVBAMTEk1D
# SSBQb3dlclNoZWxsIENTQzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AMoFVBDFL0rMASn1AncdDsOsiaJJDIKd2fXQdj+gUjcooU15vH/RStvolLJtmOUA
# O1YYYGAlZiUnqPMeXuKIeC247nN/X8KydmVk/FEgDXQBUlaMWwcdCT1EMXPiOuyW
# VE8ZJD7cwkkDGEr7IZND9TQewss1WMTgV7VuDIiVb9oOW4BAzi2QrQViNfZJt7J0
# eUqGAxTGSQyiTMXdS1NELEgx6HX8K/JID51AXRsZmw5cFRoSzXwuS8s8xTmwWcUx
# iusr8/HQc1gKMhUHZwsUV9ZAvaLtKOvOTpJKqC9qChiIjpjkyMbfYx3ltiwd1njH
# lTkZYh8SEl7IoNN9F+4/dc8CAwEAAaN5MHcwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# YAYDVR0BBFkwV4AQ90rS67Eox9I0DDTe6Ilt+aExMC8xLTArBgNVBAMTJFMzIFBv
# d2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQpeMokcDvwpNJz7iFPIkk
# rTAJBgUrDgMCHQUAA4IBAQArynLVGqNCwNk99xnNCuALE76v4zB0549Tq+wdyVca
# xaJrmgQKB7J9mn/iWbG9PTal0cYN9oo32zy3qcGBbzp63V+ylufU7S+zzR9nTo01
# iSuGVePg5soAs15AKzEWR2+idRucMV+ulOlNSuUcRJ0ayUgz+mieaVbXsjoSbXCI
# fLOahbuvEZ9OWvb/mlMBW7mcL4PhvEY01lHLyCgi+gXJSAXZEuE83nYwdzRcJ5Bn
# nC5iTQykclF91F5OLVAPVdHrXRNYJUzRnUgCmLqaJFx5kEps/riE8U8HckwICokN
# Tk6W2Y7KZff7VWt31tTsQd7g/zVOcclp16fUqRcFfPVGMYIB5DCCAeACAQEwQzAv
# MS0wKwYDVQQDEyRTMyBQb3dlclNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3QC
# EDFx5sWwweu/QN1sFNjlA0owCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAG7QiFMACq9sn8ze/os
# Ps+1y1PnMA0GCSqGSIb3DQEBAQUABIIBAH9yfXh3Oc/A+W9bIs4j8NOTtfT9zmuj
# nM8QageS3u5UjxExwCUKjVrX6Oh8GoKuW0Z17cZWHYBoC5I1NOD9u46Yd3kI7EY/
# vI8/U1e4k6MH8rIvIm2UXiWCZvHPKDXXC8qc5IfCGZjio7S+6ZpoS8l0D73jof6f
# 7bOF4fr25db4BZjKHqjBba8rN9DJg6KKdzFvlVok3OwXiKtcfGEnbGx/sTNdT7w4
# DTKIE8EKFn7xl76pbX4604O/YySKBjojpvASkJa3ZPTMMZPPYhTeZ4HmJ9c1UkXZ
# BazC+Tw3Yx4eRaFDlr6456Pr41u3RAzlOx5Cu14INwY1LlfCp9KH5Ng=
# SIG # End signature block
