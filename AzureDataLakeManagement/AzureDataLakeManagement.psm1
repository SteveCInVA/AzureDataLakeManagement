<#
.SYNOPSIS
    Gets the object ID, object type, and display name for a given Azure AD user, group, or service principal.

.PARAMETER Identity
    Specifies the user principal name, group display name, or service principal display name of the object to retrieve.

.EXAMPLE
    PS C:\> Get-AADObjectId -Identity "johndoe@contoso.com"
    ObjectId                                ObjectType      DisplayName
    --------                                ----------      -----------
    12345678-1234-1234-1234-1234567890ab    User            John Doe

    Description
    -----------
    This example retrieves the object ID, object type, and display name for the Azure AD user with the user principal name "johndoe@contoso.com".

.NOTES
    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>
function Get-AADObjectId
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity
    )

    # Check if the Identity is a username, group name, or service principal name
    $Identity = $Identity.Replace("'", "''")
    try
    {
        if (Get-AzureADUser -Filter "UserPrincipalName eq '$Identity'")
        {
            $objectType = 'User'
        }
        elseif (Get-AzureADGroup -Filter "DisplayName eq '$Identity'")
        {
            $objectType = 'Group'
        }
        elseif (Get-AzureADServicePrincipal -Filter "DisplayName eq '$Identity'")
        {
            $objectType = 'ServicePrincipal'
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

    # Get the object ID based on the identity and object type
    $objectId = ''
    switch ($objectType)
    {
        ''
        {
            Write-Error ('Object not found.  Unable to find object "{0}" in Azure AD.' -f $Identity)
            return
        }
        'User'
        {
            $user = Get-AzureADUser -Filter "UserPrincipalName eq '$Identity'"
            $objectId = $user.ObjectId
            $displayName = $user.DisplayName
            break
        }
        'Group'
        {
            $group = Get-AzureADGroup -Filter "DisplayName eq '$Identity'"
            $objectId = $group.ObjectId
            $displayName = $group.DisplayName
            break
        }
        'ServicePrincipal'
        {
            $sp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$Identity'"
            $objectId = $sp.ObjectId
            $displayName = $sp.DisplayName
            break
        }
    }
    Write-Verbose "Object ID: $objectId"
    Write-Verbose "Object Type: $objectType"
    Write-Verbose "Object Name: $displayName"

    $object = [PSCustomObject]@{
        ObjectId    = $objectId
        ObjectType  = $objectType
        DisplayName = $displayName
    }
    return $object
}
<#
.SYNOPSIS
    Gets the subscription ID and tenant ID for the specified Azure subscription.
.DESCRIPTION
    Gets the subscription ID and tenant ID for the specified Azure subscription.
.PARAMETER SubscriptionName
    The name of the Azure subscription to use.
.EXAMPLE
    get-AzureSubscriptionInfo -SubscriptionName 'MySubscription'
.NOTES
    requires an active connection to Azure using Connect-AzAccount

    Author: Stephen Carroll - Microsoft
    Date:   2021-08-31
#>

function get-AzureSubscriptionInfo
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionName
    )
    try
    {
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        if ($null -eq $subscription)
        {
            Write-Error('Subscription "{0}" not found.', $SubscriptionName)
            return
        }
        else
        {
            Write-Verbose 'Function: get-AzureSubscriptionInfo: Subscription found.'
            Write-Verbose "SubscriptionID: $subscription.id  SubscriptionName: $subscription.Name"
        }
    }
    catch
    {
        Write-Error 'Ensure you have run Connect-AzAccount and that the subscription exists.'
        return
    }

    $subscriptionId = $subscription.SubscriptionId
    $tenantId = $subscription.TenantId

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
    Creates a folder (or folder hierarchy) in a Data Lake storage account container
.Parameter SubscriptionName
    The name of the Azure subscription to use.
.Parameter ResourceGroupName
    The name of the resource group containing the Data Lake Storage account.
.Parameter StorageAccountName
    The name of the Data Lake Storage account.
.Parameter ContainerName
    The name of the container in the Data Lake Storage account.
.Parameter FolderPath
    The path of the folder to create. May be a single folder or a folder hierarchy. (e.g. 'folder1/folder2/folder3')
.Parameter ErrorIfFolderExists
    Optional switch to throw error if folder exists.  If not specified, will return the existing folder.
#>
function add-DataLakeFolder
{
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

        [switch]$ErrorIfFolderExists
    )

    $subId = (get-AzureSubscriptionInfo -SubscriptionName $SubscriptionName).SubscriptionId
    if ($null -eq $subId)
    {
        Write-Error 'Subscription not found.'
        return
    }
    else
    {
        Write-Verbose "SubscriptionID: $subId"
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

    if (-not (Get-Module -Name Az.Storage -ListAvailable))
    {
        Write-Verbose 'Installing Az.Storage module.'
        Import-Module -Name Az.Storage
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
    $ctx = $storageAccount.Context
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
        Write-Verbose ('Function: add-DataLakeFolder')
        if ($ErrorIfFolderExists)
        {
            Write-Error "Folder $FolderPath already exists."
            return
        }
        $ret = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath
        return
    }

    if ($null -eq $ret)
    {
        Write-Error 'Failed to create the folder.'
        return
    }
    else
    {
        Write-Verbose ('Function: add-DataLakeFolder')
        Write-Verbose "Folder created: $FolderPath"
        return $ret
    }
}

<#
.SYNOPSIS
    Deletes a folder from an Azure Data Lake Storage Gen2 account.

.DESCRIPTION
    This function deletes a folder from an Azure Data Lake Storage Gen2 account.
    It requires the subscription name, resource group name, storage account name, container name, and folder path as input parameters.
    If the folder does not exist, it will return an error unless the -ErrorIfFolderDoesNotExist switch is used.

.PARAMETER SubscriptionName
    The name of the Azure subscription.

.PARAMETER ResourceGroupName
    The name of the resource group containing the storage account.

.PARAMETER StorageAccountName
    The name of the storage account.

.PARAMETER ContainerName
    The name of the container containing the folder.

.PARAMETER FolderPath
    The path of the folder to delete.

.PARAMETER ErrorIfFolderDoesNotExist
    If this switch is used, the function will not return an error if the folder does not exist.

.EXAMPLE
    remove-DataLakeFolder -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -ContainerName "MyContainer" -FolderPath "MyFolder"

    This example deletes the folder "MyFolder" from the container "MyContainer" in the storage account "MyStorageAccount" in the resource group "MyResourceGroup" in the "MySubscription" Azure subscription.

.NOTES
    Author: Unknown
    Last Edit: Unknown
#>
function remove-DataLakeFolder
{
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

        [switch]$ErrorIfFolderDoesNotExist
    )

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
    $ctx = $storageAccount.Context
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
        Write-Verbose "Folder '$FolderPath' does not exist to delete."
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
The set-DataLakeFolderACL function sets the Access Control List (ACL) for a folder in an Azure Data Lake Storage Gen2 account.
The function requires the following parameters:
- SubscriptionName: The name of the Azure subscription.
- ResourceGroupName: The name of the resource group containing the storage account.
- StorageAccountName: The name of the storage account.
- ContainerName: The name of the container.
- FolderPath: The path of the folder.
- Identity: The identity to use in the ACL.
- AccessControlType: The type of access control to apply to the folder. Valid values are 'Read' and 'Write'.
- IncludeDefaultScope: A switch parameter that specifies whether to include the default scope in the ACL.

.PARAMETER SubscriptionName
The name of the Azure subscription.

.PARAMETER ResourceGroupName
The name of the resource group containing the storage account.

.PARAMETER StorageAccountName
The name of the storage account.

.PARAMETER ContainerName
The name of the container.

.PARAMETER FolderPath
The path of the folder.

.PARAMETER Identity
The identity to use in the ACL.

.PARAMETER AccessControlType
The type of access control to apply to the folder. Valid values are 'Read' and 'Write'.

.PARAMETER IncludeDefaultScope
A switch parameter that specifies whether to include the default scope in the ACL.

.EXAMPLE
set-DataLakeFolderACL -SubscriptionName "MySubscription" -ResourceGroupName "MyResourceGroup" -StorageAccountName "MyStorageAccount" -ContainerName "MyContainer" -FolderPath "/MyFolder" -Identity "MyIdentity" -AccessControlType "Read" -IncludeDefaultScope

This example sets the ACL for the folder "/MyFolder" in the container "MyContainer" in the storage account "MyStorageAccount" in the resource group "MyResourceGroup" for the identity "MyIdentity" with read access.

.NOTES
Requires the Az.Storage module.
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
    $ctx = $storageAccount.Context
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

    # get the ACL for the folder
    $acl = (Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath).ACL

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

    try
    {
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

function get-DataLakeFolderACL
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
        [string]$FolderPath
    )

    if (-not (Get-Module -Name Az.Storage -ListAvailable))
    {
        Write-Verbose 'Installing Az.Storage module.'
        Import-Module -Name Az.Storage
    }

    if (-not (Get-Module -Name AzureAD -ListAvailable))
    {
        Write-Verbose 'Installing Az.Storage module.'
        Import-Module -Name AzureAd
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
    $ctx = $storageAccount.Context
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


    # get the ACL for the folder
        $acls = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderPath | Select-Object -ExpandProperty ACL
        $aclResults = New-Object System.Collections.Generic.List[System.Object]
        foreach ( $ace in $acls)
        {
            if ($null -ne $ace.EntityId)
            {
    #            Write-Host '--------------------'
                $adObject = Get-AzureADObjectByObjectId -ObjectIds $ace.EntityId
                $aclResults.Add([pscustomobject]@{
                    DisplayName = $adObject.DisplayName
                    ObjectId = $ace.EntityId
                    ObjectType = $adObject.ObjectType
                    Permissions = $ace.Permissions
                    DefaultScope = $ace.DefaultScope
                })
            }
        }
        return $aclResults
}


Export-ModuleMember -Function *
