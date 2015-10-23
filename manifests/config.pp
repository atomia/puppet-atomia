## Atomia Basic Configuration

### Holds basic Atomia Configuration

### Variable documentation
#### atomia_domain: The domain name where all your Atomia applications will be placed. For example writing atomia.com in the box below will mean that your applications will be accessible at hcp.atomia.com, billing.atomia.com etc. Please make sure that you have a valid wildcard SSL certificate for the domain name you choose as the Atomia frontend applications are served over SSL
#### atomia_admin_password: Password used to log in to Atomia Admin Panel
#### content_share_nfs_location: The NFS share used to store customer content.
#### config_share_nfs_location: The NFS share used to store web cluster configuration.

### Validations
##### atomia_domain: %hostname
##### atomia_admin_password(advanced): %password
##### content_share_nfs_location: %nfs_share
##### config_share_nfs_location: %nfs_share

class atomia::config (
	$atomia_domain	  			= "",
	$atomia_admin_password   		= "Administrator",
	$content_share_nfs_location		= "",
	$config_share_nfs_location		= "",
){

}
