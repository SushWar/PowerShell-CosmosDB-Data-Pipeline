[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$CosmosDBEndPoint = "Your Cosmos Endpoint"
$DatabaseId = "Database name"
$collectionId = "Container name"
$MasterKey = "Primary key"					# For retrieving Cosmos DB account keys, it's strongly recommended to either use the Az.CosmosDB module with the Get-AzCosmosDBAccountKey cmdlet or leverage Azure Key Vault.

# add necessary assembly
Add-Type -AssemblyName System.Web

######################################################

# generate authorization key
Function Generate-MasterKeyAuthorizationSignature
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)][String]$verb,
		[Parameter(Mandatory=$true)][String]$resourceLink,
		[Parameter(Mandatory=$true)][String]$resourceType,
		[Parameter(Mandatory=$true)][String]$dateTime,
		[Parameter(Mandatory=$true)][String]$key,
		[Parameter(Mandatory=$true)][String]$keyType,
		[Parameter(Mandatory=$true)][String]$tokenVersion
	)

	$hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
	$hmacSha256.Key = [System.Convert]::FromBase64String($key)

	$payLoad = "$($verb.ToLowerInvariant())`n$($resourceType.ToLowerInvariant())`n$resourceLink`n$($dateTime.ToLowerInvariant())`n`n"
	$hashPayLoad = $hmacSha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($payLoad))
	$signature = [System.Convert]::ToBase64String($hashPayLoad);

	[System.Web.HttpUtility]::UrlEncode("type=$keyType&ver=$tokenVersion&sig=$signature")
}

######################################################
Function Post-CosmosDb
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)][String]$EndPoint,
		[Parameter(Mandatory=$true)][String]$DataBaseId,
		[Parameter(Mandatory=$true)][String]$CollectionId,
		[Parameter(Mandatory=$true)][String]$MasterKey,
		[Parameter(Mandatory=$true)][String]$JSON
	)
	try {
		$Verb = "POST"
		$ResourceType = "docs";
		$ResourceLink = "dbs/$DatabaseId/colls/$CollectionId"
		$partitionkey = "[""$(($JSON |ConvertFrom-Json).ou)""]"					# My data is partitioned by Organizational Unit (OU). To extract the OU value, please provide the partition key you'd like to use.
		
		Write-Host $partitionkey

		$dateTime = [DateTime]::UtcNow.ToString("r")
		$authHeader = Generate-MasterKeyAuthorizationSignature -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
		$header = @{authorization=$authHeader;"x-ms-documentdb-partitionkey"=$partitionkey;"x-ms-version"="2018-12-31";"x-ms-date"=$dateTime}
		$contentType= "application/json"
		$queryUri = "$EndPoint$ResourceLink/docs"
		
		
		#Convert to UTF8 for special characters
		$defaultEncoding = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
		$utf8Bytes = [System.Text.Encoding]::UTf8.GetBytes($JSON)
		$bodydecoded = $defaultEncoding.GetString($utf8bytes)
		
		
		Invoke-RestMethod -Method $Verb -ContentType $contentType -Uri $queryUri -Headers $header -Body $bodydecoded -ErrorAction SilentlyContinue
   	} 
   catch {
		Write-Host "error block"
		return $_.Exception.Response.StatusCode.value__ 
   	}
    
	
}




##			Start JOB				##


$metricJob = Start-Job -ScriptBlock {Import-Module ".\ExtractMetrics.ps1"; Get-SystemMetrics}

$metrics = Receive-Job $metricJob -Wait

if ($metricJob.State -eq "Completed") {
    $Data = New-Object System.Object
    $Data | Add-Member -MemberType NoteProperty -Name "id" -Value $(New-GUID) -Force
    $Data | Add-Member -MemberType NoteProperty -Name "ou" -Value $metrics.ou  -Force
    $Data | Add-Member -MemberType NoteProperty -Name "device" -Value $metrics.device  -Force
    $Data | Add-Member -MemberType NoteProperty -Name "cpu" -Value $metrics.CPUUsage -Force
    $Data | Add-Member -MemberType NoteProperty -Name "memory" -Value $metrics.MemoryUsage -Force
    $Datajson = $Data | ConvertTo-Json
    $DeviceResult=Post-CosmosDb -EndPoint $CosmosDBEndPoint -DataBaseId $DataBaseId -CollectionId $collectionId -MasterKey $MasterKey -JSON $Datajson
    Write-Host "Metrics sent to Cosmos DB successfully." $Datajson
} else {
    Write-Warning "Metrics extraction failed. Exit code: $($metricJob.Error)"
}

Remove-Job $metricJob

##			End JOB				##


