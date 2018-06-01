
######################################################################################
## Connect to AdventureWorksDW Database and stream random data using Powershell 
######################################################################################

$EventHubNamespace = '' #The name of the container of event hubs
$EventHubName = ''  #The name of the actual event hub 
$EventHubKeyName = "RootManageSharedAccessKey" #The name of your event hub user (RootManageSharedAccessKey is the default for testing)
$EventHubKey = "" #The access key for your EventHub user
$Database = "AdventureWorksDW"
$Server = "."
$NoOfStreams = 100000
    
######################################################################################
# Load the System.Web assembly to enable UrlEncode
[Reflection.Assembly]::LoadFile( `
  'C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\System.Web.dll')`
  | out-null 

$method = "POST"
$URI = "https://" + $EventHubNamespace + ".servicebus.windows.net/"+ $EventHubName + "/messages"
$encodedURI = [System.Web.HttpUtility]::UrlEncode($URI)
$startDate = [datetime]”01/01/1970 00:00”
$hour = New-TimeSpan -Hours 1

# Calculate expiry value one hour ahead
$sinceEpoch = NEW-TIMESPAN –Start $startDate –End ((Get-Date) + $hour)
$expiry = [Math]::Floor([decimal]($sinceEpoch.TotalSeconds + 3600))

# Create the signature
$stringToSign = $encodedURI + "`n" + $expiry
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($EventHubkey)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($stringToSign))
$signature = [System.Web.HttpUtility]::UrlEncode([Convert]::ToBase64String($signature))

#Connect to database
$ServerAConnectionString = "Data Source="+$Server+";Initial Catalog="+$Database+";User Id=saw;Integrated Security = True"
$ServerAConnection = new-object system.data.SqlClient.SqlConnection($ServerAConnectionString);

Write-Output "Beginning Data Streaming..."

for ($i=0; $i -le $NoOfStreams; $i++){

    $dataSet = new-object "System.Data.DataSet" "MetadataDataset" 
    $query = 'EXEC dbo.StreamTransactions'
    $dataAdapter = new-object "System.Data.SqlClient.SqlDataAdapter" ($query, $ServerAConnection)
    $dataAdapter.Fill($dataSet) | Out-Null

    $json = "{"
    foreach ($Row in $dataSet.Tables[0].Rows)
        { 
            $json = $json + "'SalesOrderNumber':'" +  $Row.SalesOrderNumber + "', "
            $json = $json + "'ProductKey':'" +  $Row.ProductKey + "', "
            $json = $json + "'OrderDateKey':" +  $Row.OrderDateKey + ", "
            $json = $json + "'OrderQuantity':" +  $Row.OrderQuantity + ", "
            $json = $json + "'UnitPrice':" +  $Row.UnitPrice + ", "
            $json = $json + "'DiscountAmount':" +  $Row.DiscountAmount + ", "
            $json = $json + "'SalesAmount':'" +  $Row.SalesAmount + "', "
            $json = $json + "'TaxAmt':" +  $Row.TaxAmt
            $json = $json + "}"
        }

    # API headers
    $headers = @{
                "Authorization"="SharedAccessSignature sr=" + $encodedURI + "&sig=" + $signature + "&se=" + $expiry + "&skn=" + $EventHubKeyName;
                "Content-Type"="application/atom+xml;type=entry;charset=utf-8";
                "Content-Length" = "" + $json.Length + ""
                }


    $response = Invoke-RestMethod -Uri $URI -Method $method -Headers $headers -Body $json
    Write-Output $json
    Start-Sleep -m 250
}


