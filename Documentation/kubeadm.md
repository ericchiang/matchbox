# kubeadm

This is an experimental example to kick the tires with kubeadm.

## Assets

Download the CoreOS Container Linux image assets referenced in the target [profile](../examples/profiles).

```sh
$ ./scripts/get-coreos stable 1353.7.0 ./examples/assets
```

Add your SSH public key to each machine group definition [as shown](../examples/README.md#ssh-keys).

```json
{
    "profile": "kubeadm-worker",
    "metadata": {
        "ssh_authorized_keys": ["ssh-rsa pub-key-goes-here"]
    }
}
```

## Containers

Use rkt or docker to start `matchbox` and mount the desired example resources. Create a network boot environment and power-on your machines. Revisit [matchbox with rkt](getting-started-rkt.md) or [matchbox with Docker](getting-started-docker.md) for help.

Client machines should boot and provision themselves. Local client VMs should network boot Container Linux and become available via SSH in about 1 minute.

## Start kubeadm

First, generate the shared bootstrapping token, scp that value to the master, then start `kubeadm init`.

```
./scripts/gen-kubeadm-token
for node in 'node1' 'node2'; do
    scp assets/kubeadm.env core@${node}.example.com:~/kubeadm.env
    ssh core@${node}.example.com sudo mkdir -p /etc/kubeadm 
    ssh core@${node}.example.com sudo mv /home/core/kubeadm.env /etc/kubeadm
    ssh core@${node}.example.com sudo start kubeadm
done
ssh core@node1.example.com journalctl -u kubeadm -f
```

Once the control plane is started, copy the admin kubeconfig off the box.

```
ssh core@node1.example.com 'sudo cat /etc/kubernetes/admin.conf' > kubeconfig
```
