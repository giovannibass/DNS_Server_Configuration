# What is NFS?

A Network File System (NFS) is a file system protocol that lets you access shared files over a network. That's it. Of course there's a lot to learn if you want to set one up for your environment, but if you understand that a NFS is a place where files can be shared then you're halfway there.

[nfs-script.sh](nfs-script.sh) is a shell script that automates the process of setting up a NFS. Scroll to the bottom to check out the script usage.

## How do I setup NFS on my machine?

The process can be simplified into installing the NFS service, creating a directory to share, and configuring the NFS files to have it shared. From there clients will be able to connect to the server and access files in the shared directory. 

Note that the steps differ slightly between Debian and Red Hat distributions. The need for a NFS is almost essential in corporate environments and for that reason I'll be detailing how to get it done for Red Hat distros.

### Step 1: Install NFS-Utils
This package contains the key components for configuring, operating, and maintaining a NFS.

```
sudo yum install nfs-utils
```

### Step 2: Create a directory to share
This can be a directory that already exists. You'll be good as long as you have one reserved and you know it's path. It's not uncommon to have shared directories located in `/mnt` to keep them separated from local files.

```
sudo mkdir /mnt/sharedfolder
```

### Step 3: Edit the /etc/exports file
This file will specify which directories on the server are shared as well as defining permissions for that directory.

```
sudo vi /etc/exports
```

The syntax used in this file isn't all that hard to pick up. Here's the structure along with some common options:

```
path/to/directory  <subnet>(options)
```

#### Example
```
/mnt/sharedfolder 192.168.1.0/24(rw,sync,no_subtree_check)
```

The subnet is letting the file know *who* is allowed to access this shared folder. In the example everyone within 192.168.1.0/24 is good to go. Instead of specifying a subnet, you can also put a specific IP, a hostname, or the * symbol which will allow anyone to connect.

- `rw` Gives read/write permissions
- `sync` Ensures that changes are written to the disk immediately
- `no_subtree_check` The server will not check if the file being accessed is within the exported directory, which in turn can improve performance.

These are just a few of the options that can be used. You can find more in this [reference](https://litux.nl/Reference/Books/7213/ddu0272.html).

### Step 4: Reload the NFS exports
Lastly you'll need to apply the changes made in `/etc/exports` . This is done with:

```
exportfs -arv
```

In addition you can run `exportfs -v` to confirm that the directory is recognized as a shared directory.

### Step 5: Enable the NFS Service
Lastly we need to start the service that controls all this.

```
sudo systemctl start nfs-server
sudo systemctl enable nfs-server
```

### Accessing a NFS on a client
Accessing the NFS server from another machine is simple. Before giving it a shot make sure that the client is on the same network as the server *AND* that the `/etc/exports` file has been configured to allow the client to connect.

*NFS will also need to be installed on the client as well for this to work. 
Debian: `sudo apt-get install nfs-common`
Red Hat: `sudo yum install nfs-utils`*

```
sudo mount -t nfs <server_ip>:/path/to/shared/folder /where/to/mount
```

Head over to the directory and you should be able to access the contents of your shared folder (unless the permissions in the exports folder state otherwise)!

## Script Usage
As of right now the shell script comes with 2 options: -d and -a

`Usage: sudo ./quicknfs.sh [-d DIRECTORY] [-a ACCESS]`

**-d**: Allows you to specify the name of the shared directory. This can be one that already exists. If it doesn't then a new one with the specified name will be created. If this option is not selected then a folder called *nfs_share* will be created in the directory that the script was executed then.

**-a**: Allows you to determine which clients can access the shared drive. You can specify an IP address, subnet, or hostname. If left blank then '*' will be used, meaning that anyone connected to the network can access the share.

