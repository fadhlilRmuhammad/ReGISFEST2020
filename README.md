# ReGISFEST2020

Indonesian Sea-Level Rise Downloader and Corrector.

Pastikan komputer sudah ter-install Ubuntu subsystem, Miniconda, dan NCL.
  Ubuntu subsystem: https://ubuntu.com/wsl
  Miniconda       : https://docs.conda.io/en/latest/miniconda.html (running menggunakan ubuntu subsystem, pilih linux installers)
  NCL             : https://www.ncl.ucar.edu/Download/conda.shtml

Step running=>
  1. Buka terminal ubuntu subsystem 
  2. Tulis di terminal: conda activate ncl_stable
  3. Tulis di terminal: ncl sealevel_workshop.ncl

Penjelasan variabel untuk sealevel_workshop.ncl
  f_cc  => data nc sealevel dari BIG.
  f_obs => data nc sealevel dari CMEMS (bisa diganti dengan data lainnya, bentuk nc).

Please cite:
[![DOI](https://zenodo.org/badge/312565304.svg)](https://zenodo.org/badge/latestdoi/312565304)
