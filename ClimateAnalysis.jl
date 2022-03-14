using NetCDF, Statistics, StatsBase, Plots, Distributions, Distributed, StatGeochem, Polynomials



#------------------- Reanalysis Data Processing -----------------------------
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
for i=dataYears
    for j=1:length(lats)
        key = "y$(i)pack$(j)"
        snowd[key] = zeros(Float32, 365)
        airtemp[key] = zeros(Float32, 365)
        precip[key] = zeros(Float32, 365)

        for z=1:length(lats[j])
            
            curr = ncread("./Data/snod.$(i).nc", "snod")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0
            snowd[key] = snowd[key] .+ curr

            curr = ncread("./Data/air.sig995.$(i).nc", "air")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0
            curr = (curr .- 273.15) .* (9/5) .+ 32
            airtemp[key] = airtemp[key] .+ curr

            curr = ncread("./Data/apcp.$(i).nc", "apcp")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0
            curr = curr .* 8
            precip[key] = precip[key] .+ curr

        end
        snowd[key] = snowd[key] ./ length(lats[j])
        airtemp[key] = airtemp[key] ./ length(lats[j])
        precip[key] = precip[key] ./ length(lats[j])
    end
    print("\rProcessing Data: [")
    for r=1981:i  print("#") end
    for r=i:2015 print(" ") end
    print("] $(round((i-1980)/0.35;digits=2))% complete  ")
end

#------------------- Station Data Processing and Comparison to Reanalysis-----------------------------


#Importing stationData.csv as a named tuple
#Contains year, mean temperature, precip in inches, snowfall in inches
data = importdataset("stationData.csv",'\t',importas=:Tuple)

#annual total precipitation in pack 2 in inches
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


#average annual temperature in pack 2
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
p3 = plot(dataYears,annualSnowPack2, framestyle=:box,legend=:topleft,xlabel = "Year",label="Central Sierra - Reanalysis Data", title = "Snow Depth in Reanalysis vs Snowfall in Station Data")
plot!(data.year,data.snow,label="Tahoe City, CA - Station Data",yticks=:false)
savefig(p3, "./Figures/StationReanalysisSnow.png")



#----------------------------- Data Analysis ------------------------------

#decade separation
decades = [[1981,1989],[1990,1999],[2000,2009],[2010,2015]]
#decade names for title purposes
decadeNames = ["1980s", "1990s", "2000s", "2010s"]

#decades = [[1981,1999],[2000,2015]]
#decadeNames = ["Pre 200s", "Post 2000s"]


#switch for each analysis
pack = 1
#for naming purposes
packNames = ["Northern","Central","Southern"]
packName = packNames[pack]


randomSamples = 100_000
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

slopeWinter = Polynomials.fit(dataYears,sumSnowDepthWinter,1)[1]
slopeSpring = Polynomials.fit(dataYears,sumSnowDepthSpring,1)[1]

plot(dataYears,sumSnowDepthWinter,framestyle=:box,title="$(packName) Pack Snow Depth", ylabel="Snow Depth (m)", xlabel="Year",smooth=:true, label="Winter - Slope = $(round(slopeWinter;digits=3))")
plot!(dataYears,sumSnowDepthSpring, smooth=:true, label="Spring - Slope = $(round(slopeSpring;digits=3))")





snowDepthByDecade = zeros(Float32, length(decades), 365)
p2 = plot(title="$(packName) Pack Snow Depth",framestyle=:box,ylabel="Snow Depth (m)", xlabel="Year")
for j=1:length(decades)
    for i=(decades[j][1]:decades[j][2])
        key = "y$(i)pack$(pack)"
        snowDepthByDecade[j,:] = snowDepthByDecade[j,:] .+ snowd[key]
    end
    snowDepthByDecade[j,:] = snowDepthByDecade[j,:]./(decades[j][2]-decades[j][1]+1)
    plot!(1:365, snowDepthByDecade[j,:], label="$(decadeNames[j])" )
end
display(p2)



snowd_decade = [getAllDataPoints(1981,1989,1,365,pack,snowd),getAllDataPoints(1990,1999,1,365,pack,snowd),getAllDataPoints(2000,2009,1,365,pack,snowd),getAllDataPoints(2010,2015,1,365,pack,snowd)]
snowd_means = Array{Float32}(undef,4,randomSamples)
for i=1:4
    for j=1:randomSamples
  
        snowd_means[i,j] = mean(rand(snowd_decade[i],randomSamples))
    end
end

histogram(snowd_means[1,:], bins=range(0.015,0.05,50),alpha=0.5)
histogram!(snowd_means[2,:],bins=range(0.015,0.05,50),alpha=0.5)
histogram!(snowd_means[3,:],bins=range(0.015,0.05,50),alpha=0.5)
histogram!(snowd_means[4,:],bins=range(0.015,0.05,50),alpha=0.5)


years = [1985,1995,2005,2015]
meansofmeans = [mean(snowd_means[1,:]),mean(snowd_means[2,:]),mean(snowd_means[3,:]),mean(snowd_means[4,:])]
stdsofmeans = [std(snowd_means[1,:]),std(snowd_means[2,:]),std(snowd_means[3,:]),std(snowd_means[4,:])]
plot(years, meansofmeans,yerr=2*stdsofmeans,seriestype=:scatter)





snowdByPack = zeros(Float32, length(lats), 365)
p5 = plot(title="Pack Snow Depth Comparison",framestyle=:box,ylabel="Snow Depth (m)", xlabel="Day of Year")
for j=1:length(lats)
    for i=dataYears
        key = "y$(i)pack$(j)"
        snowdByPack[j,:] = snowdByPack[j,:] .+ snowd[key]
    end
    snowdByPack[j,:] = snowdByPack[j,:]./35
    plot!(1:365,snowdByPack[j,:], label="$(packNames[j]) Sierra")
end
display(p5)





#----------------------------- Precip ------------------------------

#integral of snow depth for each season
sumPrecipFall = Array{Float32}(undef, 35)
sumPrecipWinter = Array{Float32}(undef, 35)
sumPrecipSpring = Array{Float32}(undef, 35)


#getting the area under the curve for each season
for i=dataYears
    curr = precip["y$(i)pack$(pack)"]

    sumPrecipFall[i-1980] = sum(curr[244:334])/25.4
    sumPrecipWinter[i-1980] = sum(vcat(curr[1:59],curr[335:365]))/25.4
    sumPrecipSpring[i-1980] = sum(curr[60:151])/25.4
end

slopeWinter = Polynomials.fit(dataYears,sumPrecipWinter,1)[1]
slopeSpring = Polynomials.fit(dataYears,sumPrecipSpring,1)[1]
slopeFall = Polynomials.fit(dataYears,sumPrecipFall,1)[1]

plot(dataYears,sumPrecipWinter,framestyle=:box,title="$(packName) Sierra Precipitation", ylabel="Precipitation (in)", xlabel="Year",smooth=:true, label="Winter - Slope = $(round(slopeWinter;digits=3))")
plot!(dataYears,sumPrecipSpring, smooth=:true, label="Spring - Slope = $(round(slopeSpring;digits=3))")
plot!(dataYears,sumPrecipFall, smooth=:true, label="Fall - Slope = $(round(slopeFall;digits=3))")



precip_decade = [getAllDataPoints(1981,1989,1,365,pack,precip),getAllDataPoints(1990,1999,1,365,pack,precip),getAllDataPoints(2000,2009,1,365,pack,precip),getAllDataPoints(2010,2015,1,365,pack,precip)]


precip_means = Array{Float32}(undef,4,randomSamples)
for i=1:4
    for j=1:randomSamples
  
        precip_means[i,j] = mean(rand(precip_decade[i],randomSamples))
    end
end

    
histogram(precip_means[1,:], bins=range(1.8,2.6,50),alpha=0.5)
histogram!(precip_means[2,:],bins=range(1.8,2.6,50),alpha=0.5)
histogram!(precip_means[3,:],bins=range(1.8,2.6,50),alpha=0.5)
histogram!(precip_means[4,:],bins=range(1.8,2.6,50),alpha=0.5)


years = [1985,1995,2005,2015]
meansofmeans = [mean(precip_means[1,:]),mean(precip_means[2,:]),mean(precip_means[3,:]),mean(precip_means[4,:])]
stdsofmeans = [std(precip_means[1,:]),std(precip_means[2,:]),std(precip_means[3,:]),std(precip_means[4,:])]
plot(years, meansofmeans,yerr=2*stdsofmeans,seriestype=:scatter)


p6 = plot(title="Pack Precipitation Comparison",framestyle=:box,ylabel="Precipitation (in)", xlabel="Day of Year")
for j=1:length(lats)
    precipPack = Array{Float32}(undef,365)
    for i=1:365
        precipPack[i] = getPrecip(1981,2015,i,i,j)
    end
    plot!(1:365,precipPack, label="$(packNames[j]) Sierra")
end
display(p6)



#----------------------------- Air Temperature ------------------------------

#integral of snow depth for each season
meanTempFall = Array{Float32}(undef, 35)
meanTempWinter = Array{Float32}(undef, 35)
meanTempSpring = Array{Float32}(undef, 35)
meanTempSummer = Array{Float32}(undef, 35)


#getting the area under the curve for each season
for i=dataYears
    curr = airtemp["y$(i)pack$(pack)"]

    meanTempFall[i-1980] = sum(curr[244:334])/91
    meanTempWinter[i-1980] = sum(vcat(curr[1:59],curr[335:365]))/90
    meanTempSpring[i-1980] = sum(curr[60:151])/92
    meanTempSummer[i-1980] = sum(curr[152:243])/92
end


slopeWinter = Polynomials.fit(dataYears,meanTempWinter,1)[1]
slopeSpring = Polynomials.fit(dataYears,meanTempSpring,1)[1]
slopeFall = Polynomials.fit(dataYears,meanTempFall,1)[1]
slopeSummer= Polynomials.fit(dataYears,meanTempSummer,1)[1]

plot(dataYears,meanTempWinter,legend=:topleft,framestyle=:box,title="$(packName) Sierra Temperatures", ylabel="Temperature (ºF)", xlabel="Year",smooth=:true, label="Winter - Slope = $(round(slopeWinter;digits=3))")
plot!(dataYears,meanTempSpring, smooth=:true, label="Spring - Slope = $(round(slopeSpring;digits=3))")
plot!(dataYears,meanTempFall, smooth=:true, label="Fall - Slope = $(round(slopeFall;digits=3))")
plot!(dataYears,meanTempSummer, smooth=:true, label="Summer - Slope = $(round(slopeSummer;digits=3))")


temp_decade = [getAllDataPoints(1981,1989,1,365,pack,airtemp),getAllDataPoints(1990,1999,1,365,pack,airtemp),getAllDataPoints(2000,2009,1,365,pack,airtemp),getAllDataPoints(2010,2015,1,365,pack,airtemp)]

temp_means = Array{Float32}(undef,4,randomSamples)
for i=1:4
    for j=1:randomSamples
  
        temp_means[i,j] = mean(rand(temp_decade[i],randomSamples))
    end
end


years = [1985,1995,2005,2015]
meansofmeans = [mean(temp_means[1,:]),mean(temp_means[2,:]),mean(temp_means[3,:]),mean(temp_means[4,:])]
stdsofmeans = [std(temp_means[1,:]),std(temp_means[2,:]),std(temp_means[3,:]),std(temp_means[4,:])]
plot(years, meansofmeans,yerr=2*stdsofmeans,seriestype=:scatter)



tempByPack = zeros(Float32, length(lats), 365)
p6 = plot()
for j=1:length(lats)
    for i=1981:2015
        key = "y$(i)pack$(j)"
        tempByPack[j,:] = tempByPack[j,:] .+ airtemp[key]
    end
    tempByPack[j,:] = tempByPack[j,:]./35
    plot!(1:365,tempByPack[j,:], label="pack$(j)")
end
display(p6)


#--------------------------- functions -------------------------------
function getAllDataPoints(startYear, endYear, startDay, endDay, pack, data)
    dataPoints = [data["y$(i)pack$(pack)"][j] for i in startYear:endYear for j in startDay:endDay]
    return dataPoints
end

function getPrecip(startYear, endYear, startDay, endDay, pack)
    #mm
    totalPrecip = 0

    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        totalPrecip += sum(precip[key][startDay:endDay])
    end

    #INCHES
    totalPrecip /= 25.4

    return totalPrecip
end



function getMeanTemp(startYear, endYear, startDay, endDay, pack)

    #F
    meanTemp = 0

    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        meanTemp += sum(airtemp[key][startDay:endDay])
    end

    #Mean
    meanTemp /= ((endDay-startDay+1)*(endYear-startYear+1))

    return meanTemp
end


function getSnowDepth(startYear, endYear, startDay, endDay, pack)

    #m
    meanDepth = 0

    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        meanDepth += sum(snowd[key][startDay:endDay])
    end

    #Mean
    meanDepth /= ((endDay-startDay+1)*(endYear-startYear+1))
    meanDepth *= 1000
    return meanDepth
end
