import-module AzureDatalakeManagement

Connect-AzAccount -UseDeviceAuthentication
Connect-AzureAd

$subName = '<subscriptionName>'
$rgName = 'resourceGroup01'
$storageAccountName = 'storage01'
$containerName = 'bronze'

#create basic dataset folder structure
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleA'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleB\test1\subA\subB'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleC'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset2'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset3'
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset4'

#add duplicate folder in error
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleA'

#add duplicate folder in error & show error
add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset1\sampleA' -ErrorIfFolderExists

#Set user acl at the root of the dataset but don't set default scope
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1' -Identity 'sam@contoso.com' -accessControlType Read

#Set user acl at the root of the dataset and set default scope
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset2' -Identity 'sam@contoso.com' -accessControlType Read -IncludeDefaultScope

#Set user acl at the root of the dataset and configure the container for access by the user
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset3' -Identity 'bob@contoso.com' -accessControlType Write -IncludeDefaultScope -SetContainerACL

#set service acl at sub folder
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1\sampleB\test1' -Identity '<service identity>' -accessControlType Write -IncludeDefaultScope

#set group acl at root of dataset
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset1' -Identity "<Azure AD Group>" -accessControlType Read -IncludeDefaultScope
set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'dataset2' -Identity "<Azure AD Group>" -accessControlType Read -IncludeDefaultScope

#remove folder from specified container
remove-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'dataset4'

#move sub folder from one dataset to another
move-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -SourceContainerName $containerName -sourceFolderPath 'dataset1\sampleB' -DestinationContainerName $containerName -destinationFolderPath 'dataset2\sampleb'

