;trend_dataSEA LEVEL EXTRACTION AND DOWNSCALING SCRIPT
;Author: Fadhlil Rizki Muhammad
;*Departemen Geofisika dan Meteorologi, IPB University
;*Current: Scool of Earth Science, University of Melbourne

;If you use this, please cite


MODE = 0 ; Choose MODE: grab-correction (0), GRABONLY (1)
SPATIAL = True

;DO NOT CHANGE THIS FOR GRAB-CORRECTION MODE (MODE = 0)!
var = "SSH"  ;FOR GRABONLY MODE YOU CAN USE ONE OF THESE (SSH, U_VEL, V_VEL, SALT, SST)

wilayah = "pekalongan"
;SPATIAL DATA OUTNAME
outputname_nc_RCP45  = "ssh."+wilayah+".RCP45.nc"
outputname_nc_OBS    = "ssh."+wilayah+".obs.nc"

;TEMPORAL ONLY OUTNAME
outputname_csv_mixed = "sealevel_"+wilayah+"_mixed.csv"
outputname_csv_RCP45 = "sealevel_"+wilayah+"_RCP45.csv"

;SET INPUT FILE
CLIMCHANGE_INPUT     = "http://tides.big.go.id:8080/thredds/dodsC/InaROMS/InaROMS_rcp45_2006_2040.nc"
OBSERVATION_INPUT    = "sealevel_indo.nc" ;or ssh.pekalongan.RCP45.nc

if(SPATIAL) then
  outputname_nc_mixed_spatial = "Spatial_"+outputname_nc_RCP45
end if

;if (wilayah.eq."pekalongan") then;
;  latS = -7.125
;  latN = -5.875
;  lonL = 108.875
;  lonR = 110.125
;else if (wilayah.eq."gunungkidul") then
;  latS = -9.625
;  latN = -7.625
;  lonL = 109.375
;  lonR = 111.125
;end if
;end if


Setting the Area
latS = -7.125
latN = -6.375
lonL = 109.375
lonR = 110.125

print("REGISFEST Workshop 2020")
print("Thank you for using this script, please cite https://github.com/fadhlilRmuhammad/ReGISFEST2020. If you have any questions, feel free to contact fadhlirizki@student.unimelb.edu.au")
f_cc  = addfile( CLIMCHANGE_INPUT, "r")  ; Downloading Climate change data

;Getting variable names
vname = getfilevarnames(f_cc)
print(vname)
;printVarSummary (vname)

if (MODE.eq.0) then
print("RUNNING GRAB-CORRECTION MODE- INITIATING....")

;Getting variables (projections)
ssh = f_cc->$var$(: , {latS:latN}, {lonL:lonR})
time = f_cc->OCEAN_TIME

datestart = 20060101      ; OBSERVATION DATA DATE START YYYYMMDD
yobstrt   = toint(datestart/10000)
print(yobstrt)

dateend   = 20181231      ; OBSERVATION DATA DATE END YYYYMMDD
yobend    = toint(dateend/10000)
print(yobend)

f_obs = addfile(OBSERVATION_INPUT, "r") ;Observation data from CMEMS, can be any data

;Getting variables (Observations)
time_obs = f_obs->time

date_obs = cd_calendar(time_obs, -2)                        ;YYYYMMDD
idate = ind(date_obs.ge.datestart.and.date_obs.le.dateend)

ystrt   = 2006             ; YEAR START FOR THE CORRECTION FACTOR PERIOD
ylast   = 2018             ; YEAR END FOR THE CORRECTION FACTOR PERIOD

;MODEL


;OBSERVATION

  ssh_obs_in = int2flt(f_obs->adt(idate, {latS:latN}, {lonL:lonR}))
  ;printVarSummary(ssh_obs_in)

  ssh_obs = ssh_obs_in * ssh_obs_in@scale_factor
  copy_VarMeta(ssh_obs_in, ssh_obs)
;Using areal average
  ssh_aave = wgt_areaave_Wrap(ssh, 1.0, 1.0, 0)         ;RCP45
  ssh_obs_aave = wgt_areaave_Wrap(ssh_obs, 1.0, 1.0, 0) ; obs

;printVarSummary(ssh_aave)
;printVarSummary(ssh_obs_aave)

;Create yearly average

print("creating yearly average, please wait")
opt = True
opt@nval_crit = 0

ssh_aave_mon = calculate_monthly_values(ssh_aave, "avg", 0, opt)
ssh_aave_obs_mon = calculate_monthly_values(ssh_obs_aave, "avg", 0, opt)

ssh_aave_yavg = month_to_annual(ssh_aave_mon, 1)
ssh_aave_obs_yavg = month_to_annual(ssh_aave_obs_mon, 1)

printVarSummary(ssh_aave_yavg)
;printVarSummary(ssh_aave_obs_mon)

;DOWNSCALING

;USING DELTA METHOD
print("creating correction factor...")


model_avg  = dim_avg_n_Wrap(ssh_aave_yavg(0:(ylast - ystrt)), 0)
obs_avg    = dim_avg_n_Wrap(ssh_aave_obs_yavg((ystrt - yobstrt):(ylast - yobstrt)), 0)
;print(correction_factor)

print("Downscaling the data...")
correction_factor = obs_avg - model_avg
model_corrected = ssh_aave_yavg + correction_factor ;
;print(model_corrected)
;print(ssh_aave_obs_yavg)

;IF YOU USE MULTIPLICATION TECHNIQUE, PLEASE UNCOMMENT THIS
;correction_factor = obs_avg/model_avg
;model_corrected = model_avg * correction factor ;USING MULTIPLICATION

print("creating mixed obs-model data...")
mixed_ssh = new((/(2040 - yobstrt + 1)/), double)

j = ylast - ystrt
do i = 0, (2040 - yobstrt)
  if (i.le.(ylast - yobstrt)) then
    mixed_ssh(i) = ssh_aave_obs_yavg(i)
  else
    mixed_ssh(i) = (/model_corrected(j)/)
    j = j + 1
  end if
end do

;print(mixed_ssh)


;OUTPUT

print("creating climate-change output, please wait...")
system ("rm "+outputname_nc_RCP45)  ;removing file with same name
;setfileoption("nc","Format","LargeFile")
fout = addfile(outputname_nc_RCP45 , "c")
fout->ssh = ssh
fout->latitude = f_cc->LAT({latS:latN})
fout->longitude = f_cc->LON({lonL:lonR})
fout->time = time

print("creating observation output, please wait...")  ;Setting sea level output name for later use
system ("rm "+outputname_nc_OBS)  ;removing file with same name
;setfileoption("nc","Format","LargeFile")
fout = addfile(outputname_nc_OBS , "c")
fout->ssh = ssh_obs
fout->latitude = f_obs->latitude({latS:latN})
fout->longitude = f_obs->longitude({lonL:lonR})
fout->time_obs = time

print("creating yearly data (csv), please wait...")

yearspan = ispan(yobstrt,2040,1)
hlist = [/"year", "SSH_obs", "SSH_mixed"/]
alist = [/yearspan, ssh_aave_obs_yavg, mixed_ssh/]

write_table(outputname_csv_mixed, "w", hlist, "%s,%s,%s")
write_table(outputname_csv_mixed, "a", alist, "%d,%3.3f,%3.3f")

yearspan_rcp = ispan(2006,2040,1)
hlist = [/"year", "SSH_RCP45", "SSH_corrected"/]
alist = [/yearspan_rcp, ssh_aave_yavg, model_corrected/]

write_table( outputname_csv_RCP45, "w", hlist, "%s,%s,%s")
write_table( outputname_csv_RCP45, "a", alist, "%d,%3.3f,%3.3f")

if(SPATIAL) then
  print("creating yearly average, please wait")
  opt = True
  opt@nval_crit = 0

  printVarSummary(ssh)
  ssh_mon_sp = calculate_monthly_values(ssh, "avg", 0, opt)
  ssh_obs_mon = calculate_monthly_values(ssh_obs, "avg", 0, opt)

  ssh_obs_mon!1 = "latitude"

  printVarSummary(ssh_obs_mon)
  ssh_yavg_sp = month_to_annual(ssh_mon_sp, 1)
  ssh_obs_yavg = month_to_annual(ssh_obs_mon, 1)


  ;DOWNSCALING

  ;USING DELTA METHOD
  print("creating correction factor...")
;  printVarSummary(ssh_yavg_regrid)
  printVarSummary(ssh_yavg_sp)
  printVarSummary(ssh_obs_yavg)

  ssh_obs_yavg_regrid = linint2_Wrap(ssh_obs_yavg&longitude, ssh_obs_yavg&latitude, ssh_obs_yavg, False, ssh_yavg_sp&LON, ssh_yavg_sp&LAT, 0 )
;  ssh_obs_yavg_regrid = ssh_obs_yavg

  printVarSummary(ssh_yavg_sp)

  model_avg_sp  = dim_avg_n_Wrap(ssh_yavg_sp(0:(ylast - ystrt),:,: ), 0)
  obs_avg_sp    = dim_avg_n_Wrap(ssh_obs_yavg_regrid((ystrt - yobstrt):(ylast - yobstrt), :, :), 0)

  printVarSummary(model_avg_sp)
  printVarSummary(obs_avg_sp)
  ;print(correction_factor)

  ssh_yavg_sp&year = ispan(2006, 2040, 1)

;AMBIL DIMENSI
  ndim = dimsizes(ssh_yavg_sp)
  ntim = ndim(0)
  nlat = ndim(1)
  nlon = ndim(2)


  print("Downscaling the data...")
  correction_factor_sp = obs_avg_sp - model_avg_sp        ; dim= (/nlat, nlon/) BUAT CORRECTION FACTOR
  correction_factor_sp_conform = new((/ntim, nlat, nlon/), "double")

  ;ngubah jadi (/ntim nlat nlon/)
  do i = 0, ntim-1
    correction_factor_sp_conform(i, :, :) = correction_factor_sp
  end do

  printVarSummary(correction_factor_sp_conform)
  printVarSummary(ssh_obs_yavg_regrid)

  model_corrected_sp = ssh_yavg_sp + correction_factor_sp_conform ; KOREKSI

  printVarSummary(model_corrected_sp)

  print("creating mixed obs-model data...")

  mixed_ssh_sp = new((/(2040 - yobstrt + 1), nlat, nlon/), double)

  mixed_ssh_sp(0:yobend-yobstrt,:,:) = ssh_obs_yavg_regrid
  mixed_ssh_sp(yobend-yobstrt+1:2040-yobstrt,:,:) = model_corrected_sp(13:34,:,:)

  mixed_ssh_sp!0 = "time"
  mixed_ssh_sp!1 = "lat"
  mixed_ssh_sp!2 = "lon"

  mixed_ssh_sp&time = ispan(yobstrt, 2040, 1)
  mixed_ssh_sp&lat  = ssh_yavg_sp&LAT
  mixed_ssh_sp&lon  = ssh_yavg_sp&LON

  print("creating climate-change output, please wait...")
  system ("rm "+outputname_nc_mixed_spatial)  ;removing file with same name
  ;setfileoption("nc","Format","LargeFile")
  fout = addfile(outputname_nc_mixed_spatial , "c")
  fout->ssh = mixed_ssh_sp
  fout->latitude = f_obs->latitude({latS:latN})
  fout->longitude = f_obs->longitude({lonL:lonR})
  fout->time = mixed_ssh_sp&time

  print("Calculating trend")

  trendname = "trend_" + outputname_nc_mixed_spatial

  trend_mixed = regCoef_n(ispan(yobstrt,2040,1), mixed_ssh_sp, 0, 0)
  trend_RCP = regCoef_n(ispan(2019,2040,1), ssh_yavg_sp(2019-2006:2040-2006,:,:), 0, 0)
  trend_obs = regCoef_n(ispan(yobstrt,yobend,1), ssh_obs_yavg_regrid, 0, 0)

  trend_mixed!0 = "latitude"
  trend_mixed&latitude = ssh_yavg_sp&LAT
  trend_mixed!1 = "longitude"
  trend_mixed&longitude = ssh_yavg_sp&LON

  trend_RCP!0 = "latitude"
  trend_RCP&latitude = ssh_yavg_sp&LAT
  trend_RCP!1 = "longitude"
  trend_RCP&longitude = ssh_yavg_sp&LON

  trend_obs!0 = "latitude"
  trend_obs&latitude = ssh_yavg_sp&LAT
  trend_obs!1 = "longitude"
  trend_obs&longitude = ssh_yavg_sp&LON

  printVarSummary(trend_mixed)

  system("rm "+trendname)
  fout = addfile(trendname , "c")
  fout->trend_mixed = trend_mixed
  fout->trend_RCP = trend_RCP
  fout->trend_obs = trend_obs

  ;fout->latitude = f_cc->LAT({latS:latN})
  ;fout->longitude = f_cc->LON({lonL:lonR})
end if


else if (MODE.eq.1) then
  print("RUNNING GRABONLY MODE- INITIATING DATA CUTTING....")
  ;Getting variables (projections)
  x = f_cc->$var$(: , {latS:latN}, {lonL:lonR})
  time = f_cc->OCEAN_TIME
  print("creating yearly average, please wait")
  opt = True
  opt@nval_crit = 0

  x_aave = wgt_areaave_Wrap(x, 1.0, 1.0, 0)
  x_aave_mon = calculate_monthly_values(x_aave, "avg", 0, opt)

  x_aave_yavg = month_to_annual(x_aave_mon, 1)

  print("creating climate-change output, please wait...")
  system ("rm "+outputname_nc_RCP45)  ;removing file with same name

  ;setfileoption("nc","Format","LargeFile")
  fout = addfile(outputname_nc_RCP45 , "c")
  fout->$var$ = x
  fout->latitude = f_cc->LAT({latS:latN})
  fout->longitude = f_cc->LON({lonL:lonR})
  fout->time = time

  yearspan_rcp = ispan(2006,2040,1)
  hlist = [/"year", var+"_RCP45"/]
  alist = [/yearspan_rcp, x_aave_yavg/]

  write_table(outputname_csv_RCP45, "w", hlist, "%s,%s")
  write_table(outputname_csv_RCP45, "a", alist, "%d,%3.3f")


end if

;delete(model_avg)
;delete(obs_avg)
;delete(correction_factor)
;delete(model_corrected)
;delete(mixed_ssh)

end if





print("Finished, have a good day :)")
print("Dont forget to cite https://github.com/fadhlilRmuhammad/ReGISFEST2020")
print("mail: fadhlilrizki@student.unimelb.edu.au")
print("mail: fadhlilmuhammad6@gmail.com")
