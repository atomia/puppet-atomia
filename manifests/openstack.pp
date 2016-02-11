## Atomia OpenStack Configuration

### Define configuration for OpenStack

### Variable documentation
#### admin_user: The user to use when connecting to the OpenStack api endpoints
#### admin_password: The password to use when connecting to the OpenStack api endpoints
#### domain: The OpenStack domain
#### identity_uri: The uri to the Keystone endpoint
#### compute_uri: The uri to the Nova endpoint
#### network_uri: The uri to the Neutron endpoint
#### ceilometer_uri: The uri to the Ceilometer endpoint
#### cinder_uri: The uri to the Cinder endpoint
#### hypervisor: The hypervisor to use, supports only KVM for now
#### external_gateway: The id of the external gateway created in Neutron

### Validations
##### admin_user: %username
##### admin_password: %password
##### domain: [a-zA-Z0-9]+
##### identity_uri: .*
##### compute_uri: .*
##### network_uri: .*
##### ceilometer_uri: .*
##### cinder_uri: .*
##### hypervisor(advanced): [a-z]+
##### external_gateway: .*

class atomia::openstack (
	$admin_user        = "admin",
	$admin_password,    
	$domain			   = "Default",
    $identity_uri,
    $compute_uri,
    $network_uri,
    $ceilometer_uri,
    $cinder_uri,
    $hypervisor        = "kvm",
    $external_gateway  = "",
){

}
