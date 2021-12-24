# SpotRun5
This repository captures what I have done to digest images collected for spot acquisition during Run5.

I used 13162 (B protocol) for making calibrations (super bias, super dark, defects).

I processed a single sensor as it came out one-by-one.

The command to process images is:
    srun --pty --cpus-per-task=16 --mem-per-cpu=8G  --time=24:00:00  bash -x R03_S12.sh
