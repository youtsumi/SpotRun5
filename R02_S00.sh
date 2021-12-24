#!/bin/sh +x
### srun --pty --cpus-per-task=16 --mem-per-cpu=8G  --time=24:00:00  bash -x bias.sh 

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
export output=u/youtsumi/Run5/run_R02_S00
#export yamldir=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/mixcoatl/pipelines
export yamldir=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/cp_pipe/pipelines/
export superdark=${output}
export superbias=${output}
export superflat=${output}
export defects=${output}
export workdir=${REPO}/u/youtsumi/Run5/work

if test ! -f "${workdir}"; then
    mkdir -p ${workdir}
fi
cd ${workdir}

source /cvmfs/sw.lsst.eu/linux-x86_64/lsst_distrib/w_2021_51/loadLSST.bash
setup lsst_distrib

#butler query-datasets ${REPO} --where "instrument='LSSTCam' and exposure.observation_type='bias' and detector=9 and exposure.science_program='13162'"
#
#butler query-dimension-records  /sdf/group/lsst/camera/IandT/repo_gen3/BOT_data/ detector
#
#(lsst-scipipe-0.7.0-ext) [youtsumi@sdf-login02 202112]$ butler query-dimension-records  /sdf/group/lsst/camera/IandT/repo_gen3/BOT_data/ detector | grep R02 | grep S00
#   LSSTCam   9   R02_S00          S00  R02   SCIENCE

#pipetask run \
#    -b ${REPO} \
#    -i LSSTCam/raw/all,LSSTCam/calib \
#    -d "instrument='LSSTCam' AND exposure.observation_type='bias' and detector = 9 and  exposure.science_program IN ('13162')" \
#    -o ${output}/sbias \
#    -p ${yamldir}/cpBias.yaml \
#    --register-dataset-types \
#    -j 64

### Certify superbias as a calibration
#butler certify-calibrations ${REPO} ${output}/sbias ${output}/calib bias


#pipetask run \
#    -b ${REPO} \
#    -i LSSTCam/raw/all,LSSTCam/calib,${output}/calib \
#    -d "instrument='LSSTCam' AND exposure.observation_type='dark' and detector = 9 and  exposure.science_program IN ('13162')" \
#    -o ${output}/sdark \
#    -p /sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/yaml/cpDark.yaml \
#    --register-dataset-types \
#    -j 64

#butler certify-calibrations ${REPO} ${output}/sdark ${output}/calib dark

#pipetask run \
#    -b ${REPO} \
#    -d "instrument='LSSTCam' AND exposure.observation_type='bias' and detector = 9 and exposure.science_program IN ('13162')" \
#    -i LSSTCam/raw/all,LSSTCam/calib,${output}/calib \
#    -o ${output}/defects  \
#    -p /sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/yaml/findDefects.yaml \
#    --register-dataset-types \
#    -j 64
#
#butler certify-calibrations ${REPO} ${output}/defects ${output}/calib defects

PYTHONPATH=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/mixcoatl/python:$PYTHONPATH pipetask run \
    -b ${REPO} \
    -i LSSTCam/raw/all,LSSTCam/calib,${output}/calib \
    -d "instrument='LSSTCam' AND exposure.observation_type='spot' and detector = 9 and exposure.science_program IN ('13230','13231')" \
    -o ${output}/spot \
    -p /sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/202112/yaml/cpSpot2.yaml \
    --register-dataset-types -j 64
