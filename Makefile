all:  WPS/ungrib.exe
	echo All	


#TODO: do sed magic to search-replace on start_date en end_date. How to extract those values from % ?
run/%/namelist.wps: namelist.wps
	cp $< $@ 

#http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.2014010100/gfs.t00z.pgrb2f00
run/gfs/%:
	mkdir -p `dirname $@` && \
	wget -O $@ http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$@

run/%/Vtable: $(CURDIR)/WPS/ungrib/Variable_Tables/Vtable.GFS
	ln -s $< $@

run/%/metgrid: WPS/metgrid
	ln -s $(CURDIR)/$< $@


#Building WPS
WPS/configure WPS/geogrid WPS/metgrid WPS/ungrib/Variable_Tables/Vtable.GFS: wps.tar.gz
	tar -xzf $< && \
	touch $@

WPS/configure.wps: WPS/configure wps-configure.input WRFV3/run/wrf.exe
	(cd WPS && \
	bash ./configure < ../wps-configure.input && \
	sed -i -e 's/-O -fconvert=big-endian -frecord-marker=4/-O -fconvert=big-endian -frecord-marker=4 -cpp/' configure.wps) && \
	touch $@

WPS/geogrid.exe WPS/ungrib.exe WPS/metgrid.exe: WPS/configure.wps WRFV3/run/wrf.exe
	(cd WPS && \
	csh ./compile && \
	rm namelist.wps)
	#strip geogrid.exe ungrib.exe metgrid.exe)

#Compilation of WRFV3
WRFV3/configure: wrf.tar.gz
	tar -xzf $<
	touch $@

WRFV3/configure.wrf: WRFV3/configure wrf-configure.input
	(cd WRFV3 && \
	bash ./configure < ../wrf-configure.input && \
	sed -i -e 's/-O2 -ftree-vectorize -funroll-loops/-O3 -ffast-math -march=native -funroll-loops -fno-protect-parens -flto/' configure.wrf && \
	sed -i -e 's/-O0/-O3 -ffast-math -march=native -funroll-loops -fno-protect-parens -flto -cpp/' configure.wrf) && \
	touch $@

WRFV3/run/wrf.exe WRFV3/run/real.exe: WRFV3/configure.wrf
	(cd WRFV3 && \
	csh ./compile em_real)
	#strip run/wrf.exe run/real.exe)

WRFV3/run/namelist.input: namelist.input
	cp $< $@
	touch $@

geog/%: geog.tar.gz
	tar -xzf $<

#Archives
wrf.tar.gz:
	wget -O $@ http://www2.mmm.ucar.edu/wrf/src/WRFV3.7.1.TAR.gz

wps.tar.gz:
	wget -O $@ http://www2.mmm.ucar.edu/wrf/src/WPSV3.7.1.TAR.gz

geog.tar.gz:
	wget -O $@ http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_complete.tar.bz2
