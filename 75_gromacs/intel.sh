#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname $0)"; pwd)
. $SCRIPT_DIR/../util.sh
. $SCRIPT_DIR/version.sh
set_prefix

. $PREFIX_TOOL/env.sh
LOG=$BUILD_DIR/gromacs-$GROMACS_VERSION-$GROMACS_MA_REVISION.log
PREFIX="$PREFIX_APPS/gromacs/gromacs-$GROMACS_VERSION-$GROMACS_MA_REVISION"

if [ -d $PREFIX ]; then
  echo "Error: $PREFIX exists"
  exit 127
fi

sh $SCRIPT_DIR/setup.sh
rm -rf $LOG
cd $BUILD_DIR/gromacs-$GROMACS_VERSION
start_info | tee -a $LOG
echo "[make]" | tee -a $LOG
if [ -n "$FFTW_ROOT" ]; then
  check ./configure --prefix=$PREFIX CC=$(which icc) CXX=$(which icpc) CPPFLAGS="-I$FFTW_ROOT/include" LDFLAGS="-L$FFTW_ROOT/lib" | tee -a $LOG
else
  check ./configure --prefix=$PREFIX CC=$(which icc) CXX=$(which icpc) | tee -a $LOG
fi
check make | tee -a $LOG
echo "[make install]" | tee -a $LOG
make install | tee -a $LOG
check make distclean | tee -a $LOG
echo "[make mdrun_mpi]" | tee -a $LOG
if [ -n "$FFTW_ROOT" ]; then
  check ./configure --prefix=$PREFIX CC=$(which icc) CXX=$(which icpc) CPPFLAGS="-I$FFTW_ROOT/include" LDFLAGS="-L$FFTW_ROOT/lib" --enable-mpi --program-suffix=_mpi | tee -a $LOG
else
  check ./configure --prefix=$PREFIX CC=$(which icc) CXX=$(which icpc) --enable-mpi --program-suffix=_mpi | tee -a $LOG
fi
check make mdrun | tee -a $LOG
make install-mdrun | tee -a $LOG
finish_info | tee -a $LOG

cat << EOF > $BUILD_DIR/gromacsvars.sh
# gromacs $(basename $0 .sh) $GROMACS_VERSION $GROMACS_MA_REVISION $(date +%Y%m%d-%H%M%S)
test -z "\$MA_ROOT_TOOL" && . $PREFIX_TOOL/env.sh
export GROMACS_ROOT=$PREFIX
export GROMACS_VERSION=$GROMACS_VERSION
export GROMACS_MA_REVISION=$GROMACS_MA_REVISION
. \$GROMACS_ROOT/bin/GMXRC.bash
EOF
GROMACSVARS_SH=$PREFIX_APPS/gromacs/gromacsvars-$GROMACS_VERSION-$GROMACS_MA_REVISION.sh
rm -f $GROMACSVARS_SH
cp -f $BUILD_DIR/gromacsvars.sh $GROMACSVARS_SH
rm -f $BUILD_DIR/gromacsvars.sh
cp -f $LOG $PREFIX_APPS/gromacs/
