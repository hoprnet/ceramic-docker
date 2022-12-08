# Examples on how to use the Ceramic setup

## Local Setup

```
# first start the Docker containers locally
make local_start

# then check local Ceramic API
make local_test

# stop the nodes
make local_stop

# then check local Ceramic API (should fail)
make local_test
```

The running Ceramic node can be further inspected by working with the API at
`http://localhost:7007/api`. Refer to the Ceramic HTTP API docs for more info.

## Remote Setup

This requires to start a VM first, then start the Docker containers on that VM.
The setup of the DNS entry is skipped since its only meant as additional improvements.
Replace `TODO` in the ceramic .json configuration files with valid information.

```
# ensure SSH user has access to docker daemon on VM
SSH_HOST=some_user@some_host make remote_setup

# deploy Docker containers (replace VM_IP with the external IP)
SSH_HOST=some_user@some_host CERAMIC_DOMAIN=mytarget.domain make remote_start 

# test against deployed node
CERAMIC_DOMAIN=mytarget.domain make remote_test

# take Docker containers down again
SSH_HOST=some_user@some_host CERAMIC_DOMAIN=mytarget.domain make remote_stop

# test against deployed nodes (should fail now)
CERAMIC_DOMAIN=mytarget.domain make remote_test
```
