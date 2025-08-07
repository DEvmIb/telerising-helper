if ! hash file wget fuse3 &>/dev/null
then
	apt -y install file wget fuse3
fi

_app_image_build=https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-armhf.AppImage 
wget -q "$_app_image_build" -O appimagetool.AppImage
chmod +x appimagetool.AppImage
./appimagetool.AppImage skelet_armhf_raspbian armhf_raspbian.AppImage
rm appimagetool.AppImage
