# rpi4-k8s
Recipe to build a kubernetes cluster with [Raspberry Pi 4 model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)

# Hardware

- 4x Raspberry Pi 4 model B
- 4x USB Flash memory (128GB)
- 4x USB cable to power Raspberries
- 4x Ethernet cable to network Raspberries
- 1x Router with internet connection and at least 4 free ethernet ports
- 1x Power strip with:
  - 4x 10.0V 6.5A USB power supply ports for raspberries
- (Optional) 1x 2TB External SDD

# Steps

1. Flash Ubuntu Server 64 bits on each Raspberry Pi with USB Flash memory plugged.
  - It may be that your Raspberry does not have USB boot enabled by default, in which case you will need an SD card to [update the firmware and boot options](https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb) using the [Raspberry Pi Imager tool](https://github.com/raspberrypi/rpi-imager)

2. Connect each Raspberry to power and router.
  - Make sure your router provides static IP addresses to the Raspberries.
  - We will use the following hostname mapping (IP addresses may change depending on your router configuration):

```
192.168.0.100   rpi4-master
192.168.0.101   rpi4-slave1
192.168.0.102   rpi4-slave2
192.168.0.103   rpi4-slave3
```

3. Update the system. Turn on each raspberry and run on each of them:

```
sudo apt update
sudo apt upgrade
```

4. Update `/etc/hosts`. On each Raspberry:

```
sudo bash -c "cat <<EOF >> /etc/hosts

192.168.0.100   rpi4-master                                                     
192.168.0.101   rpi4-slave1                                                     
192.168.0.102   rpi4-slave2                                                     
192.168.0.103   rpi4-slave3  
EOF"
```

5. Update `/etc/hostname`. On *rpi4-master* Raspberry (arbitrarily choose one of them):

```bash
sudo -c "echo 'rpi4-master' > /etc/hostname"
```

Repeat the process for *rpi4-slave1*, *rpi4-slave2* and *rpi4-slave3*. 

6. Load `br_netfilter` and `overlay` kernel modules on system startap of each Raspberry:

```
sudo bash -c "cat <<EOF >> /etc/modules-load.d/k8s-modules.conf
br_netfilter
overlay
EOF"
```

To explicitly load in current session:

```
sudo modprobe overlay
sudo modprobe br_netfilter
```

7. Forwarding IPv4 and letting iptables see bridged traffic on each Raspberry:

```
sudo bash -c "cat <<EOF >> /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip-forward = 1
EOF"
```

Apply sysctl params without reboot:

```
sudo sysctl --system
```

8. Installing `containerd` as [CRI](https://kubernetes.io/docs/concepts/architecture/cri/) on each Raspberry.

```
sudo apt install -y containerd
```

Set default configuration and activate Systemd Cgroup:

```
sudo bash -c "containerd config default | tee /etc/containerd/config.toml"
sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml"
sudo systemctl restart containserd
```

9. Disable Swap

```
sudo swapoff -a
```

10. Install kubeadm, kubelet and kubectl on each Raspberry.

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

**The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.**



# Troubleshooting
# References
- [Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Vladimir Cicovic video](https://www.youtube.com/watch?v=L9kN7E2RN3A)
