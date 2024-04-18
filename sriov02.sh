#!/bin/sh
# Author: DoraCloud Technology Ltd.co
#         
# Date: 2022/05/07
#
# Enable IO-MMU on PVE Server



apt update && apt install git pve-headers pve-headers-$(uname -r) mokutil -y
rm -rf /var/lib/dkms/i915-sriov-dkms*
rm -rf /usr/src/i915-sriov-dkms*
rm -rf ~/i915-sriov-dkms
KERNEL=$(uname -r); KERNEL=${KERNEL%-pve}


apt install git dkms build-* unzip -y

wget http://vdi.doracloud.cn:9000/software/i915-sriov-dkms.tar.gz
tar -zxvf i915-sriov-dkms.tar.gz  


cd ~/i915-sriov-dkms
cp -a ~/i915-sriov-dkms/dkms.conf{,.bak}
sed -i 's/"@_PKGBASE@"/"i915-sriov-dkms"/g' ~/i915-sriov-dkms/dkms.conf
sed -i 's/"@PKGVER@"/"'"$KERNEL"'"/g' ~/i915-sriov-dkms/dkms.conf
sed -i 's/ -j$(nproc)//g' ~/i915-sriov-dkms/dkms.conf
cat ~/i915-sriov-dkms/dkms.conf


apt install  dkms -y


dkms add .
cd /usr/src/i915-sriov-dkms-$KERNEL


dkms install -m i915-sriov-dkms -v $KERNEL -k $(uname -r) --force -j 4
dkms status




# 复制如下脚本，启用IO-MMU
echo ""
echo "********************************************"
echo "***  Enable IO-MMU on proxmox host       ***"
echo "********************************************"
# /etc/default/grub 的GRUB_CMDLINE_LINUX_DEFAULT，增加 intel_iommu=on iommu=pt
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on i915.enable_guc=3 i915.max_vfs=7"/g' /etc/default/grub

echo ""
echo "    Update grub .... "
update-grub
update-initramfs -u -k all
pve-efiboot-tool refresh


echo ""
echo "    Install sysfsutils ,set sriov_numvfs=7"
apt install sysfsutils -y
echo "devices/pci0000:00/0000:00:02.0/sriov_numvfs = 7" > /etc/sysfs.conf

echo ""
echo "   Please Verify SR-IOV by lspci |grep VGA after reboot ...."
reboot



