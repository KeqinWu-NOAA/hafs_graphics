;----------------------------------------------------------------------
;ncl replace=0 'graphicDir="/your/figure/dir"' 'stormModel="HAFA"' startDate=2019071506 startTimeLevel=0 endTimeLevel=11 'atcfFile="/hafs/com/2019071506/00L/natl00l.2019071506.trak.hafs.atcfunix.all"' 'stormDir="/hafs/com/2019071506/00L"' fv3_Standard_Layer_RH_Ght_Wind_plot_forstorm.ncl

;************************************************
; image for every 6 Hour
if (.not. isvar("is6Hr")) then
  is6Hr=True
end if

if ( is6Hr ) then
  maxLen = 22  ;
else
  maxLen = 43  ; number of forecasts. 43 for 126 hrs, 59 for 174 hr
end if

;-------------------------------------------------------------------
loadscript("readTracks.ncl")
loadscript("validTime.ncl")
loadscript("colorPlans.ncl")

;------------------------------------------------------------------
begin

;---------------- init ---------------------------
if (.not. isvar("replace")) then
   replace=0  ; replace if the image is already there
end if

if (.not. isvar("graphicDir")) then
   graphicDir="/your/figure/dir"  ; replace if the image is already there
end if

if ( .not. isvar("startTimeLevel")) then
  startTimeLevel=0
end if

if ( .not. isvar("endTimeLevel")) then
  endTimeLevel=maxLen-1
end if


if (.not. isvar("stormModel")) then
    stormModel="HAFS"
end if

if (.not. isvar("figType")) then
   figType="png" ; x11, png, ps, pdf, ncgm, etc.
end if

if (.not. isvar("stormID")) .or. (.not. isvar("stormName")) then  ;;  if no stormID is given, draw all the storms from the track file
   sids=systemfunc("sh getStormIDs.sh "+atcfFile )
   names=systemfunc("sh getStormNames.sh "+atcfFile + " " + tostring(startDate))
   if strlen(sids) .gt. 0 then
      stormIDs=str_split(sids," ")
      stormNames=str_split(names," ")
      stormCount=dimsizes(stormIDs)
   else
      stormCount=0
   end if
   stormID="00l"
   stormName="natl"
else
   stormCount=1
   stormIDs=(/stormID/)
   stormNames=(/stormName/)
end if

if ( .not. isvar("standardLayer")) then
  standardLayer=700
end if

nextLayer=standardLayer-200

if isstring(startDate) then
    sDate=tointeger(startDate)
    delete(startDate)
    startDate=sDate
end if

modelName = str_upper(stormModel)
stormID = str_upper(stormID)
stormName = str_upper(stormName)

sdstr = str_lower(stormName) + str_lower(stormID) + "." + tostring(startDate)
domain1_dir = stormDir + "/" + sdstr  + ".hafsprs.synoptic.0p03.f"   ;006.grb2  ;   sdstr + "." + str_lower(stormModel) +  "prs.synoptic.0p03.f"

;-----------------------get domain boundary ----------------------------------

name0 = domain1_dir  +  "000.grb2"
grb_file_new=addfile(name0, "r")

lat=grb_file_new->lat_0
lon=grb_file_new->lon_0

lids=get1Dindex(grb_file_new->lv_ISBL0, standardLayer*100)
if ismissing(lids) then
   layerId = dimsizes(grb_file_new->lv_ISBL0)-1
else
   layerId = lids(0)
end if

lids=get1Dindex(grb_file_new->lv_ISBL0, nextLayer*100)
if ismissing(lids) then
   layerId_n = dimsizes(grb_file_new->lv_ISBL0)-1
else
   layerId_n = lids(0)
end if


minLat  =  min(lat)       ;12    ; min(lat) ; 7
maxLat  =  max(lat)       ;48    ; max(lat)  ; 47
minLon  =  min(lon)      ; -95
maxLon  =  max(lon)        ;-50   ; max(lon)  ; -55


;---------------- get tracks ---------------------------
if stormCount .gt. 0 then
  track_xp=new((/stormCount, maxLen/), float, default_fillvalue("float"))
  track_yp=new((/stormCount, maxLen/), float, default_fillvalue("float"))
  track_w=new((/stormCount, maxLen/), float, default_fillvalue("float"))

  line1 = new(stormCount, graphic)
  markers1 = new(stormCount, graphic)
  markers2 = new(stormCount, graphic)
  markers3 = new(stormCount, graphic)

  texts = new(stormCount, graphic)
  texts_w1 = new(stormCount, graphic)
  texts_w2 = new(stormCount, graphic)
  texts_w3 = new(stormCount, graphic)
  texts_w4 = new(stormCount, graphic)
end if

do i = 0, stormCount-1
if ( is6Hr ) then
  track_data = getATCFTrack_6Hr_2(atcfFile,stormIDs(i))
else
  track_data = getATCFTrack_2(atcfFile,stormIDs(i))
end if
  track_xp(i,:)=track_data(0,:)
  track_yp(i,:)=track_data(1,:)
  track_w(i,:)=track_data(2,:)
end do

;************************************************
; create plot
;************************************************

;;;-------res1---------
   res1                      = True               ; plot mods desired
   res1@cnFillOn             = True               ; turn on color for contours
   res1@cnLinesOn            = False              ; turn off contour lines
   res1@cnLineLabelsOn       = False              ; turn off contour line labels
   res1@gsnSpreadColors      = True               ; use full color map
   res1@cnFillColors = getColorMap("relativeHumidity")
   res1@cnFillMode = "RasterFill"
   ;res1@gsnMaximize           = True         ; enlarge plo
   res1@cnFillOpacityF = 0.95

   res1@cnConstFEnableFill = True
   res1@cnConstFLabelOn    =  False          ; Turn off the "constant field" label in the middle of the plot
   res1@gsnAddCyclic = False

   res1@lbOrientation         = "Vertical"           ; vertical label bar
   res1@cnLevelSelectionMode = "ExplicitLevels"     ;"ManualLevels"  ;"ExplicitLevels"

   res1@cnLevels = (/10, 20, 30, 40, 60, 70, 80, 90/)    ;  (/10, 20, 34, 50, 64, 83, 96, 113, 137/)     ;(/20, 34, 64, 83, 96, 113, 137/)     ;ispan(0,64,4) ;(/5, 7.5, 10, 12.5, 15, 17.5, 20, 25, 30, 40, 45, 50/)

   res1@pmLabelBarWidthF = 0.05
   res1@pmLabelBarOrthogonalPosF = -0.012 ; move laber bar further away
   res1@pmLabelBarHeightF  = 0.705  ;0.71*(maxLat-minLat)/(maxLon-minLon) ;0.515 for HAFC

   res1@gsnDraw          = False                    ; turn off draw and frame
   res1@gsnFrame         = False                    ; b/c this is an overlay plot
   res1@cnFillDrawOrder   = "Draw"  ; draw contours first
   res1@mpOutlineDrawOrder = "Postdraw"
   res1@vpWidthF         = 0.7
   res1@vpHeightF         = 0.7
   res1@vpXF = 0.15
   res1@vpYF = 0.85
   res1@cnInfoLabelOn = False

   res1@mpDataBaseVersion      = "MediumRes"    ; better map outlines
   res1@mpDataSetName          = "Earth..2"
   res1@mpOutlineBoundarySets  = "GeophysicalAndUSStates"
   res1@mpGeophysicalLineThicknessF = 1.5	
   res1@mpUSStateLineThicknessF = 1.5
   res1@mpFillOn = False

   res1@mpGridAndLimbOn = True
   res1@mpGridLatSpacingF = 1.0
   res1@mpGridLonSpacingF = 1.0
   res1@mpGridLineColor = "gray40"
   res1@mpGridLineDashPattern = 2 

   res1@tmXBTickSpacingF = 1.0
   res1@tmYLTickSpacingF = 1.0
   res1@tmXBMinorOn = True
   res1@tmYLMinorOn = True
   res1@gsnMinorLatSpacing = 1.0
   res1@gsnMinorLonSpacing = 1.0

   res1@tmXBMinorPerMajor = 1
   res1@tmYLMinorPerMajor = 1
   res1@tmXBLabelFontHeightF = 0.01
   res1@tmYLLabelFontHeightF = 0.01

   res1@gsnStringFontHeightF = 0.012
   res1@lbLabelFontHeightF = 0.01
   res1@tmXTOn = False
   res1@tmYROn = False
   res1@tiMainString = tostring(standardLayer) + "-" + tostring(nextLayer) + "hPa RH (%), " + tostring(standardLayer)  + "hPa Geo. Height (x10m), and " + tostring(standardLayer) + "hPa Wind (kt)"

   res1@gsnLeftStringOrthogonalPosF = 0.006
   res1@gsnRightStringOrthogonalPosF = 0.006

   res1@tiMainFont = 21
   res1@tiMainFontHeightF = 0.014
   res1@tmXBMajorLengthF=0.008
   res1@tmXBMinorLengthF=0.004
   res1@tmYLMajorLengthF=0.008
   res1@tmYLMinorLengthF=0.004

   res1@sfXArray         = lon(:)
   res1@sfYArray         = lat(:)

;;; ------------- res ------------ ;;;
   res2 = True
   res2@cnLevelSelectionMode = "ExplicitLevels" ;"ManualLevels"  ;"ExplicitLevels"

   if standardLayer .eq. 850 then
     res2@cnLevels = ispan(100,200,2) ;(/5, 7.5, 10, 12.5, 15, 17.5, 20, 25, 30, 40, 45, 50/)
   else if standardLayer .eq. 500 then
     res2@cnLevels = ispan(400,700,2)
   else if standardLayer .eq. 200 then
     res2@cnLevels = ispan(1000,1400,2)
   else
     res2@cnLevels = ispan(2000,100,2)
   end if
   end if
   end if

   res2@cnSmoothingOn = True
   res2@cnSmoothingDistanceF = 0.002

   res2@cnLinesOn            = True              ; turn off contour lines
   res2@cnLineLabelsOn       = True              ; turn off contour line labels
   res2@cnLineColor = "black"
   res2@cnLineThicknessF = 2
   res2@gsnDraw          = False                    ; turn off draw and frame
   res2@gsnFrame         = False 
   res2@cnInfoLabelOn = False
   res2@cnLineLabelPlacementMode = "Constant" ; "Randomized" ;  "computed"  ; "constant" often not work, computed
   res2@cnLineLabelInterval = 1
   res2@cnLineLabelFontHeightF = 0.008
   res2@cnLineLabelBackgroundColor = "transparent"
   res2@cnLabelMasking             = True	

   res2@gsnLeftString = ""
   res2@gsnRightString = ""

   res2@sfXArray         = lon(:)
   res2@sfYArray         = lat(:)

;;;------------- vres-----------;;;
   vres = True
   vres@vcRefMagnitudeF           = 10.0             ; define vector ref mag
   vres@vcRefLengthF              = 0.022 ;0.018          ; define length of vec ref
   vres@vcMinDistanceF          = 0.026  ;17 ;0.0225 ;0.01 ;0.015

   ;vres@vcRefMagnitudeF           = 15.0             ; define vector ref mag
   ;vres@vcRefLengthF              = 0.015 ;0.018          ; define length of vec ref
   ;vres@vcMinDistanceF   = 0.017 ;0.0225 ;0.01 ;0.015

   vres@vcRefAnnoOn   = False         ; change ref vector color
   ;vres@vcLineArrowColor        = "blue"   ;"deeppink1"           ; change vector color
   vres@vcWindBarbLineThicknessF   = 1.3               ; change vector thickness
   vres@gsnAddCyclic = False
   vres@gsnDraw          = False                    ; turn off draw and frame
   vres@gsnFrame         = False                    ; b/c this is an overlay plot
   vres@vcGlyphStyle     = "WindBarb"         ; select wind barbs
   vres@vcVectorDrawOrder = "Postdraw"
   vres@vcPositionMode = "ArrowHead"

   vres@gsnLeftString = ""
   vres@gsnRightString = ""
   vres@vfXArray         = lon(:)
   vres@vfYArray         = lat(:)

;;;-------------pres------------;;;

   pres                  = True               ; polyline resources
   pres@gsLineThicknessF = 6.0                ; line thickness
   pres@gsLineColor      = "black"

   mres                = True         ; marker resources for best track
   format = "%Y%N%D%H"    ; "%Y (%HH)", "%d %c

 if startTimeLevel .lt. 0 then
  startTimeLevel = 0
end if
if endTimeLevel .gt. maxLen-1 then
  endTimeLevel=maxLen-1
end if

do ifil = startTimeLevel, endTimeLevel
;do ifil = 0, maxLen-1 ;42
   if ( is6Hr ) then
      hour = sprinti("%0.3i",ifil*6)
   else  ; 3hr
      hour = sprinti("%0.3i",ifil*3)
   end if
   print(ifil)


   do i = 0, stormCount-1

    figName = stormNames(i) + "." + tostring(startDate) + "." +  modelName + ".storm." + tostring(standardLayer) + "mb.rh.hgt.wind.f" + hour

    if .not. ismissing(track_xp(i,ifil)) .and. ( ( replace .eq. 1 ) .or. ( .not. (fileexists( graphicDir + "/" +  stormNames(i) + "." + tostring(startDate) + "/" + figName + "." + figType )) ) ) then

   wks = gsn_open_wks(figType,  figName)
   figName = figName +  "." + figType


   hrind = NhlNewMarker(wks, "p", 37, 0.0, 0.0, 1.0, 1.0, 0.0)

   name0 = domain1_dir  +  hour + ".grb2"


   res1@mpMinLatF = track_yp(i,ifil) -9
   res1@mpMaxLatF = track_yp(i,ifil) +9
   res1@mpMinLonF = track_xp(i,ifil) -9
   res1@mpMaxLonF = track_xp(i,ifil) +9

   res1@gsnLeftString = stormModel + " " + stormNames(i)


   valid = validtime(startDate, tointeger(hour), format)
   res1@gsnRightString = "Init: " + tostring(startDate) + "Z, F" + hour  + ", Valid: " + valid + "Z"

   grb_file_new=addfile(name0, "r")
  
   u = grb_file_new->UGRD_P0_L100_GLL0(layerId,:,:)*1.94384  ;UGRD_P0_L100_GLL0
   v = grb_file_new->VGRD_P0_L100_GLL0(layerId,:,:)*1.94384   ;VGRD_P0_L100_GLL0
   H = grb_file_new->HGT_P0_L100_GLL0(layerId,:,:)/10.0

   RH_n = dim_avg_n(grb_file_new->RH_P0_L100_GLL0(layerId_n:layerId,:,:),0)

   vres@vcWindBarbColor   = "blue" ; "royalblue1" 
   plotV = gsn_csm_vector(wks,u, v, vres)

   plot = gsn_csm_contour_map(wks, RH_n, res1)
   plot2 = gsn_csm_contour(wks, H, res2)

   overlay(plot, plot2)
   overlay(plot, plotV)

      mres@gsMarkerSizeF = 10.0
      mres@gsMarkerIndex = 16
      mres@gsMarkerColor = "Black"
      mres@gsMarkerThicknessF = 1.0
      line1(i) = gsn_add_polyline(wks,plot,track_xp(i,:),track_yp(i,:),pres)      ; draw the traj
      markers1(i) = gsn_add_polymarker(wks,plot2,track_xp(i,:),track_yp(i,:),mres)

      mres@gsMarkerSizeF = 18.0          ; marker size
      mres@gsMarkerIndex = hrind
      mres@gsMarkerColor = "black"
      mres@gsMarkerThicknessF = 10.0

      markers2(i) = gsn_add_polymarker(wks,plot2,track_xp(i,ifil),track_yp(i,ifil),mres)

      mres@gsMarkerSizeF = 18.0          ; marker size
      mres@gsMarkerColor = "red"
      mres@gsMarkerThicknessF = 4.0
      markers3(i) = gsn_add_polymarker(wks,plot2,track_xp(i,ifil),track_yp(i,ifil),mres)

   draw(plot)
   frame(wks)

   system("convert -crop 924x924+50+50 " + figName + " " + figName)

   end if
   end do
end do

print("end")

end
