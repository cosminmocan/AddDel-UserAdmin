Hello everyone.

First of all, this will probably a hard to follow post , so excuses in advance, however I think it is worth the read.



The company that I work for(small sized , continuously growing ) has had it's fair share of strange requests, however, since the disease that we all know and despise , there has been a recurrent requirement for temporary admin rights, for researchers of various upper management people.

While the security aspect of this practice shall not be discussed (we already did and know the risks and dangers) , there was never a clear method for my requirement.



I needed the following:

Be able to add a user to the local admin group (but only on his device)

Be able to do that without any remote sessions

Be able to provide temporary access, and leave the possibility to redo the whole process if needed.

Everything should be silent

Dumb it down so that it can later be explained and followed by the support guys

Be compatible or at least non destructive for all forms of devices (AzureAD-joined , AzureAD-registered and my personal favorite Hybrid)



What I tried:

Configure group membership OMA uri

This one was nice, until I figured out that by doing so I am limited to only one application, and that if I want to redo the process, I would have to search registries and delete entries yada yada yada , also adding users by had for each request was simply outrageous for me.

2. Additional local administrators on Azure AD joined devices

This one was also not great because it would added the user on all devices and it would also spam our team with a mail about a user being added to that group.





Solution:

Custom made scripts that will do the following:

Get the user SID: this one is required so that each user will get admin rights on his own device without needing any input from the sysadmin. Name**: Get-UserSID.ps1**

Add the user as an admin using the SID stored by the previous script
Name**: AddDel-UserAdmin.ps1**

Remove the user from the local admin group and make sure that no other local account is left on that group Name**: AddDel-UserAdmin.ps1**



Solution in detail:

Get-UserSID.ps1 - This is a script that is applied on all devices, it creates a hidden folder in which we will store the user SID for each user that logs on the device , since it's applied on all devices that means that each device will have the sid files of the users that are using them

Example: user1's laptop will have a file called user1firstname.user1secondname.sid containin the SID of the user

#NOTE: all our users are firstname.secondname@companyname.com



AddDell-UserAdmin.ps1 - This script will converted in a app using intunewinapputil , it will also be called using add and del commands(add for installing and del for uninstalling) so that we always know which device has admin provided by this method , and also so that we know where it was successfully removed.

Further explanations about the script can be found in its comments, however , the decision for it to be a app is interesting enough to discuss as well.

Reasons for conversion to app:

As an app , you can install and uninstall as often as you like , removing the issue method number 1 from WHAT-I-TRIED had

Easier to monitor , and to deploy .

Even if alterations are needed, one can always update the app without it being reapplied to all the devices from the past.

The ability to have a single script with 2 functions inside, install(used for adding users) and uninstall(used for removing them).



Results:

It works ! *

* If used on hybrid devices, you will lose your ad admin group, this one can be added back using a group policy or by adding it manually via SID (SID is vital because if the device cannot contact the Ad Server when the script is executed, it won't know what group you want to add )

Intune settings:

Install command

executionpolicy bypass -command "& '.\AddDel-UserAdmin.ps1' Add"

Uninstall command
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -command "& '.\AddDel-UserAdmin.ps1' Del"



Detection rule
