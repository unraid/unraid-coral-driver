# Download source
cd ${DATA_DIR}
mkdir -p ${DATA_DIR}/apex /CORAL/lib/modules/${UNAME}/extra

 # Check to apply patches
TARGET_V="6.12.0"
COMPARE="${UNAME%%-*}
$TARGET_V"
if [ "$TARGET_V" != "$(echo "$COMPARE" | sort -V | tail -1)" ]; then
TARGET_V="6.13.0"
COMPARE="${UNAME%%-*}
$TARGET_V"
if [ "$TARGET_V" != "$(echo "$COMPARE" | sort -V | tail -1)" ]; then
TARGET_V="6.14.0"
COMPARE="${UNAME%%-*}
$TARGET_V"
if [ "$TARGET_V" != "$(echo "$COMPARE" | sort -V | tail -1)" ]; then
cd ${DATA_DIR}/apex
cp ${DATA_DIR}/gasket_6.14.0.patch ${DATA_DIR}/apex/gasket_6.14.0.patch
patch -p1 < ${DATA_DIR}/apex/gasket_6.14.0.patch
else
cd ${DATA_DIR}/apex
cp ${DATA_DIR}/gasket_6.13.0.patch ${DATA_DIR}/apex/gasket_6.13.0.patch
patch -p1 < ${DATA_DIR}/apex/gasket_6.13.0.patch
fi
else
cd ${DATA_DIR}/apex
cp ${DATA_DIR}/gasket_6.12.0.patch ${DATA_DIR}/apex/gasket_6.12.0.patch
patch -p1 < ${DATA_DIR}/apex/gasket_6.12.0.patch
fi
fi

# Compile modules
cd ${DATA_DIR}/apex/src
make -j${CPU_COUNT}
cp ${DATA_DIR}/apex/src/*.ko /CORAL/lib/modules/${UNAME}/extra

#Compress modules
while read -r line
do
  xz --check=crc32 --lzma2 $line
done < <(find /CORAL/lib/modules/${UNAME}/extra -name "*.ko")

# Create Slackware package
PLUGIN_NAME="Coral"
BASE_DIR="/CORAL"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"
mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://coral.googlesource.com/linux-imx/+/refs/heads/master/drivers/staging/gasket/
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5
