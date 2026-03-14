#!/bin/sh

TARGET_EXE=rkmppenc
TARGET_OS=$1
PKG_TYPE=$2
OUTPUT_DIR=`pwd`/../output
NPROC=$(grep 'processor' /proc/cpuinfo | wc -l)
FFMPEG_PREFIX=/opt/build_scripts/ffmpeg_dll/build_dll/arm64/build

mkdir -p ${OUTPUT_DIR}

rm -rf AviSynthPlus vapoursynth
git clone https://github.com/AviSynth/AviSynthPlus.git AviSynthPlus
git clone -b R72 --depth 1 https://github.com/vapoursynth/vapoursynth.git vapoursynth

docker build -t build_${TARGET_EXE}_${TARGET_OS} -f docker/docker_${TARGET_OS} .

RUN_NAME=build_pkg_${TARGET_EXE}_${TARGET_OS}
docker run -dit --rm \
  -v "$(pwd)":/work \
  -v ${OUTPUT_DIR}:/output \
  -u "$(id -u):$(id -g)" \
  --workdir /work \
  --name ${RUN_NAME} \
  -e FFMPEG_PREFIX=${FFMPEG_PREFIX} \
  -e PKG_CONFIG_PATH=${FFMPEG_PREFIX}/lib/pkgconfig \
  build_${TARGET_EXE}_${TARGET_OS}

docker exec ${RUN_NAME} bash -lc '
  meson setup ./build . --buildtype=release -Db_lto=true -Dcpp_args="['\''-I/work/AviSynthPlus/avs_core/include'\'','\''-I/work/vapoursynth/include'\'']"
'
docker exec ${RUN_NAME} bash -lc "meson compile -C ./build -j${NPROC}"
docker exec ${RUN_NAME} ./build/${TARGET_EXE} --version
docker exec ${RUN_NAME} ./check_options.py -exe ./build/${TARGET_EXE}
docker exec ${RUN_NAME} cp ./build/${TARGET_EXE} ./${TARGET_EXE}
docker exec ${RUN_NAME} ./build_${PKG_TYPE}.sh
docker exec ${RUN_NAME} sh -c "cp -v ./*.${PKG_TYPE} /output/"

rm -rf AviSynthPlus vapoursynth
