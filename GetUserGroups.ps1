Connect-azuread

$guests = Get-AzureADUser -top 10000 | Where-Object {($_.UserType -eq "Guest")}
foreach($guest in $guests){
    $groups= Get-AzureADUserMembership -ObjectId $guest.ObjectId
    foreach($group in $groups){
        $exportvalues = New-Object psobject
        $exportvalues | add-member -MemberType NoteProperty -Name UserPrincipalName -Value $guest.UserPrincipalName
        $exportvalues | add-member -MemberType NoteProperty -Name UserEmail -Value $guest.mail
        $exportvalues | add-member -MemberType NoteProperty -Name UserObjectID -Value $guest.ObjectId
        $exportvalues | add-member -MemberType NoteProperty -Name UserDisplayName -Value $guest.DisplayName
        $exportvalues | add-member -MemberType NoteProperty -Name GroupDisplayName -Value $group.DisplayName
        $exportvalues | add-member -MemberType NoteProperty -Name GroupObjectId -Value $group.ObjectId
        $exportvalues | Export-CSV -path $env:userprofile\guestgroups.csv -Append -NoTypeInformation
    }
}
