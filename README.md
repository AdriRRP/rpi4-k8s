# rpi4-k8s
Recipe to build a kubernetes cluster with [Raspberry Pi 4 model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)

## Hardware

- 4x Raspberry Pi 4 model B
- 4x USB Flash memory (128GB)
- 4x USB cable to power Raspberries
- 4x Ethernet cable to network Raspberries
- 1x Router with internet connection and at least 4 free ethernet ports
- 1x Power strip with:
  - 4x 10.0V 6.5A USB power supply ports for raspberries
- (Optional) 1x 2TB External SDD

## Steps

1. **Flash Ubuntu Server** 64 bits on each Raspberry Pi with USB Flash memory plugged. (Explicar más)
  - It may be that your Raspberry does not have USB boot enabled by default, in which case you will need an SD card to [update the firmware and boot options](https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb) using the [Raspberry Pi Imager tool](https://github.com/raspberrypi/rpi-imager)

2. **Connect** each Raspberry to power and router.
  - Make sure your router provides static IP addresses to the Raspberries.
  - We will use the following hostname mapping (IP addresses may change depending on your router configuration):

    ```
    192.168.0.100   rpi4-master
    192.168.0.101   rpi4-slave1
    192.168.0.102   rpi4-slave2
    192.168.0.103   rpi4-slave3
    ```

3. **Update the system**. Turn on each Raspberry and run on them:

    ```bash
    sudo apt update
    sudo apt upgrade
    ```

4. **Update `/etc/hosts`**. On each Raspberry:

    ```bash
    sudo bash -c "cat <<EOF >> /etc/hosts

    192.168.0.100   rpi4-master                                                     
    192.168.0.101   rpi4-slave1                                                     
    192.168.0.102   rpi4-slave2                                                     
    192.168.0.103   rpi4-slave3  
    EOF"
    ```

5. **Update `/etc/hostname`**. On *rpi4-master*:

    ```bash
    sudo -c "echo 'rpi4-master' > /etc/hostname"
    ```

  - Repeat the process for *rpi4-slave1*, *rpi4-slave2* and *rpi4-slave3* by replacing *rpi4-master* with these. 

6. **Load `br_netfilter` and `overlay`** kernel modules on system boot of each Raspberry:

    ```bash
    sudo bash -c "cat <<EOF >> /etc/modules-load.d/k8s-modules.conf
    br_netfilter
    overlay
    EOF"
    ```

  - To explicitly load in current session:

    ```bash
    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```

7. **Forwarding IPv4** and letting **iptables see bridged traffic** on each Raspberry:

    ```bash
    sudo bash -c "cat <<EOF >> /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip-forward = 1
    EOF"
    ```

  - Apply `sysctl` params without reboot:

    ```bash
    sudo sysctl --system
    ```

8. **Install `containerd`** as [CRI](https://kubernetes.io/docs/concepts/architecture/cri/) on each Raspberry.

    ```bash
    sudo apt install -y containerd
    ```

  - Set default configuration and activate *SystemdCgroup*:

    ```bash
    sudo bash -c "containerd config default | tee /etc/containerd/config.toml"
    sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
    sudo systemctl restart containerd
    ```

9. **Disable Swap**

    ```bash
    sudo swapoff -a
    ```

10. **Install `kubeadm`, `kubelet` and `kubectl`** on each Raspberry.

    ```bash
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl

    # Add kubernetes key to Ubuntu
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

    *The kubelet is now **restarting every few seconds**, as it waits in a crashloop for kubeadm to tell it what to do.*

11. **Init Control Pane** on *rpi4-master*:

    ```bash
    sudo kubeadm init --control-plane-endpoint=rpi4-master --pod-network-cidr=10.200.0.0/16
    ```

  - **IMPORTANT**: The choice of cidr depends on the network configuration. Make sure that the network you use as cidr *does not overlap* your local network (in my case, calico's default cidr *192.168.0.0/16* overlapped my network causing dns failures). We will use *10.200.0.0/16* as the cidr in this case.

  - At the end of the process, a text similar to this will be displayed on the console:
  
    ```log
        Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config

    Alternatively, if you are the root user, you can run:

      export KUBECONFIG=/etc/kubernetes/admin.conf

    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
      https://kubernetes.io/docs/concepts/cluster-administration/addons/

    You can now join any number of control-plane nodes by copying certificate authorities
    and service account keys on each node and then running the following as root:

      kubeadm join rpi4-master:6443 --token <YOUR-TOKEN> \
    	--discovery-token-ca-cert-hash <YOUR-TOKEN-CERT-HASH> \
    	--control-plane 

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join rpi4-master:6443 --token <YOUR-TOKEN> \
    	--discovery-token-ca-cert-hash <YOUR-TOKEN-CERT-HASH> 
    ```

  - Configure the cluster as indicated in the previous output:

    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
  - You can copy the configuration file to any machine that has visibility to *rpi4-master* to connect to the cluster.

12. **Install Calico** as [CNI](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) of the cluster (from any machine with the cluster configured):

  - Download the latest version of Calico available from the [official site](https://projectcalico.docs.tigera.io/getting-started/kubernetes/self-managed-onprem/onpremises). For example, for version 3.24.3:

    ```bash
    curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/calico.yaml -O
    ```

  - Search for *CALICO_IPV4POOL_CIDR* and you will find a commented environment variable with this name:

    ```yaml
    # The default IPv4 pool to create on startup if none exists. Pod IPs will be
    # chosen from this range. Changing this value after installation will have
    # no effect. This should fall within `--cluster-cidr`.              
    # - name: CALICO_IPV4POOL_CIDR                                      
    #   value: "192.168.0.0/16"    
    ```

  - Uncomment and replace the new cidr *10.200.0.0/16*:

    ```yaml
    # The default IPv4 pool to create on startup if none exists. Pod IPs will be
    # chosen from this range. Changing this value after installation will have
    # no effect. This should fall within `--cluster-cidr`.              
    - name: CALICO_IPV4POOL_CIDR                                      
      value: "10.200.0.0/16"    
    ```
  
  - Install Calico:

    ```bash
    kubectl apply -f calico.yaml
    ```
    
13. **Join Worker Nodes** 
  - Execute the command shown at the end of the output of step 11. *YOUR-TOKEN* and *YOUR-TOKEN-CERT-HASH* will have the values for your installation:

    ```bash
    kubeadm join rpi4-master:6443 --token <YOUR-TOKEN> \
    	--discovery-token-ca-cert-hash <YOUR-TOKEN-CERT-HASH> 
    ```

  - You will need to run `kubeadm join ...` on *rpi4-slave1*, *rpi4-slave2* and *rpi4-slave3*.

14. **Check your cluster** (from any machine with the cluster configured):

  - Install dns utils:

    ```bash
    kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml
    ```

  - Wait for *Running* status:

    ```bash
    kubectl get pods dnsutils
    ```

    ```log
    NAME      READY     STATUS    RESTARTS   AGE
    dnsutils   1/1       Running   0          <some-time>
    ```




## Recommended Additions
### Monitoring
### NFS storage
### NFS volume provisioner
### Cert Manager
### Docker Registry
## Troubleshooting
### Can't resolve image reference (*Error: ImagePullBackOff*)
The pod goes into a restart loop because it cannot resolve the image registry. You should see a log message similar to this:

 ```
 Failed to pull image "registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3": rpc error: code = Unknown desc = failed to pull and unpack image "registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3": failed to resolve reference "registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3": failed to do request: Head "https://registry.k8s.io/v2/e2e-test-images/jessie-dnsutils/manifests/1.3": dial tcp: lookup registry.k8s.io: Temporary failure in name resolution
 ```

## References
- [Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Vladimir Cicovic video](https://www.youtube.com/watch?v=L9kN7E2RN3A)
