<#
.SYNOPSIS
    This function retrieves the object ID, object type, and display name for a specified Azure AD user, group, or service principal.

.DESCRIPTION
    Get-AADObjectId is a function that takes an identity as a parameter and returns the object ID, object type, and display name of the corresponding Azure AD user, group, or service principal. It requires an active connection to Azure AD.

.PARAMETER Identity
    The Identity parameter specifies the user principal name, group display name, or service principal display name of the object to retrieve. This parameter is mandatory.

.EXAMPLE
    PS C:\> Get-AADObjectId -Identity "johndoe@contoso.com"
    ObjectId                                ObjectType      DisplayName
    --------                                ----------      -----------
    12345678-1234-1234-1234-1234567890ab    User            John Doe

    This example retrieves the object ID, object type, and display name for the Azure AD user with the user principal name "johndoe@contoso.com".

.EXAMPLE
    PS C:\> Get-AADObjectId -Identity "HR Group"
    ObjectId                                ObjectType      DisplayName
    --------                                ----------      -----------
    87654321-4321-4321-4321-ba0987654321    Group           HR Group

    This example retrieves the object ID, object type, and display name for the Azure AD group with the display name "HR Group".

.NOTES
    This function requires an active connection to Azure AD using Connect-AzureAD. If the specified identity does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function Get-AADObjectId
{
    param (
        # The identity for which the Azure AD Object ID is to be fetched
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity
    )

    # Replacing single quotes in the identity with double single quotes
    $Identity = $Identity.Replace("'", "''")

    try
    {
        # Initializing user, group, and service principal to null
        $user = $null
        $group = $null
        $sp = $null

        # Try to get the user, group, and service principal in one go
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$Identity'" -ErrorAction SilentlyContinue
        if ($null -eq $user)
        {
            $group = Get-AzureADGroup -Filter "DisplayName eq '$Identity'" -ErrorAction SilentlyContinue
            if ($null -eq $group)
            {
                $sp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$Identity'" -ErrorAction SilentlyContinue
            }
        }

        # Check which object is not null and assign the corresponding values
        if ($null -ne $user)
        {
            $objectType = 'User'
            $objectId = $user.ObjectId
            $displayName = $user.DisplayName
        }
        elseif ($null -ne $group)
        {
            $objectType = 'Group'
            $objectId = $group.ObjectId
            $displayName = $group.DisplayName
        }
        elseif ($null -ne $sp)
        {
            $objectType = 'ServicePrincipal'
            $objectId = $sp.ObjectId
            $displayName = $sp.DisplayName
        }
        else
        {
            Write-Error ('Object not found.  Unable to find object "{0}" in Azure AD.' -f $Identity)
            return
        }
    }
    catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException]
    {
        Write-Error 'You must be authenticated to Azure AD to run this command.  Run Connect-AzureAD to authenticate.'
        return
    }
    catch
    {
        Write-Error $_.Exception.Message
        return
    }

    # Output the object details
    Write-Verbose "Object ID: $objectId"
    Write-Verbose "Object Type: $objectType"
    Write-Verbose "Object Name: $displayName"

    # Create a custom object to return
    $object = [PSCustomObject]@{
        ObjectId    = $objectId
        ObjectType  = $objectType
        DisplayName = $displayName
    }
    return $object
}

<#
.SYNOPSIS
    Retrieves the subscription ID and tenant ID for a specified Azure subscription.

.DESCRIPTION
    The get-AzureSubscriptionInfo function takes a subscription name as a parameter and returns a custom object containing the subscription ID and tenant ID for the specified Azure subscription. It requires an active connection to Azure.

.PARAMETER SubscriptionName
    The SubscriptionName parameter specifies the name of the Azure subscription for which to retrieve the subscription ID and tenant ID. This parameter is mandatory.

.EXAMPLE
    PS C:\> get-AzureSubscriptionInfo -SubscriptionName 'MySubscription'
    SubscriptionId                                TenantId
    --------------                                --------
    12345678-1234-1234-1234-1234567890ab          87654321-4321-4321-4321-ba0987654321

    This example retrieves the subscription ID and tenant ID for the Azure subscription named 'MySubscription'.

.NOTES
    This function requires an active connection to Azure using Connect-AzAccount. If the specified subscription does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function get-AzureSubscriptionInfo
{
    param (
        # The name of the Azure subscription
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionName
    )

    try
    {
        # Get the subscription details
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName

        # Check if the subscription exists
        if ($null -eq $subscription)
        {
            Write-Error('Subscription "{0}" not found.', $SubscriptionName)
            return
        }
        else
        {
            # Write verbose messages for debugging
            Write-Verbose 'Function: get-AzureSubscriptionInfo: Subscription found.'
            Write-Verbose "SubscriptionID: $subscription.id  SubscriptionName: $subscription.Name"
        }
    }
    catch
    {
        # Handle exceptions and write an error message
        Write-Error 'Ensure you have run Connect-AzAccount and that the subscription exists.'
        return
    }

    # Get the subscription ID and tenant ID
    $subscriptionId = $subscription.SubscriptionId
    $tenantId = $subscription.TenantId

    # Create a custom object to return
    $object = [PSCustomObject]@{
        SubscriptionId = $subscriptionId
        TenantId       = $tenantId
    }

    return $object
}

<#
.SYNOPSIS
    Creates a folder in a Data Lake Storage account.

.DESCRIPTION
    The add-DataLakeFolder function creates a folder (or folder hierarchy) in a Data Lake storage account container. It requires an active connection to Azure.

.PARAMETER SubscriptionName
    The name of the Azure subscription to use. This parameter is mandatory.

.PARAMETER ResourceGroupName
    The name of the resource group containing the Data Lake Storage account. This parameter is mandatory.

.PARAMETER StorageAccountName
    The name of the Data Lake Storage account. This parameter is mandatory.

.PARAMETER ContainerName
    The name of the container in the Data Lake Storage account. This parameter is mandatory.

.PARAMETER FolderPath
    The path of the folder to create. May be a single folder or a folder hierarchy (e.g. 'folder1/folder2/folder3'). This parameter is mandatory.

.PARAMETER ErrorIfFolderExists
    Optional switch to throw error if folder exists. If not specified, will return the existing folder.

.EXAMPLE
    PS C:\> add-DataLakeFolder -SubscriptionName 'MySubscription' -ResourceGroupName 'MyResourceGroup' -StorageAccountName 'MyStorageAccount' -ContainerName 'MyContainer' -FolderPath 'folder1/folder2/folder3'
    This example creates a folder hierarchy 'folder1/folder2/folder3' in the specified Data Lake storage account container.

.NOTES
    This function requires an active connection to Azure using Connect-AzAccount. If the specified subscription, resource group, storage account, or container does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function add-DataLakeFolder
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName, # Azure subscription name

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName, # Azure resource group name

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName, # Azure storage account name

        [Parameter(Mandatory = $true)]
        [string]$ContainerName, # Azure container name

        [Parameter(Mandatory = $true)]
        [string]$FolderPath, # Path to the folder

        [switch]$ErrorIfFolderExists  # Flag to indicate if an error should be thrown if the folder exists
    )

    # Get the subscription ID
    $subId = (get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName).SubscriptionId
    if ($null -eq $subId)
    {
        Write-Error 'Subscription not found.'
        return
    }

    # Set the current Azure context
    $subContext = Set-AzContext -Subscription $subId
    if ($null -eq $subContext)
    {
        Write-Error 'Failed to set the Azure context.'
        return
    }

    # Check if the Az.Storage module is installed
    if (-not (Get-Module -Name Az.Storage -ListAvailable))
    {
        Import-Module -Name Az.Storage  # Install the Az.Storage module if it's not installed
    }

    # Get the Data Lake Storage account
    $storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName
    if ($null -eq $storageAccount)
    {
        Write-Error 'Storage account not found.'
        return
    }

    # Set the context to the Data Lake Storage account
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    if ($null -eq $ctx)
    {
        Write-Error 'Failed to set the Data Lake Storage account context.'
        return
    }

    # Create the folder
    try
    {
        $ret = New-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath -Directory -ErrorAction Stop
    }
    catch
    {
        if ($ErrorIfFolderExists)
        {
            Write-Error "Folder $FolderPath already exists."
            return
        }
        $ret = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath  # Get the folder if it already exists
        return
    }

    if ($null -eq $ret)
    {
        Write-Error 'Failed to create the folder.'
        return
    }
    else
    {
        return $ret  # Return the created folder
    }
}

<#
.SYNOPSIS
    Deletes a folder from an Azure Data Lake Storage Gen2 account.

.DESCRIPTION
    The remove-DataLakeFolder function deletes a folder from an Azure Data Lake Storage Gen2 account. It requires the subscription name, resource group name, storage account name, container name, and folder path as input parameters. If the folder does not exist, it will return an error unless the -ErrorIfFolderDoesNotExist switch is used.

.PARAMETER SubscriptionName
    The name of the Azure subscription. This parameter is mandatory.

.PARAMETER ResourceGroupName
    The name of the resource group containing the storage account. This parameter is mandatory.

.PARAMETER StorageAccountName
    The name of the storage account. This parameter is mandatory.

.PARAMETER ContainerName
    The name of the container containing the folder. This parameter is mandatory.

.PARAMETER FolderPath
    The path of the folder to delete. This parameter is mandatory.

.PARAMETER ErrorIfFolderDoesNotExist
    If this switch is used, the function will not return an error if the folder does not exist.

.EXAMPLE
    PS C:\> remove-DataLakeFolder -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -ContainerName "MyContainer" -FolderPath "MyFolder"
    This example deletes the folder "MyFolder" from the container "MyContainer" in the storage account "MyStorageAccount" in the resource group "MyResourceGroup" in the "MySubscription" Azure subscription.

.NOTES
    This function requires an active connection to Azure using Connect-AzAccount. If the specified subscription, resource group, storage account, or container does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function remove-DataLakeFolder
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName, # Azure subscription name

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName, # Azure resource group name

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName, # Azure storage account name

        [Parameter(Mandatory = $true)]
        [string]$ContainerName, # Azure container name

        [Parameter(Mandatory = $true)]
        [string]$FolderPath, # Path to the folder

        [switch]$ErrorIfFolderDoesNotExist  # Flag to indicate if an error should be thrown if the folder does not exist
    )

    # Get the subscription ID
    $subId = (get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName).SubscriptionId
    if ($null -eq $subId)
    {
        Write-Error 'Subscription not found.'
        return
    }

    # Set the current Azure context
    $subContext = Set-AzContext -Subscription $subId
    if ($null -eq $subContext)
    {
        Write-Error 'Failed to set the Azure context.'
        return
    }

    # Get the Data Lake Storage account
    $storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName
    if ($null -eq $storageAccount)
    {
        Write-Error 'Storage account not found.'
        return
    }

    # Set the context to the Data Lake Storage account
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    if ($null -eq $ctx)
    {
        Write-Error 'Failed to set the Data Lake Storage account context.'
        return
    }

    # Ensure the folder exists before deleting
    try
    {
        $folderExists = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath -ErrorAction Stop
    }
    catch
    {
        if ($ErrorIfFolderDoesNotExist)
        {
            Write-Error "Folder '$FolderPath' does not exist to delete."
            return
        }
        return
    }

    # Delete the folder
    if ($null -ne $folderExists)
    {
        $ret = Remove-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath -Force
    }

    if ($null -ne $ret)
    {
        Write-Error 'Failed to delete the folder.'
        return
    }
    else
    {
        Write-Host "Folder $ContainerName\$FolderPath deleted successfully."
        return
    }
}

<#
.SYNOPSIS
    Sets the Access Control List (ACL) for a folder in an Azure Data Lake Storage Gen2 account.

.DESCRIPTION
    The set-DataLakeFolderACL function sets the Access Control List (ACL) for a folder in an Azure Data Lake Storage Gen2 account. It requires the subscription name, resource group name, storage account name, container name, folder path, identity, and access control type as input parameters. Optionally, it can also set the ACL for the container and include the default scope in the ACL.

.PARAMETER SubscriptionName
    The name of the Azure subscription. This parameter is mandatory.

.PARAMETER ResourceGroupName
    The name of the resource group containing the storage account. This parameter is mandatory.

.PARAMETER StorageAccountName
    The name of the storage account. This parameter is mandatory.

.PARAMETER ContainerName
    The name of the container containing the folder. This parameter is mandatory.

.PARAMETER FolderPath
    The path of the folder. This parameter is mandatory.

.PARAMETER Identity
    The identity to use in the ACL. This parameter is mandatory.

.PARAMETER AccessControlType
    The type of access control to apply to the folder. Valid values are 'Read' and 'Write'. This parameter is mandatory.

.PARAMETER SetContainerACL
    A switch parameter that specifies whether to set the ACL for the container. This parameter is optional.

.PARAMETER IncludeDefaultScope
    A switch parameter that specifies whether to include the default scope in the ACL. This parameter is optional.

.EXAMPLE
    PS C:\> set-DataLakeFolderACL -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -ContainerName "MyContainer" -FolderPath "/MyFolder" -Identity "MyIdentity" -AccessControlType "Read" -IncludeDefaultScope
    This example sets the ACL for the folder "/MyFolder" in the container "MyContainer" in the storage account "MyStorageAccount" in the resource group "MyResourceGroup" for the identity "MyIdentity" with read access and includes the default scope in the ACL.

.NOTES
    This function requires the Az.Storage module and an active connection to Azure using Connect-AzAccount. If the specified subscription, resource group, storage account, container, or folder does not exist, the function will return an error message. If the specified identity does not exist, the function will return an error message. If the specified access control type is not 'Read' or 'Write', the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function set-DataLakeFolderACL
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $true)]
        [string]$ContainerName,

        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [Parameter(Mandatory = $true)]
        [string]$Identity,

        [ValidateSet('Read', 'Write')]
        [Parameter(Mandatory = $true)]
        [string]$AccessControlType,

        [switch]$SetContainerACL,

        [switch]$IncludeDefaultScope
    )

    if (-not (Get-Module -Name Az.Storage -ListAvailable))
    {
        Write-Verbose 'Installing Az.Storage module.'
        Import-Module -Name Az.Storage
    }

    $sub = get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName
    if ($null -eq $sub)
    {
        Write-Error 'Subscription not found. Ensure you have run Connect-AzAccount before execution.'
        return
    }
    else
    {
        $subId = $sub.SubscriptionId
    }

    # Get the object ID of the identity to use in the ACL
    $identityObj = Get-AADObjectId -Identity $Identity
    if ($null -eq $identityObj)
    {
        Write-Error 'Identity not found.'
        return
    }
    else
    {
        Write-Verbose ('{0} ID: {1} Display Name: {2}' -f $identityObj.ObjectType, $identityObj.ObjectId, $identityObj.DisplayName)
    }

    # Set the current Azure context
    $subContext = Set-AzContext -Subscription $subId
    if ($null -eq $subContext)
    {
        Write-Error 'Failed to set the Azure context.'
        return
    }
    else
    {
        Write-Verbose $subContext.Name
    }

    # Get the Data Lake Storage account
    $storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName
    if ($null -eq $storageAccount)
    {
        Write-Error 'Storage account not found.'
        return
    }
    else
    {
        Write-Verbose $storageAccount.StorageAccountName
    }

    # Set the context to the Data Lake Storage account
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    if ($null -eq $ctx)
    {
        Write-Error 'Failed to set the Data Lake Storage account context.'
        return
    }

    # verify the folder exists before setting the ACL
    try
    {
        $folderExists = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath
        if ($null -eq $folderExists)
        {
            Write-Error('Folder not found.')
            return
        }
    }
    catch
    {
        Write-Error('Folder not found.')
        return
    }

    # translate the access control type to applied permission
    $permission = switch ( $AccessControlType )
    { 'Read'
        { 'r-x'
        }
        'Write'
        { 'rwx'
        }
        default
        { ''
        }
    }

    $identityType = switch ($identityObj.ObjectType)
    { 'User'
        { 'user'
        }
        'Group'
        { 'group'
        }
        'ServicePrincipal'
        { 'user'
        }
        'ManagedIdentity'
        { 'other'
        }
        default
        { ''
        }
    }

    # set the ACL at the container level
    if ($SetContainerACL)
    {
        Write-Verbose 'set container ACL'
        $containerACL = (Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName).ACL
        $containerACL = Set-AzDataLakeGen2ItemAclObject -AccessControlType Mask -Permission 'r-x' -InputObject $containerACL
        $containerACL = Set-AzDataLakeGen2ItemAclObject -AccessControlType $identityType -EntityId $identityObj.ObjectId -Permission 'r-x' -InputObject $containerACL
        $result = Update-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Acl $containerACL

        if ($result.FailedEntries.Count -gt 0)
        {
            Write-Error 'Failed to set the ACL for the container.'
            Write-Error $result.FailedEntries
            return
        }
        else
        {
            Write-Host 'Container ACL set successfully.'
            Write-Verbose ('Successful Directories: {0} ' -f $result.TotalDirectoriesSuccessfulCount)
            Write-Verbose ('Successful Files: {0} ' -f $result.TotalFilesSuccessfulCount)
        }
    }

    # get the ACL for the folder
    $acl = (Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath).ACL

    try
    {
        $acl = Set-AzDataLakeGen2ItemAclObject -AccessControlType Mask -Permission 'rwx' -InputObject $acl
        $acl = Set-AzDataLakeGen2ItemAclObject -AccessControlType $identityType -EntityId $identityObj.ObjectId -Permission $permission -InputObject $acl
        $result = Update-AzDataLakeGen2AclRecursive -Context $ctx -FileSystem $ContainerName -Path $FolderPath -Acl $acl
    }
    catch [Microsoft.PowerShell.Commands.WriteErrorException]
    {
        Write-Error 'Error communicating with Powershell module AZ.Storage. Ensure you have the latest version of the module installed. (Install-Module -Name Az.Storage -Force)'
        return
    }

    if ($result.FailedEntries.Count -gt 0)
    {
        Write-Error 'Failed to set the ACL.'
        Write-Error $result.FailedEntries
        return
    }
    else
    {
        Write-Host 'ACL set successfully.'
        Write-Verbose ('Successful Directories: {0} ' -f $result.TotalDirectoriesSuccessfulCount)
        Write-Verbose ('Successful Files: {0} ' -f $result.TotalFilesSuccessfulCount)
    }
    ######################
    # default scope
    if ($IncludeDefaultScope)
    {
        Write-Verbose 'include default scope'
        $acl = Set-AzDataLakeGen2ItemAclObject -AccessControlType Mask -Permission 'rwx' -InputObject $acl -DefaultScope
        $acl = Set-AzDataLakeGen2ItemAclObject -AccessControlType $identityType -EntityId $identityObj.ObjectId -Permission $permission -InputObject $acl -DefaultScope
        $result = Update-AzDataLakeGen2AclRecursive -Context $ctx -FileSystem $ContainerName -Path $FolderPath -Acl $acl

        if ($result.FailedEntries.Count -gt 0)
        {
            Write-Error 'Failed to set the ACL for the default scope.'
            Write-Error $result.FailedEntries
            return
        }
        else
        {
            Write-Host 'Default Scope ACL set successfully.'
            Write-Verbose ('Successful Directories: {0} ' -f $result.TotalDirectoriesSuccessfulCount)
            Write-Verbose ('Successful Files: {0} ' -f $result.TotalFilesSuccessfulCount)
        }
    }


}

<#
.SYNOPSIS
    Gets the Access Control List (ACL) for a folder in Azure Data Lake Storage Gen2.

.DESCRIPTION
    The get-DataLakeFolderACL function retrieves the Access Control List (ACL) for a folder in Azure Data Lake Storage Gen2. It requires the subscription name, resource group name, storage account name, and container name as input parameters. Optionally, it can also take a folder path. If the folder path is not provided, the function will revert to the root of the container.

.PARAMETER SubscriptionName
    The name of the Azure subscription. This parameter is mandatory.

.PARAMETER ResourceGroupName
    The name of the resource group containing the storage account. This parameter is mandatory.

.PARAMETER StorageAccountName
    The name of the storage account. This parameter is mandatory.

.PARAMETER ContainerName
    The name of the container. This parameter is mandatory.

.PARAMETER FolderPath
    The path of the folder. This parameter is optional. If omitted, the function will revert to the root of the container.

.EXAMPLE
    PS C:\> get-DataLakeFolderACL -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -ContainerName "MyContainer" -FolderPath "/MyFolder"
    This example gets the ACL for the folder "/MyFolder" in the container "MyContainer" of the storage account "MyStorageAccount" in the resource group "MyResourceGroup" of the Azure subscription "MySubscription".

.NOTES
    This function requires the Az.Storage and AzureAd modules and an active connection to Azure using Connect-AzAccount. If the specified subscription, resource group, storage account, or container does not exist, the function will return an error message. If the specified folder does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function get-DataLakeFolderACL
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName, # Azure subscription name

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName, # Azure resource group name

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName, # Azure storage account name

        [Parameter(Mandatory = $true)]
        [string]$ContainerName, # Azure container name

        [Parameter(Mandatory = $false)]
        [string]$FolderPath = '/' # Path to the folder in the Data Lake
    )

    # Import necessary modules
    Import-Module -Name Az.Storage -ErrorAction SilentlyContinue
    Import-Module -Name AzureAd -ErrorAction SilentlyContinue

    # Remove leading slash or backslash from the folder path
    if ($FolderPath.Length -gt 1 -and ($FolderPath.StartsWith('/') -or $FolderPath.StartsWith('\')))
    {
        $FolderPath = $FolderPath.Substring(1)
    }

    try
    {
        # Get subscription info
        $sub = get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName
        $subId = $sub.SubscriptionId

        # Set the context to the specified subscription
        $subContext = Set-AzContext -Subscription $subId

        # Get the storage account
        $storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName
        $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

        # Check if the folder exists
        $folderExists = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath

        # Get the ACLs for the folder
        $acls = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath | Select-Object -ExpandProperty ACL

        # Process each ACL
        $aclResults = foreach ($ace in $acls)
        {
            if ($ace.EntityId)
            {
                # Get the AD object for the entity
                $adObject = Get-AzureADObjectByObjectId -ObjectIds $ace.EntityId

                # Create a custom object with the ACL info
                [pscustomobject]@{
                    DisplayName  = $adObject.DisplayName
                    ObjectId     = $ace.EntityId
                    ObjectType   = $adObject.ObjectType
                    Permissions  = $ace.Permissions
                    DefaultScope = $ace.DefaultScope
                }
            }
        }

        # Return the results
        return $aclResults
    }
    catch
    {
        # Write any errors to the console
        Write-Error $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Moves a folder in Azure Data Lake Storage Gen2 to a new location.

.DESCRIPTION
    The move-DataLakeFolder function moves a folder in Azure Data Lake Storage Gen2 to a new location. It requires the subscription name, resource group name, storage account name, source container name, source folder path, and destination folder path as input parameters. Optionally, it can also take a destination container name. If the destination container name is not provided, the function will use the source container name.

.PARAMETER SubscriptionName
    The name of the Azure subscription containing the Data Lake Storage Gen2 account. This parameter is mandatory.

.PARAMETER ResourceGroupName
    The name of the resource group containing the Data Lake Storage Gen2 account. This parameter is mandatory.

.PARAMETER StorageAccountName
    The name of the Data Lake Storage Gen2 account. This parameter is mandatory.

.PARAMETER SourceContainerName
    The name of the source container for the move operation. This parameter is mandatory.

.PARAMETER SourceFolderPath
    The path of the folder to move. This parameter is mandatory.

.PARAMETER DestinationContainerName
    The name of the destination container for the move operation. This parameter is optional. If not specified, the function will use the source container name.

.PARAMETER DestinationFolderPath
    The path of the destination folder. This parameter is mandatory.

.EXAMPLE
    PS C:\> move-DataLakeFolder -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -SourceContainerName "MySourceContainer" -SourceFolderPath "/MySourceFolder" -DestinationFolderPath "/MyDestinationFolder"
    This example moves the folder "/MySourceFolder" from the container "MySourceContainer" in the storage account "MyStorageAccount" in the resource group "MyResourceGroup" in the Azure subscription "MySubscription" to the folder "/MyDestinationFolder" in the same container.

.NOTES
    This function requires the Az.Storage and AzureAd modules and an active connection to Azure using Connect-AzAccount. If the specified subscription, resource group, storage account, container, or folder does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function move-DataLakeFolder
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName, # Azure subscription name

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName, # Azure resource group name

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName, # Azure storage account name

        [Parameter(Mandatory = $true)]
        [string]$SourceContainerName, # Source container name

        [Parameter(Mandatory = $true)]
        [string]$SourceFolderPath, # Source folder path

        [Parameter(Mandatory = $false)]
        [string]$DestinationContainerName, # Destination container name

        [Parameter(Mandatory = $true)]
        [string]$DestinationFolderPath # Destination folder path
    )

    # Import necessary modules
    Import-Module -Name Az.Storage -ErrorAction SilentlyContinue
    Import-Module -Name AzureAd -ErrorAction SilentlyContinue

    try
    {
        # Get subscription info
        $sub = get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName
        $subId = $sub.SubscriptionId

        # Set the context to the specified subscription
        $subContext = Set-AzContext -Subscription $subId

        # Get the storage account
        $storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName
        $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

        # Check if the folder exists
        $folderExists = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $SourceContainerName -Path $SourceFolderPath

        # If destination container name is not provided, use source container name
        if (-not $DestinationContainerName)
        {
            $DestinationContainerName = $SourceContainerName
        }

        # Move the folder
        $ret = Move-AzDataLakeGen2Item -Context $ctx -FileSystem $SourceContainerName -Path $SourceFolderPath -DestFileSystem $DestinationContainerName -DestPath $DestinationFolderPath -Force

        # Write verbose output and return the result
        Write-Verbose ('Function: move-DataLakeFolder')
        Write-Verbose "Folder moved: $DestinationFolderPath"
        return $ret
    }
    catch
    {
        # Write any errors to the console
        Write-Error $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Removes an identity from the Access Control List (ACL) of a folder in Azure Data Lake Storage Gen2.

.DESCRIPTION
    The remove-DataLakeFolderACL function removes an identity from the Access Control List (ACL) of a folder in Azure Data Lake Storage Gen2. It requires the subscription name, resource group name, storage account name, container name, and identity as input parameters. Optionally, it can also take a folder path. If the folder path is not provided, the function will revert to the root of the container.

.PARAMETER SubscriptionName
    The name of the Azure subscription containing the Data Lake Storage Gen2 account. This parameter is mandatory.

.PARAMETER ResourceGroupName
    The name of the resource group containing the Data Lake Storage Gen2 account. This parameter is mandatory.

.PARAMETER StorageAccountName
    The name of the Data Lake Storage Gen2 account. This parameter is mandatory.

.PARAMETER ContainerName
    The name of the container. This parameter is mandatory.

.PARAMETER FolderPath
    The path of the folder. This parameter is optional. If not specified, the function will revert to the root of the container.

.PARAMETER Identity
    The identity to remove from the ACL. This parameter is mandatory.

.EXAMPLE
    PS C:\> remove-DataLakeFolderACL -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -ContainerName "MyContainer" -Identity "MyIdentity"
    This example removes the identity "MyIdentity" from the ACL of the root of the container "MyContainer" in the storage account "MyStorageAccount" in the resource group "MyResourceGroup" in the Azure subscription "MySubscription".

.NOTES
    This function requires the Az.Storage and AzureAd modules and an active connection to Azure using Connect-AzAccount. If the specified subscription, resource group, storage account, container, or folder does not exist, the function will return an error message. If the specified identity does not exist, the function will return an error message.

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function remove-DataLakeFolderACL
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName, # Azure subscription name

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName, # Azure resource group name

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName, # Azure storage account name

        [Parameter(Mandatory = $true)]
        [string]$ContainerName, # Azure container name

        [Parameter(Mandatory = $false)]
        [string]$FolderPath = '/', # Path to the folder in the Data Lake

        [Parameter(Mandatory = $true)]
        [string]$Identity # Identity to remove from the ACL
    )

    # Import necessary modules
    Import-Module -Name Az.Storage -ErrorAction SilentlyContinue
    Import-Module -Name AzureAd -ErrorAction SilentlyContinue

    # Remove leading slash or backslash from the folder path
    if ($FolderPath.Length -gt 1 -and ($FolderPath.StartsWith('/') -or $FolderPath.StartsWith('\')))
    {
        $FolderPath = $FolderPath.Substring(1)
    }

    try
    {
        # Get subscription info
        $sub = get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName
        $subId = $sub.SubscriptionId

        # Set the context to the specified subscription
        $subContext = Set-AzContext -Subscription $subId

        # Get the storage account
        $storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName
        $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

        # Get the object ID of the identity to use in the ACL
        $identityObj = Get-AADObjectId -Identity $Identity
        $id = $identityObj.ObjectId

        # Get the folder
        $folder = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath

        # Get the ACLs for the folder
        $acls = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath | Select-Object -ExpandProperty ACL

        # Remove the specified identity from the ACL
        $newacl = $acls | Where-Object { -not ($_.AccessControlType -eq $identityObj.ObjectType -and $_.EntityId -eq $id) }

        # Update the ACL
        $result = Set-AzDataLakeGen2AclRecursive -Context $ctx -FileSystem $ContainerName -Path $FolderPath -Acl $newacl

        # Check if the update was successful
        if ($result.FailedEntries.Count -gt 0)
        {
            Write-Error 'Failed to update the ACL.'
            Write-Error $result.FailedEntries
        }
        else
        {
            Write-Host 'ACL updated successfully.'
            Write-Verbose ('Successful Directories: {0} ' -f $result.TotalDirectoriesSuccessfulCount)
            Write-Verbose ('Successful Files: {0} ' -f $result.TotalFilesSuccessfulCount)
        }
    }
    catch
    {
        # Write any errors to the console
        Write-Error $_.Exception.Message
    }
}

Export-ModuleMember -Function *
