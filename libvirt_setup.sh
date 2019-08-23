#!/usr/bin/env bash
set -xe

export USER=rna
# Restart libvirtd service to get the new group membership loaded
if ! id $USER | grep -q libvirt; then
  sudo usermod -a -G "libvirt" $USER
  sudo systemctl restart libvirtd
fi

# As per https://github.com/openshift/installer/blob/master/docs/dev/libvirt-howto.md#configure-default-libvirt-storage-pool
# Usually virt-manager/virt-install creates this: https://www.redhat.com/archives/libvir-list/2008-August/msg00179.html
if ! virsh pool-uuid default > /dev/null 2>&1 ; then
    virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
EOF
    virsh pool-start default
    virsh pool-autostart default
fi

# Create the provisioning bridge
if ! virsh net-uuid provisioning > /dev/null 2>&1 ; then
    virsh net-define /dev/stdin <<EOF
<network>
  <name>provisioning</name>
  <bridge name='provisioning'/>
  <forward mode='bridge'/>
</network>
EOF
    virsh net-start provisioning
    virsh net-autostart provisioning
fi

# Create the baremetal bridge
if ! virsh net-uuid baremetal > /dev/null 2>&1 ; then
    virsh net-define /dev/stdin <<EOF
<network>
  <name>baremetal</name>
  <bridge name='baremetal'/>
  <forward mode='bridge'/>
</network>
EOF
    virsh net-start baremetal
    virsh net-autostart baremetal
fi
