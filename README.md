This repo will describes a method that allows a Sysadmin/Intune Admin to manage local admin right with more granularity.

  
The awesome company that I work for(small sized , continuously growing ) has had it's fair share of strange requests that pushes one's skills to the next level, however, since the well known event that forced us to stay home, , there has been a recurrent requirement for temporary admin rights, for various reasons .

The security aspect of such a request is always hot topic, however while this method works, I only present it here for demonstration purposes.

The reason behind this is that I had some requirements that were not fulfilled by any actual method, more details below:  

**I needed the following:**

1.  Be able to add a user to the local admin group (but only on his device)
    
2.  Be able to do that without any remote sessions
    
3.  Be able to provide temporary access, and leave the possibility to redo the whole process if needed.
    
4.  Everything should be silent
    
5.  Make it as simple as possible so that it can be explained to others and poked around for bugs.
    
6.  Be compatible or at least non destructive for all forms of devices (AzureAD-joined, AzureAD-registered, and my personal favorite Hybrid)
    

  

**What I tried:**

1.  [Configure group membership OMA uri](https://www.inthecloud247.com/manage-the-local-administrators-group-with-microsoft-intune-azure-ad-joined-windows-10-devices/)
    

This one was nice, until I figured out that by doing so I am limited to only one application, and that if I want to redo the process, I would have to search registries and delete entries yada yada yada , also adding users by had for each request was simply outrageous for me.

2.  [Additional local administrators on Azure AD joined devices](https://docs.microsoft.com/en-us/azure/active-directory/devices/assign-local-admin#manage-the-device-administrator-role)

This one was also not great because it would added the user on all devices and it would also spam our team with a mail about a user being added to that group.

  

  

**Solution:**

Custom made scripts that will do the following:

1.  Get the user SID: this one is required so that each user will get admin rights on his own device without needing any input from the sysadmin.  _**Name**_**: Get-UserSID.ps1**
    
2.  Add the user as an admin using the SID stored by the previous script  
    _**Name**_**: AddDel-UserAdmin.ps1**
    
3.  Remove the user from the local admin group and make sure that no other local account is left on that group  _**Name**_**: AddDel-UserAdmin.ps1**
    

  
  

**Solution in detail:**

[Get-UserSID.ps1](https://github.com/cosminmocan/AddDel-UserAdmin/blob/main/Get-UserSID.ps1)  - This is a script that is applied on all devices, it creates a hidden folder in which we will store the user SID for each user that logs on the device , since it's applied on all devices that means that each device will have the sid files of the users that are using them

Example: user1's laptop will have a file called  **USER1firstname.USER1secondname.sid**  containing the SID of the user

#NOTE: all users are  [firstname.secondname@companyname.com](mailto:firstname.secondname@companyname.com)

  

[AddDell-UserAdmin.ps1](https://github.com/cosminmocan/AddDel-UserAdmin/blob/main/AddDell-UserAdmin.ps1)  - This script will be converted in a app using  [intunewinapputil](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)  , it will also be called using add and del commands(add for installing and del for uninstalling) so that we always know which device has admin provided by this method , and also so that we know where it was successfully removed.

Further explanations about the script can be found in its comments, however , the decision for it to be a app is interesting enough to discuss as well.

**Reasons for conversion to app:**

1.  As an app , you can install and uninstall as often as you like , removing the issue method number 1 from  _**WHAT-I-TRIED**_  had
    
2.  Easier to monitor , and to deploy .
    
3.  Even if alterations are needed, one can always update the app without it being reapplied to all the devices from the past.
    
4.  The ability to have a single script with 2 functions inside, install(used for adding users) and uninstall(used for removing them).

5. Possibility of deploying and removing admin right by simply adding and removing user in a security group
    

  

**Results:**

**It works !**  *

* If used on hybrid devices, you will lose your ad admin group, this one can be added back using a group policy or by adding it manually via SID (SID is vital because if the device cannot contact the Ad Server when the script is executed, it won't know what group you want to add )

Intune settings:

**Install command**

executionpolicy bypass -command "& '.\AddDel-UserAdmin.ps1' Add"

**Uninstall command**  
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -command "& '.\AddDel-UserAdmin.ps1' Del"

  

**Detection rule:**
![description](https://github.com/cosminmocan/AddDel-UserAdmin/blob/main/Evm3b3x.png)
