# SierraNevadaCA-WaterAnalysis
Analyzes the snow depth, precipitation, temperature, and melting rates in the Sierra Nevada mountain range in CA. The snow melt is essential to California's agriculture, urban population, and species inhabiting national forests and parks.

Notes on the datasets (Reanalysis data is a few gigabytes):

You can download the dataset using an ftp client accessing: ftp2.psl.noaa.gov
The datasets are all in the /Datasets/20thC_ReanV3/Dailies/accumsMO/ directory
In the directory you need to download:

apcp.1981.nc .... apcp.1981.nc              #Precip amounts 

air.sig995.1981.nc .... air.sig995.2015.nc  #Temps  

snowd.1981.nc .... snowd.2015.nc            #Snowd amounts 

You can also download them online visiting: 

http://psl.noaa.gov/cgi-bin/db_search/DBListFiles.pl?did=210&tid=76965&vid=5202
http://psl.noaa.gov/cgi-bin/db_search/DBListFiles.pl?did=210&tid=76964&vid=5246
http://psl.noaa.gov/cgi-bin/db_search/DBListFiles.pl?did=210&tid=76964&vid=5205

The station data was self-processed and made into a csv
