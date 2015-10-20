## Atomia Basic Configuration

### Holds basic Atomia Configuration

### Variable documentation
#### atomia_domain: The domain name where all your Atomia applications will be placed. For example writing atomia.com in the box below will mean that your applications will be accessible at hcp.atomia.com, billing.atomia.com etc. Please make sure that you have a valid wildcard SSL certificate for the domain name you choose as the Atomia frontend applications are served over SSL


### Validations
##### atomia_domain: .*

class atomia::config (
	$atomia_domain         = ""

){

}
