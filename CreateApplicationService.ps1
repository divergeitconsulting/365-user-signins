connect-azuread

$sp = New-AzADServicePrincipal -DisplayName guestusersigins
Sleep 20
$key = New-AzADServicePrincipalCredential -ObjectId $sp.Id

(get-azureadtenantdetail).ObjectId
$sp.AppId
$key.SecretText