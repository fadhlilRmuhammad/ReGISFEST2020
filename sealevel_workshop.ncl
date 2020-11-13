;SEA LEVEL EXTRACTION AND DOWNSCALING SCRIPT
;Author: Fadhlil Rizki Muhammad
;*Departemen Geofisika dan Meteorologi, IPB University
;*Current: Scool of Earth Science, University of Melbourne

;If you use this, please cite

;Select date range
datestart = 19930101
dateend   = 20181231

print("REGISFEST Workshop 2020")
print("Thank you for using this script, please cite ..... If you have any questions, feel free to contact fadhlirizki@student.unimelb.edu.au")
f_cc  = addfile("http://tides.big.go.id:8080/thredds/dodsC/InaROMS/InaROMS_rcp45_2006_2040.nc" , "r")  ; Downloading Climate change data
f_obs = addfile("ssh.pekalongan.obs.nc", "r") ;Observation data from CMEMS, can be any data

;Getting variable names
vname = getfilevarnames(f_cc)
print(vname)
;printVarSummary (vname)

;Setting the Area
latS = -6.9
latN = -6.5
lonL = 109.5
lonR = 109.75

;Getting variables (projections)
ssh = f_cc->SSH(: , {latS:latN}, {lonL:lonR})
time = f_cc->OCEAN_TIME

;Getting variables (Observations)
time_obs = f_obs->time

date_obs = cd_calendar(time_obs, -2)
idate = ind(date_obs.ge.datestart.and.date_obs.le.dateend)

ssh_obs_in = int2flt(f_obs->adt(idate, {latS:latN}, {lonL:lonR}))
;printVarSummary(ssh_obs_in)

ssh_obs = ssh_obs_in * ssh_obs_in@scale_factor
copy_VarMeta(ssh_obs_in, ssh_obs)
;Using areal average
ssh_aave = wgt_areaave_Wrap(ssh, 1.0, 1.0, 0)
ssh_obs_aave = wgt_areaave_Wrap(ssh_obs, 1.0, 1.0, 0)

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

;printVarSummary(ssh_aave_yavg)
;printVarSummary(ssh_aave_obs_mon)

;DOWNSCALING
ystrt   = 2006
ylast   = 2018


;USING DELTA METHOD
print("creating correction factor...")
model_avg  = dim_avg_n_Wrap(ssh_aave_yavg(0:(ylast - ystrt)), 0)
obs_avg    = dim_avg_n_Wrap(ssh_aave_obs_yavg((ystrt - 1993):(ylast - 1993)), 0)
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
mixed_ssh = new((/(2040 - 1993 + 1)/), double)

j = 2018 - 2006
do i = 0, (2040 - 1993)
  if (i.le.(2018 - 1993)) then
    mixed_ssh(i) = ssh_aave_obs_yavg(i)
  else
    mixed_ssh(i) = (/model_corrected(j)/)
    j = j + 1
  end if
end do

;print(mixed_ssh)


;OUTPUT

print("creating climate-change output, please wait...")
outname_cc  = "ssh.pekalongan.RCP45.nc"  ;Setting sea level projection output name for later use
system ("rm "+outname_cc)  ;removing file with same name

;setfileoption("nc","Format","LargeFile")
fout = addfile(outname_cc , "c")
fout->ssh = ssh
fout->latitude = f_cc->LAT({latS:latN})
fout->longitude = f_cc->LON({lonL:lonR})
fout->time = time

print("creating observation output, please wait...")
outname_cc  = "ssh.pekalongan.obs.nc"  ;Setting sea level output name for later use
system ("rm "+outname_cc)  ;removing file with same name

;setfileoption("nc","Format","LargeFile")
fout = addfile(outname_cc , "c")
fout->ssh = ssh_obs
fout->latitude = f_obs->latitude({latS:latN})
fout->longitude = f_obs->longitude({lonL:lonR})
fout->time_obs = time

print("creating yearly data (csv), please wait...")

fname1 = "sealevel_pekalongan_mixed.csv"

yearspan = ispan(1993,2040,1)
hlist = [/"year", "SSH_obs", "SSH_mixed"/]
alist = [/yearspan, ssh_aave_obs_yavg, mixed_ssh/]

write_table(fname1, "w", hlist, "%s,%s,%s")
write_table(fname1, "a", alist, "%d,%3.3f,%3.3f")


fname2 = "sealevel_pekalongan_RCP45.csv"

yearspan_rcp = ispan(2006,2040,1)
hlist = [/"year", "SSH_RCP45", "SSH_corrected"/]
alist = [/yearspan_rcp, ssh_aave_yavg, model_corrected/]

write_table(fname2, "w", hlist, "%s,%s,%s")
write_table(fname2, "a", alist, "%d,%3.3f,%3.3f")

print("Finished, have a good day :)")
print("mail: fadhlilrizki@student.unimelb.edu.au")
print("mail: fadhlilmuhammad6@gmail.com")
