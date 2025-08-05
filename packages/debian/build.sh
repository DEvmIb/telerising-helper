# debian apt remove will /opt löschen

_ver=$1
_arch=$2

if [ -d telerising-$_ver-$_arch ]
then
    rm -r telerising-$_ver-$_arch
fi

cp -R skelet telerising-$_ver-$_arch

sed -i "s#{version}#$_ver#g" telerising-$_ver-$_arch/usr/share/telerising-service/run.sh
sed -i "s#{version}#$_ver#g" telerising-$_ver-$_arch/DEBIAN/control

chmod 0755 telerising-$_ver-$_arch/DEBIAN/preinst
chmod 0755 telerising-$_ver-$_arch/DEBIAN/postinst
chmod 0755 telerising-$_ver-$_arch/DEBIAN/prerm
chmod 0755 telerising-$_ver-$_arch/DEBIAN/postrm
chmod 0755 telerising-$_ver-$_arch/usr/share/telerising-service/initrd.install.sh
chmod 0755 telerising-$_ver-$_arch/usr/share/telerising-service/run.sh
chmod 0755 telerising-$_ver-$_arch/usr/bin/telerising
chmod 0755 telerising-$_ver-$_arch/etc/init.d/telerising-service

dpkg-deb -Zxz --build --root-owner-group telerising-$_ver-$_arch

if [ $? -ne 0 ]
then
    echo error build
    rm -r telerising-$_ver-$_arch
    exit 1
fi

#dpkg-deb --info telerising-$_ver-$_arch.deb

rm -r telerising-$_ver-$_arch

