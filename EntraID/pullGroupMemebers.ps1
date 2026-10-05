Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All"

# Search string
$searchString = "AAD Intune Sensitive Data"

# Get all groups that contain the name
$groups = Get-MgGroup -All | Where-Object {
    $_.DisplayName -like "*$searchString*"
}

$results = @()

foreach ($group in $groups) {

    Write-Host "Processing group: $($group.DisplayName)" -ForegroundColor Cyan

    # Get members of the group
    $members = Get-MgGroupMember -GroupId $group.Id -All

    foreach ($member in $members) {

        # Try to get user details (if member is a user)
        $user = $null
        if ($member.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.user") {
            $user = Get-MgUser -UserId $member.Id
        }

        $results += [PSCustomObject]@{
            GroupName       = $group.DisplayName
            GroupId         = $group.Id
            MemberName      = $user.DisplayName
            MemberUPN       = $user.UserPrincipalName
            MemberId        = $member.Id
            MemberType      = $member.AdditionalProperties["@odata.type"]
        }
    }
}

# Display results
$results | Format-Table -AutoSize

# Optional: Export to CSV
$results | Export-Csv ".\exports\Sensitive_Data_Devices.csv" -NoTypeInformation

Write-Host "`nExport complete" -ForegroundColor Green
