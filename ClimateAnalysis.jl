using NetCDF, Statistics, Plots, Distributed, StatGeochem, Polynomials



#-------------------  Data Processing Variables -----------------------------
#Data years
dataYears = 1981:2015
#Latitudes
lats = [[41,41,41,40,40],[39,38,38],[37,37,36]]
#Longitudes
longs = [[123,122,121,122,121],[121,121,120],[120,119,119]]

#Equation for index adjustment in reanalysis dataset
f(x) = 181 .+ (-1 .*x .+ 180)
g(x) = x .+ 91

#Mapping them to their index
lats = g.(lats)
longs = f.(longs)
#-------------------------Analysis Variables ----------------------------

#decade separation
decades = [[1981,1989],[1990,1999],[2000,2009],[2010,2015]]
#decade names for title purposes
decadeNames = ["1980s", "1990s", "2000s", "2010s"]
#for labeling
years = [1985,1995,2005,2015]

#switch for each analysis
pack = 1
#for naming purposes
packNames = ["Northern","Central","Southern"]
packName = packNames[pack]

#for resampling
randomSamples = 10_000

#------------------- Reanalysis Data Processing -----------------------------

#Data stored in dictionary
#Format:
#       String --> List
# ex.   y2000pack1 --> List of avg value each day of 2000 in pack 1
# snowd: snow depth (m)
# airtemp:  air temperature (F)
# precip: rainfall (mm)
# pack1: northern sierra snow pack
# pack2: central sierra snow pack
# pack3: southern sierra snow pack
snowd = Dict{String, Array{Float32}}()
airtemp = Dict{String, Array{Float32}}()
precip = Dict{String, Array{Float32}}()


#Storing data using nested for loops
#first loop is to iterate through each year
for i=dataYears
    #this iterates through each cluster coordinates
    for j=1:length(lats)
        #key for dictionary
        key = "y$(i)pack$(j)"
        #filling with zeros
        snowd[key] = zeros(Float32, 365)
        airtemp[key] = zeros(Float32, 365)
        precip[key] = zeros(Float32, 365)

        #iterating for each square grid for each cluster
        for z=1:length(lats[j])
            #adding the snow depth data
            curr = ncread("./Data/snod.$(i).nc", "snod")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0 #removes any noisy value below 0
            snowd[key] = snowd[key] .+ curr
            #adding the temperature data in fahrenheit
            curr = ncread("./Data/air.sig995.$(i).nc", "air")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0 #removes any noisy value below 0
            curr = (curr .- 273.15) .* (9/5) .+ 32 #kelvin to fahrenheit conversion
            airtemp[key] = airtemp[key] .+ curr
            #adding the precip data in mm each day
            curr = ncread("./Data/apcp.$(i).nc", "apcp")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0 #removes any noisy value below 0
            curr = curr .* 8    #data is in 3 hour mean so mulply by 8 for 24 hour amount
            precip[key] = precip[key] .+ curr

        end
        #averaging them out by dividing by area of each cluster
        snowd[key] = snowd[key] ./ length(lats[j])
        airtemp[key] = airtemp[key] ./ length(lats[j])
        precip[key] = precip[key] ./ length(lats[j])
    end
    #Loading bar to keep track of progress
    print("\rProcessing Data: [")
    for r=1981:i  print("#") end
    for r=i:2015 print(" ") end
    print("] $(round((i-1980)/0.35;digits=2))% complete  ")
end



#------------------- Station Data Processing and Comparison to Reanalysis-----------------------------


#Importing stationData.csv as a named tuple
#Contains year, mean temperature, precip in inches, snowfall in inches
data = importdataset("stationData.csv",'\t',importas=:Tuple)

#annual total precipitation in Central Sierra in inches
annualPrecipPack2 = Array{Float32}(undef, 35)
for i=dataYears
    annualPrecipPack2[i-1980] = getPrecip(i, i, 1, 365, 2) 
end

#regression line slope
slopeReanalysis = Polynomials.fit(dataYears,annualPrecipPack2,1)[1]
slopeStation = Polynomials.fit(data.year,data.precip,1)[1]

#plotting the annual precip in reanalysis vs station data
p1 = plot(dataYears,annualPrecipPack2,smooth=:true, xlabel = "Year",framestyle=:box, ylabel="Precipitation (in)",label="Reanalysis Data - Slope = $(round(slopeReanalysis;digits=3))", title = "Precipitation from 1981-2015")
plot!(data.year,data.precip,smooth=:true, label="Station Data - Slope = $(round(slopeStation;digits=3))")
savefig(p1, "./Figures/StationReanalysisPrecip.png")


#average annual temperature in Central Sierra
annualTempPack2 = Array{Float32}(undef, 35)
for i=dataYears
    annualTempPack2[i-1980] = getMeanTemp(i, i, 1, 365, 2) 
end

#regression line slope
slopeReanalysis = Polynomials.fit(dataYears,annualTempPack2,1)[1]
slopeStation = Polynomials.fit(data.year,data.Tmean,1)[1]

#plotting the annual temperature in reanalysis vs station data
p2 = plot(dataYears,annualTempPack2,smooth=:true, framestyle=:box,legend=:topleft,xlabel = "Year", ylabel="Temperature (ºF)",label="Reanalysis Data - Slope = $(round(slopeReanalysis;digits=3))", title = "Average Temperature from 1981-2015")
plot!(data.year,data.Tmean,smooth=:true, label="Station Data - Slope = $(round(slopeStation;digits=3))")
savefig(p2, "./Figures/StationReanalysisTemp.png")



#average snow depth from january 1 to june 30
annualSnowPack2 = Array{Float32}(undef, 35)
for i=dataYears
    annualSnowPack2[i-1980] = getSnowDepth(i, i, 1, 151, 2) 
end
#plotting the snow depth in reanalysis vs snowfall in station data
p3 = plot(dataYears,annualSnowPack2, smooth=:true,framestyle=:box,legend=:topleft,xlabel = "Year",label="Central Sierra - Reanalysis Data", title = "Snow Depth in Reanalysis vs Snowfall in Station Data")
plot!(data.year,data.snow,label="Tahoe City, CA - Station Data",smooth=:true,yticks=:false)
savefig(p3, "./Figures/StationReanalysisSnow.png")



#----------------------------- Data Analysis ------------------------------


#----------------------------- Snow Depth ------------------------------

#integral of snow depth for each season
sumSnowDepthWinter = Array{Float32}(undef, 35)
sumSnowDepthSpring = Array{Float32}(undef, 35)

#getting the area under the curve for each season
for i=dataYears
    curr = snowd["y$(i)pack$(pack)"]
    sumSnowDepthWinter[i-1980] = sum(vcat(curr[1:59],curr[335:365]))
    sumSnowDepthSpring[i-1980] = sum(curr[60:151])
end
#regression line slope
slopeWinter = Polynomials.fit(dataYears,sumSnowDepthWinter,1)[1]
slopeSpring = Polynomials.fit(dataYears,sumSnowDepthSpring,1)[1]

#plotting the figures
p4 = plot(dataYears,sumSnowDepthWinter,framestyle=:box,title="$(packName) Pack Snow Depth", ylabel="Snow Depth (m)", xlabel="Year",smooth=:true, label="Winter - Slope = $(round(slopeWinter;digits=3))")
plot!(dataYears,sumSnowDepthSpring, smooth=:true, label="Spring - Slope = $(round(slopeSpring;digits=3))")
savefig(p4, "./Figures/$(packName)-SD-Season.png")



#getting snow depth by decade for each day of the year
snowDepthByDecade = zeros(Float32, length(decades), 365)
p5 = plot(title="$(packName) Pack Snow Depth",framestyle=:box,ylabel="Snow Depth (m)", xlabel="Year")
#iterating through decades
for j=1:length(decades)
    #extracting the decade data
    for i=(decades[j][1]:decades[j][2])
        key = "y$(i)pack$(pack)"
        snowDepthByDecade[j,:] = snowDepthByDecade[j,:] .+ snowd[key]
    end
    #averaging them out and plotting
    snowDepthByDecade[j,:] = snowDepthByDecade[j,:]./(decades[j][2]-decades[j][1]+1)
    plot!(1:365, snowDepthByDecade[j,:], label="$(decadeNames[j])" )
end
savefig(p5, "./Figures/$(packName)SD-Decade-Daily.png")



#snow depth by decade with monte carlo resampling to get mean of means and std of means
snowd_decade = [getAllDataPoints(1981,1989,1,365,pack,snowd),getAllDataPoints(1990,1999,1,365,pack,snowd),getAllDataPoints(2000,2009,1,365,pack,snowd),getAllDataPoints(2010,2015,1,365,pack,snowd)]
snowd_means = Array{Float32}(undef,4,randomSamples)
#applying it for a large amount of times
for i=1:4
    for j=1:randomSamples
        snowd_means[i,j] = mean(rand(snowd_decade[i],randomSamples))
    end
end
#getting the mean of means and std of means and plotting the distrbution data
meansofmeans = [mean(snowd_means[1,:]),mean(snowd_means[2,:]),mean(snowd_means[3,:]),mean(snowd_means[4,:])]
stdsofmeans = [std(snowd_means[1,:]),std(snowd_means[2,:]),std(snowd_means[3,:]),std(snowd_means[4,:])]
p6 = plot(years, meansofmeans,yerr=2*stdsofmeans,seriestype=:scatter,framestyle=:box,title="$(packName) Sierra Resampled Mean Snow Depths",ylabel="Snow Depth (m)",xlabel="year",legend=:false)
savefig(p6, "./Figures/$(packName)SD-Decade-Resampled.png")







#----------------------------- Precip ------------------------------

#integral of precip for each season
sumPrecipFall = Array{Float32}(undef, 35)
sumPrecipWinter = Array{Float32}(undef, 35)
sumPrecipSpring = Array{Float32}(undef, 35)

#getting the area under the curve for each season and converting to inches
for i=dataYears
    curr = precip["y$(i)pack$(pack)"]

    sumPrecipFall[i-1980] = sum(curr[244:334])/25.4
    sumPrecipWinter[i-1980] = sum(vcat(curr[1:59],curr[335:365]))/25.4
    sumPrecipSpring[i-1980] = sum(curr[60:151])/25.4
end
#getting the slope for each season
slopeWinter = Polynomials.fit(dataYears,sumPrecipWinter,1)[1]
slopeSpring = Polynomials.fit(dataYears,sumPrecipSpring,1)[1]
slopeFall = Polynomials.fit(dataYears,sumPrecipFall,1)[1]
#plotting the data
p8 = plot(dataYears,sumPrecipWinter,framestyle=:box,title="$(packName) Sierra Precipitation", ylabel="Precipitation (in)", xlabel="Year",smooth=:true, label="Winter - Slope = $(round(slopeWinter;digits=3))")
plot!(dataYears,sumPrecipSpring, smooth=:true, label="Spring - Slope = $(round(slopeSpring;digits=3))")
plot!(dataYears,sumPrecipFall, smooth=:true, label="Fall - Slope = $(round(slopeFall;digits=3))")
savefig(p8, "./Figures/$(packName)-Precip-Season.png")



#Precip by decade with monte carlo resampling to get mean of means and std of means
precip_decade = [getAllDataPoints(1981,1989,1,365,pack,precip),getAllDataPoints(1990,1999,1,365,pack,precip),getAllDataPoints(2000,2009,1,365,pack,precip),getAllDataPoints(2010,2015,1,365,pack,precip)]
precip_means = Array{Float32}(undef,4,randomSamples)
#applying it for a large amount of times
for i=1:4
    for j=1:randomSamples
        precip_means[i,j] = mean(rand(precip_decade[i],randomSamples))/25.4
    end
end
#getting the mean of means and std of means and plotting the distrbution data
meansofmeans = [mean(precip_means[1,:]),mean(precip_means[2,:]),mean(precip_means[3,:]),mean(precip_means[4,:])]
stdsofmeans = [std(precip_means[1,:]),std(precip_means[2,:]),std(precip_means[3,:]),std(precip_means[4,:])]
p9=plot(years, meansofmeans,yerr=2*stdsofmeans,seriestype=:scatter,framestyle=:box,title="$(packName) Sierra Resampled Mean Precip",ylabel="Precip (in)",xlabel="year",legend=:false)
savefig(p9, "./Figures/$(packName)Precip-Decade-Resampled.png")






#----------------------------- Air Temperature ------------------------------

#integral of snow depth for each season
meanTempFall = Array{Float32}(undef, 35)
meanTempWinter = Array{Float32}(undef, 35)
meanTempSpring = Array{Float32}(undef, 35)
meanTempSummer = Array{Float32}(undef, 35)

#getting the area under the curve for each season and dividing by days for mean temp
for i=dataYears
    curr = airtemp["y$(i)pack$(pack)"]

    meanTempFall[i-1980] = sum(curr[244:334])/91
    meanTempWinter[i-1980] = sum(vcat(curr[1:59],curr[335:365]))/90
    meanTempSpring[i-1980] = sum(curr[60:151])/92
    meanTempSummer[i-1980] = sum(curr[152:243])/92
end

#getting the regression line slope
slopeWinter = Polynomials.fit(dataYears,meanTempWinter,1)[1]
slopeSpring = Polynomials.fit(dataYears,meanTempSpring,1)[1]
slopeFall = Polynomials.fit(dataYears,meanTempFall,1)[1]
slopeSummer= Polynomials.fit(dataYears,meanTempSummer,1)[1]
#plotting the figures
p11= plot(dataYears,meanTempWinter,legend=:topleft,framestyle=:box,title="$(packName) Sierra Temperatures", ylabel="Temperature (ºF)", xlabel="Year",smooth=:true, label="Winter - Slope = $(round(slopeWinter;digits=3))")
plot!(dataYears,meanTempSpring, smooth=:true, label="Spring - Slope = $(round(slopeSpring;digits=3))")
plot!(dataYears,meanTempFall, smooth=:true, label="Fall - Slope = $(round(slopeFall;digits=3))")
plot!(dataYears,meanTempSummer, smooth=:true, label="Summer - Slope = $(round(slopeSummer;digits=3))")
savefig(p11, "./Figures/$(packName)-Temp-Season.png")


#Getting the annual mean snow depth
sumSnowAnnual = Array{Float32}(undef, 4,35)
#Getting the annual mean temperature
meanTempAnnual = Array{Float32}(undef, 4,35)

for j=1:length(lats)
    for i=dataYears
        meanTempAnnual[j,i-1980] = sum(airtemp["y$(i)pack$(j)"])/365
        sumSnowAnnual[j,i-1980] = sum(snowd["y$(i)pack$(j)"])
    end
end

#Plotting the results of snow depth vs temperature for each pack
p13 = plot(seriestype=:scatter)
plot!(meanTempAnnual[1,:],sumSnowAnnual[1,:], xlabel = "Temperature (ºF)",ylabel="Snow Depth (m)", framestyle=:box,label="$(packNames[1]) Sierra",smooth=:true,seriestype=:scatter)
savefig(p13,"./Figures/$(packNames[1])TempvsSD.png" )
p14 = plot(seriestype=:scatter)
plot!(meanTempAnnual[2,:],sumSnowAnnual[2,:],xlabel = "Temperature (ºF)",ylabel="Snow Depth (m)", framestyle=:box, label="$(packNames[2]) Sierra",smooth=:true,seriestype=:scatter)
savefig(p14,"./Figures/$(packNames[2])TempvsSD.png" )
p15 = plot(seriestype=:scatter)
plot!(meanTempAnnual[3,:],sumSnowAnnual[3,:],xlabel = "Temperature (ºF)",ylabel="Snow Depth (m)", framestyle=:box, label="$(packNames[3]) Sierra",smooth=:true,seriestype=:scatter)
savefig(p15,"./Figures/$(packNames[3])TempvsSD.png" )


#-------------------------------- Pack Comparisons -----------------------------------
#Shows the average snow depth of each pack from day 1 to 365
snowdByPack = zeros(Float32, length(lats), 365)
p7 = plot(title="Pack Snow Depth Comparison",framestyle=:box,ylabel="Snow Depth (m)", xlabel="Day of Year")
for j=1:length(lats)
    for i=dataYears
        key = "y$(i)pack$(j)"
        snowdByPack[j,:] = snowdByPack[j,:] .+ snowd[key]
    end
    snowdByPack[j,:] = snowdByPack[j,:]./35
    plot!(1:365,snowdByPack[j,:], label="$(packNames[j]) Sierra")
end
savefig(p7, "./Figures/SD-Pack-Comp.png")

#Shows the total precip of each pack from day 1 to 365
p10 = plot(title="Pack Precipitation Comparison",framestyle=:box,ylabel="Precipitation (in)", xlabel="Day of Year")
for j=1:length(lats)
    precipPack = Array{Float32}(undef,365)
    for i=1:365
        precipPack[i] = getPrecip(1981,2015,i,i,j)
    end
    plot!(1:365,precipPack, label="$(packNames[j]) Sierra")
end
savefig(p10, "./Figures/Precip-Pack-Comp.png")


#Shows the average temperature of each pack from day 1 to 365
tempByPack = zeros(Float32, length(lats), 365)
p13 = plot(title="Pack Temperature Comparison",framestyle=:box,ylabel="Temperature (ºF)", xlabel="Day of Year")

for j=1:length(lats)
    for i=1981:2015
        key = "y$(i)pack$(j)"
        tempByPack[j,:] = tempByPack[j,:] .+ airtemp[key]
    end
    tempByPack[j,:] = tempByPack[j,:]./35
    plot!(1:365,tempByPack[j,:], label="$(packName) Sierra")
end
savefig(p13, "./Figures/Temp-Pack-Comp.png")


#--------------------------- functions -------------------------------

#Takes in a start year and end year, and start day and end day
# and returns all the data points for that data and pack in that period
# pack = 1 ---> northern
# pack = 2 ---> central
# pack = 3 ---> southern
function getAllDataPoints(startYear, endYear, startDay, endDay, pack, data)
    dataPoints = [data["y$(i)pack$(pack)"][j] for i in startYear:endYear for j in startDay:endDay]
    return dataPoints
end


#Takes in a start year and end year, and start day and end day
# and returns the total precip during that period in that pack
# pack = 1 ---> northern
# pack = 2 ---> central
# pack = 3 ---> southern
function getPrecip(startYear, endYear, startDay, endDay, pack)
    #mm
    totalPrecip = 0
    #sums the precip for all the days
    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        totalPrecip += sum(precip[key][startDay:endDay])
    end

    #Conversion to inches
    totalPrecip /= 25.4

    return totalPrecip
end


#Takes in a start year and endy year, and start day and end day
# and returns the mean temp during that period in that pack
# pack = 1 ---> northern
# pack = 2 ---> central
# pack = 3 ---> southern
function getMeanTemp(startYear, endYear, startDay, endDay, pack)
    #Mean
    meanTemp = 0
    #iterating through each year and summing the counts for those days
    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        meanTemp += sum(airtemp[key][startDay:endDay])
    end

    #Averaging out based on days
    meanTemp /= ((endDay-startDay+1)*(endYear-startYear+1))

    return meanTemp
end

#Takes in a start year and endy year, and start day and end day
# and returns the mean snow depth during that period in that pack
# pack = 1 ---> northern
# pack = 2 ---> central
# pack = 3 ---> southern
function getSnowDepth(startYear, endYear, startDay, endDay, pack)
    #mean 
    meanDepth = 0

    #iterating through each year and summing the counts for those days
    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        meanDepth += sum(snowd[key][startDay:endDay])
    end

    #Averaging out based on days summed
    meanDepth /= ((endDay-startDay+1)*(endYear-startYear+1))
    #turns to millimeter
    meanDepth *= 1000
    return meanDepth
end
