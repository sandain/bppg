# BPPG AWS controller

This script controls job submission and instance management for AWS.


## Usage:
```
Usage: controller.sh <command> <command options>

Commands:

  enqueue <Type> <Name> <Files>   Add a job to the queue.
  instance <IP Address/Domain>    Add an AWS instance to run jobs.
  start                           Start the job queue.
  status                          Print current status of jobs and queues.

Job Types:

  genome-assembly                 Run the bppg/genome-assembly pipeline.

Requirements:
  ~/.config/rclone/rclone.conf    Rclone configuration for the job.
  ~/.ssh/jpl.pem                  RSA private key used to connect to AWS.
```

## Required Configuration:

This script requires that Rclone be configured to connect with GDrive, and an
RSA key be setup with AWS.

### Rclone

1. Create a new remote connection using the Rclone configuration utility.
```
rclone config
```

2. Create a new remote connection:
```
No remotes found - make a new one
n) New remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
n/r/c/s/q> n
```

3. Name the remote connection. For this example, we use the genome-assembly
pipeline:
```
name> genome-assembly
```

4. Select the type of storage. We are using Google Drive:
```
Type of storage to configure.
Choose a number from below, or type in your own value
[snip]
 XX / Google Drive
    \ "drive"
[snip]
Storage> drive
```

5. Google Application Client ID is optional, leave blank:
```
Google Application Client Id - leave blank normally.
client_id>
```

6. Google Client Secret is optional, leave blank:
```
OAuth Client Secret
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_secret>
```

7. Select access level for remote connection. We will use full access:
```
Scope that rclone should use when requesting access from drive.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
 1 / Full access all files, excluding Application Data Folder.
   \ "drive"
 [snip]
scope> 1
```

8. Root folder ID is optional, leave blank:
```
ID of the root folder
Leave blank normally.
Fill in to access "Computers" folders (see docs), or for rclone to use
a non root folder as its starting point.
Enter a string value. Press Enter for the default ("").
root_folder_id>
```

9. Service Account Credentials JSON file path is optional, leave blank:
```
Service Account Credentials JSON file path 
Leave blank normally.
Needed only if you want use SA instead of interactive login.
Leading `~` will be expanded in the file name as will environment variables such as `${RCLONE_CONFIG_DIR}`.
Enter a string value. Press Enter for the default ("").
service_account_file> 
```

10. No advanced configuration is needed:
```
Edit advanced config? (y/n)
y) Yes
n) No (default)
y/n> n
```

11. Don't use auto config:
```
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
y) Yes (default)
n) No
y/n> n
```

12. Follow the link, login to Google account, and enter verification code.
```
Please go to the following link:         https://accounts.google.com/o/oauth2/auth?[snip]
Log in and authorize rclone for access
Enter verification code> [snip]
```

13. Use the team drive option:
```
Configure this as a team drive?
y) Yes
n) No (default)
y/n> y
```

14. Select the team drive to use:
```
Fetching team drive list...
Choose a number from below, or type in your own value
 [snip]
 2 / BPPG/genome-assembly
   \ "[snip]"
 [snip]
Enter a Team Drive ID> 2
```

15. Confirm the remote connection:
```
[genome-assembly]
type = drive
scope = drive
token = {"access_token":"[snip]","expiry":"[snip]"}
team_drive = [snip]
root_folder_id =
--------------------
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y
```

16. Verify that the configuration was saved to the right place
(`~/.config/rclone/rclone.conf`):
```
cat ~/.config/rclone/rclone.conf
```

### RSA key

Go to the Amazon AWS Dashboard, select `Key Pairs`, and then click on the
`Create key pair` button. Use the name `jpl` and the `pem` file format.
Finally, click `Create key pair`. This will open a file-save dialog. Save the
file to `~/.ssh/jpl.pem`.
