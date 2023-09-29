
#Connect-AzAccount
#Connect-AzureAd

$subName = 'stecarr - Microsoft Azure Internal Consumption'
$rgName = 'cdma'
$storageAccountName = 'cdmastorage02'
$containerName = 'bronze'

#create basic dataset folder structure
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleA'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleB\test1\subA\subB'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleC'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset2'

#add duplicate folder in error
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleA'

#Set user acl at the root of the dataset but don't set default scope
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1' -Identity 'hblinebury@microsoft.com' -accessControlType Read

#set service acl at sub folder
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1\sampleB\test1' -Identity 'cdma-ml-workspace' -accessControlType Write -IncludeDefaultScope

#set group acl at root of dataset
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1' -Identity "Pete Whitson's Direct Reports" -accessControlType Read -IncludeDefaultScope
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset2' -Identity "Pete Whitson's Direct Reports" -accessControlType Read -IncludeDefaultScope


#add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleC\test1\subA'

# user
#set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1' -Identity 'hblinebury@microsoft.com' -accessControlType Read

#service principal
#set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1\sampleB' -Identity 'cdma-ml-workspace' -accessControlType Write -IncludeDefaultScope

#add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleB'

# group
#set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1\sampleB' -Identity "Pete Whitson's Direct Reports" -accessControlType Read -IncludeDefaultScope -Verbose

remove-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset2'



