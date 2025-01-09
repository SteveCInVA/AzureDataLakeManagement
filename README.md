# AzureDataLakeManagement
This project was created to help simplify the process of managing an Azure Datalake specifically around updating existing ACL's to child objects within the lake.
Yes, this can be accomplished with Azure Storage Explorer, however come customers don't like to install new software.

My goal, is to make a straight forward set of functions that will assist a user in configuring folders and the associated ACL's in an ADLS Gen 2 storage container using the objects names rather than ID's.

To contribute to this project please view the GitHub project at https://github.com/SteveCInVA/AzureDataLakeManagement

***

## Version History:

- 2025.1.1 - 01/09/2025
Issue 27 - Added optional switch to set-DataLakeFolderACL and remove-DataLakeFolderACL functions to enable the user to not recursively apply permissions on children of the path specified.

- 2024.1.1 - 01/09/2024
Issue 22 - Fixed issue where a lack of Azure Permissions to Microsoft.Storage/storageAccounts/listKeys/action would cause failure to execute even with correct AzureAD permissions on objects.

- 2023.12.3 - 12/01/2023
Published via Github Actions to [PowershellGallery.com](https://www.powershellgallery.com/packages/AzureDataLakeManagement)

- 2023.12.2 - 12/01/2023
Removed - Github Action Publish testing

- 2023.12.1 - 12/01/2023
Function optimization and improved consistency of help content.

- 2023.11.2 - 11/13/2023
Added function to remove an ACL from a folder and all inherited children

