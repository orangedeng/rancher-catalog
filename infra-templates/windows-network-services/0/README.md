## Network Services for windows

This stack provides the following services:

* Metadata
* DNS

#### Metadata [rancher/rancher-metadata:<version>]
* Use microsfot/nanoserver as base image and rebuild metadata service.

#### DNS [rancher/dns:<version>]
* Use microsfot/nanoserver as base image and rebuild DNS service.
* In Windows environment, DNS server address will be 169.254.169.251

### Configuration Options

#### dns

* `DNS_RECURSER_TIMEOUT`
* `TTL`
