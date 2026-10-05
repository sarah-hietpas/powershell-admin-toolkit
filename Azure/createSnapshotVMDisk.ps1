# Connect and select subscription
Connect-AzAccount
$subscriptionId = "your-subscription-id"
Select-AzSubscription -SubscriptionId $subscriptionId

# Target backup resource group and location
$targetRg = "AzureBackupRG_northeurope_1"
$targetLocation = "northeurope"

# Today's date
$dateShort = Get-Date -Format "yyyyMMdd"
$dateTag = Get-Date -Format "yyyy-MM-dd"

# Import VMs from CSV
$vmList = Import-Csv -Path ".\vm_list.csv"

foreach ($vm in $vmList) {
    $vmName = $vm.VMName
    $sourceRg = $vm.ResourceGroup

    Write-Output "Processing VM: $vmName in RG: $sourceRg"
    $vmObject = Get-AzVM -Name $vmName -ResourceGroupName $sourceRg

    $allDisks = @($vmObject.StorageProfile.OsDisk) + $vmObject.StorageProfile.DataDisks

    foreach ($diskRef in $allDisks) {
        $disk = Get-AzDisk -ResourceGroupName $sourceRg -DiskName $diskRef.Name

        $snapshotName = "${vmName}_snapshot_${dateShort}"

        $snapshotConfig = New-AzSnapshotConfig `
            -SourceUri $disk.Id `
            -Location $targetLocation `
            -CreateOption Copy `
            -SkuName Standard_ZRS  # Standard HDD, zone-redundant

        Write-Output "Creating snapshot: $snapshotName for disk: $($disk.Name)"

        New-AzSnapshot `
            -Snapshot $snapshotConfig `
            -SnapshotName $snapshotName `
            -ResourceGroupName $targetRg `
            -Tag @{ "CreatedBy" = "Sarah Centeno"; "Date" = $dateTag }
    }
}
