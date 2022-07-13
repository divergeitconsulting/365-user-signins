# GetUserSignInData

$AppId = "Your Application ID here"
$TenantId = "Your Tenant ID here"
$AppSecret = 'Your Application Secret here'

# Construct URI and body needed for authentication
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
    grant_type    = "client_credentials" }

# Get OAuth 2.0 Token
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing

# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

# Base URL
$headers = @{Authorization = "Bearer $token"}

# Get User sign in data
Write-Host "Accessing the Graph to get user sign-in data..."
$URI = "https://graph.microsoft.com/beta/users?`$select=displayName,userPrincipalName, mail, id, CreatedDateTime, signInActivity, UserType&`$top=999"
$SignInData = (Invoke-RestMethod -Uri $URI -Headers $Headers -Method Get -ContentType "application/json") 
$Report = [System.Collections.Generic.List[Object]]::new() 

Foreach ($User in $SignInData.Value) {  
   If ($Null -ne $User.SignInActivity)     {
      $LastSignIn = Get-Date($User.SignInActivity.LastSignInDateTime) -format g
      $DaysSinceSignIn = (New-TimeSpan $LastSignIn).Days }
   Else { #No sign in data for this user account
      $LastSignIn = "Never or > 180 days" 
      $DaysSinceSignIn = "N/A" }
     
   $ReportLine  = [PSCustomObject] @{          
     UPN                = $User.UserPrincipalName
     DisplayName        = $User.DisplayName
     Email              = $User.Mail
     ObjectId           = $User.Id
     Created            = Get-Date($User.CreatedDateTime) -format g      
     LastSignIn         = $LastSignIn
     DaysSinceSignIn    = $DaysSinceSignIn
     UserType           = $User.UserType }
   $Report.Add($ReportLine) 
} # End ForEach

# Do we have extra data to fetch?
$NextLink = $SignInData.'@Odata.NextLink'

While ($NextLink -ne $Null) { # We do... so process them.
   Write-Host "Still processing..."
   $SignInData = Invoke-WebRequest -Method GET -Uri $NextLink -ContentType "application/json" -Headers $Headers
   $SignInData = $SignInData | ConvertFrom-JSon
   ForEach ($User in $SignInData.Value) {  

   If ($Null -ne $User.SignInActivity)     {
      $LastSignIn = Get-Date($User.SignInActivity.LastSignInDateTime) -format g
      $DaysSinceSignIn = (New-TimeSpan $LastSignIn).Days }
   Else { #No sign in data for this user account
      $LastSignIn = "Never or > 180 days" 
      $DaysSinceSignIn = "N/A" }
     
   $ReportLine  = [PSCustomObject] @{  
     UPN                = $User.UserPrincipalName
     DisplayName        = $User.DisplayName
     Email              = $User.Mail
     ObjectId           = $User.Id
     Created            = Get-Date($User.CreatedDateTime) -format g      
     LastSignIn         = $LastSignIn
     DaysSinceSignIn    = $DaysSinceSignIn
     UserType           = $User.UserType        }
     $Report.Add($ReportLine) } 

   # Check for more data
   $NextLink = $SignInData.'@Odata.NextLink'
} # End While

Write-Host "All done. " $Report.Count "accounts processed - output available in c:\Temp\ReportUserSignin.csv."
$Report | Export-CSV -NoTypeInformation c:\Temp\ReportUserSignin.csv