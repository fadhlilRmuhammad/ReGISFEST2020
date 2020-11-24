# ReGISFEST2020

Indonesian Sea-Level Rise Downloader and Corrector.
https://github.com/fadhlilRmuhammad/ReGISFEST2020/releases/edit/IndoSLR-v1.2

Pastikan komputer sudah ter-install Ubuntu subsystem, Miniconda, dan NCL.
  1. Ubuntu subsystem: https://ubuntu.com/wsl
  2. Miniconda       : https://docs.conda.io/en/latest/miniconda.html (running menggunakan ubuntu subsystem, pilih linux installers, python 3.8)
  3. NCL             : https://www.ncl.ucar.edu/Download/conda.shtml

Step running=>
  1. Buka terminal ubuntu subsystem 
  2. Tulis di terminal: conda activate ncl_stable
  3. Tulis di terminal: ncl sealevel_workshop.ncl

Penjelasan variabel untuk sealevel_workshop.ncl
  1. f_cc  => data nc sealevel dari BIG.
  2. f_obs => data nc sealevel dari CMEMS (bisa diganti dengan data lainnya, bentuk nc).

Please cite:
[![DOI](https://zenodo.org/badge/312565304.svg)](https://zenodo.org/badge/latestdoi/312565304)
