#!/bin/sh +x
### srun --pty --cpus-per-task=16 --mem-per-cpu=8G  --time=24:00:00  bash -x bias.sh 
#butler query-datasets ${REPO} --where "instrument='LSSTCam' and exposure.observation_type='bias' and detector=23 and exposure.science_program='13162'"
#
#butler query-dimension-records  /sdf/group/lsst/camera/IandT/repo_gen3/BOT_data/ detector
#
#butler query-dimension-records  /sdf/group/lsst/camera/IandT/repo_gen3/BOT_data/ detector | grep R03 | grep S12
#   LSSTCam  23   R24_S11          S12  R03   SCIENCE
# what column can be used for searching images in exposure
#butler query-dimension-records   /sdf/group/lsst/camera/IandT/repo_gen3/BOT_data/ exposure | less

#SBATCH --partition=shared
#
#SBATCH --job-name=my_pipeline_job
#SBATCH --output=my_pipeline_job-%j.txt
#SBATCH --error=my_pipeline_job-%j.txt
#
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2G
#
#SBATCH --time=24:00:00

# https://github.com/lsst/cp_pipe
#
export REPO=/sdf/group/lsst/camera/IandT/repo_gen3/BOT_data/
export base=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/
export yamldir=${base}/yaml/
export mixcotalpath=${base}/mixcoatl/python
export superdark=${output}
export superbias=${output}
export superflat=${output}
export defects=${output}
export workdir=${REPO}/u/youtsumi/Run5/work
export detector=112
export output=u/youtsumi/Run5/run_R24_S11
export runs="('13239','13240')"

if test ! -f "${workdir}"; then
    mkdir -p ${workdir}
fi
cd ${workdir}

source /cvmfs/sw.lsst.eu/linux-x86_64/lsst_distrib/w_2021_52/loadLSST.bash
setup lsst_distrib
setup -r /sdf/home/j/jchiang/dev/daf_butler -j

pipetask run \
    -b ${REPO} \
    -i LSSTCam/raw/all,LSSTCam/calib \
    -d "instrument='LSSTCam' AND exposure.observation_type='bias' and detector = ${detector} and  exposure.science_program IN ('13162')" \
    -o ${output}/sbias \
    -p ${yamldir}/cpBias.yaml \
    --register-dataset-types \
    -j 64

## Certify superbias as a calibration
butler certify-calibrations ${REPO} ${output}/sbias ${output}/calib bias


pipetask run \
    -b ${REPO} \
    -i LSSTCam/raw/all,LSSTCam/calib,${output}/calib \
    -d "instrument='LSSTCam' AND exposure.observation_type='dark' and detector = ${detector} and  exposure.science_program IN ('13162')" \
    -o ${output}/sdark \
    -p ${yamldir}/cpDark.yaml \
    --register-dataset-types \
    -j 64

butler certify-calibrations ${REPO} ${output}/sdark ${output}/calib dark

pipetask run \
    -b ${REPO} \
    -d "instrument='LSSTCam' AND exposure.observation_type='bias' and detector = ${detector} and exposure.science_program IN ('13162')" \
    -i LSSTCam/raw/all,LSSTCam/calib,${output}/calib \
    -o ${output}/defects  \
    -p ${yamldir}/findDefects.yaml \
    --register-dataset-types \
    -j 64

butler certify-calibrations ${REPO} ${output}/defects ${output}/calib defects

PYTHONPATH=${mixcotalpath}:${PYTHONPATH} pipetask run \
    -b ${REPO} \
    -i LSSTCam/raw/all,LSSTCam/calib,${output}/calib \
    -d "instrument='LSSTCam' AND exposure.observation_type='spot' and detector = ${detector} and exposure.science_program IN ${runs}" \
    -o ${output}/spot \
    -p ${yamldir}/cpSpot2.yaml \
    --register-dataset-types -j 64
