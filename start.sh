#!/bin/bash

#set -eu

### Handle `docker stop` for graceful shutdown
function shutdown {
    touch /tmp/bbbb
    exit 0
}

trap "shutdown" SIGTERM
####

target=/etc/sysconfig/nfs
sed -i "s#^RPCMOUNTDOPTS.*#RPCMOUNTDOPTS=\"-p 32767\"#g" $target
if ! cat $target | grep ^MOUNTD_PORT > /dev/null 2>&1;
then
cat >> $target <<EOF
MOUNTD_PORT=892
STATD_PORT=662
EOF
fi

target=/etc/sysctl.conf
if ! cat $target | grep ^fs.nfs.nfs_callback_tcpport > /dev/null 2>&1;
then
cat >> $target <<EOF
fs.nfs.nfs_callback_tcpport = 32764
fs.nfs.nlm_tcpport = 32768
fs.nfs.nlm_udpport = 32768
EOF
fi

export_base="/exports/"

#echo "$export_base *(rw,sync,insecure,fsid=0,no_subtree_check,no_root_squash)" | tee /etc/exports
echo "$export_base *(insecure,rw,async,no_root_squash)" | tee /etc/exports

read -a exports <<< "${@}"
for export in "${exports[@]}"; do
    src=`echo "$export" | sed 's/^\///'` # trim the first '/' if given in export path
    src="$export_base$src"
    mkdir -p $src
    chmod 777 $src
    echo "$src *(rw,sync,insecure,no_subtree_check,no_root_squash)" | tee -a /etc/exports
done

sysctl --system
#/usr/sbin/rpcbind -w
#/usr/sbin/rpc.idmapd
#/usr/sbin/rpc.statd --no-notify -p 662 -o 2020
#/usr/sbin/rpc.mountd -p 892
#/usr/sbin/rpc.nfsd
systemctl restart rpcbind
systemctl restart nfs-idmap
systemctl restart nfslock
systemctl restart nfs

exportfs -a
sleep 3
exportfs -a

# Run forever
sleep infinity
