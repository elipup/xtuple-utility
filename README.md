# xTuple Admin Utility
management of the linux-based xTuple stack. 

Getting Started, Ubuntu 14.04 LTS, 14.10, and 15.04. Debian 7.x and 8.1, all 64bit only

sudo apt-get install git

git clone https://github.com/xtuple/xtuple-admin-utility.git

cd xtuple-admin-utility && ./xtuple-utility.sh

If you are installing from scratch, choose provisioning from the main menu. To install everything, choose installpg, provisioncluster, initdb, demodb, and webclient. You will be prompted along the way for information such as postgresql port, cluster name, postgres user password, admin passwords and so on. Remember what you choose! Work on implementing #7 will be forthcoming. 

For an unattended install on a clean machine, try: `./xtuple-utility.sh -a` (See "**Installing ERP, Web Client, and xTupleCcommerce**" below)

Help Output:
```
To get an interactive menu run xtuple-utility.sh with no arguments

  -h    Show this message
  -a    Install all (PostgreSQL (currently 9.3), demo database (currently 4.9.1) and web client (currently 4.9.1))
  -d    Specify database name to create
  -p    Override PostgreSQL version
  -n    Override instance name
  -x    Override xTuple version (applies to web client and database)
  -t    Specify the type of database to grab (demo/quickstart/empty)
```

##**Installing ERP, Web Client, and xTupleCommerce**
If you choose to install everything i.e: `./xtuple-utility -a` on a *CLEAN Ubuntu 14.0x LTS* _and if you have appropriate access_, this is what you need to be aware of:

* Server Prerequsites (minimum for xTupleCommerce):
    * Ubuntu 14.0x LTS (_Ubuntu 16 **does not work** for this option_)
    * 10GB Disk
    * 2GB RAM
    * A Commercial License and Access to xTuple Private Repos
    * A [Github Personal Access Token](https://github.com/settings/tokens)

* You will need a [Github Personal Access Token](https://github.com/settings/tokens). This token can be stored in [xdruplesettings.ini](xdruplesettings.ini) or in [oatokens.txt](oatokens.txt).   

    * If you don't have a token stored, The Utility will prompt you for your Github Username and Password and create a token for you.
      
    * If you do not have access to our Commercial/Private or a specific repository, then you need to request access from xTuple.
    
    * If you have access it will install xTuple Commercial Extensions ([manufacturing,distribution](https://github.com/xtuple/private-extensions) and [xdruple-extension](https://github.com/xtuple/xdruple-extension)).
      
    * You must have access to our private repositories to install the xTupleCommerce demo environment. _It will do this to a Postbooks Demo v4.9.5 database by default._
    
    * The process may fail at several points if your Github User does not have the proper authorization from xTuple - i.e.: During drupal installation, cloning xdruple-extension or private-extensions, etc.

* When using the `./xtuple-utility -a` option, the default settings for the xTupleCommerce installation method are passed in from the [xdruplesettings.ini](xdruplesettings.ini) file. There settings for Shipper and Credit Card tokens in there which can be set. Please read this file.

* NGINX is the webserver that we use.  The configuration files for the Mobile Web Client and xTupleCommerce are located in `/etc/nginx/sites-enabled/`. 

    * Two websites will be created:
	    * For the Mobile Web Client: https://erp.prodiem.xd
	    * For the xTupleCommerce Site: http://shop.prodiem.xd 
    
    * To access the sites, you need to add entries into your local hosts file. An IP/Hostname mapping entry will need to be created in this file in order for the websites to appear on your workstation.  When the installation process is complete, The Utility will [display a message](https://github.com/xtpclark/xtuple-admin-utility/blob/xdruple/xdrupletoken.sh#L318-L348) informing you of the possible entries to create and how to login via the various xTuple Clients/Sites, etc.

	    * For Linux/OSX, the hosts file is: `/etc/hosts`
	    * For Windows NT, 2000, XP, 2003, Vista, 2008, 7, 2012, 8, 10, the hosts file is: `%SystemRoot%\System32\drivers\etc\hosts`
    
As of this tag, the xTupleCommerce site will configure a Catalog with
BTRUCK1, YTRUCK1, and WTRUCK1.  However; they do not have images associated with them for the website yet, so none will display.
