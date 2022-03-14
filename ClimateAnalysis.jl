using NetCDF, Statistics, StatsBase, Plots, Distributions, Distributed, StatGeochem



#------------------- Reanalysis Data Processing -----------------------------
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
# airT:  air temperature (F)
# precip: rainfall (mm)
# pack1: northern sierra snow pack
# pack2: central sierra snow pack
# pack3: southern sierra snow pack
snowd = Dict{String, Array{Float32}}()
airT = Dict{String, Array{Float32}}()
precip = Dict{String, Array{Float32}}()


#Storing data using nested for loops
for i=1981:2015
    for j=1:length(lats)
        key = "y$(i)pack$(j)"
        snowd[key] = zeros(Float32, 365)
        airT[key] = zeros(Float32, 365)
        precip[key] = zeros(Float32, 365)

        for z=1:length(lats[j])
            
            curr = ncread("./Data/snod.$(i).nc", "snod")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0
            snowd[key] = snowd[key] .+ curr

            curr = ncread("./Data/air.sig995.$(i).nc", "air")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0
            curr = (curr .- 273.15) .* (9/5) .+ 32
            airT[key] = airT[key] .+ curr

            curr = ncread("./Data/apcp.$(i).nc", "apcp")[longs[j][z],:,:][lats[j][z],:][1:365]
            curr[curr.<=0] .= 0
            curr = curr .* 8
            precip[key] = precip[key] .+ curr

        end
        snowd[key] = snowd[key] ./ length(lats[j])
        airT[key] = airT[key] ./ length(lats[j])
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


annualPrecipPack2 = Array{Float32}(undef, 35)
for i=1981:2015
    annualPrecipPack2[i-1980] = getPrecip(i, i, 1, 365, 2) 
end
p1 = plot(1981:2015,annualPrecipPack2,smooth=:true, xlabel = "Year",framestyle=:box, ylabel="Precipitation (in)",label="Central Sierra Snow Pack", title = "Precipitation from 1981-2015")
plot!(data.year,data.precip,smooth=:true, label="Tahoe City, CA")
savefig(p1, "./Figures/StationReanalysisPrecip.png")




annualTempPack2 = Array{Float32}(undef, 35)
for i=1981:2015
    annualTempPack2[i-1980] = getMeanTemp(i, i, 1, 365, 2) 
end
p2 = plot(1981:2015,annualTempPack2,smooth=:true, framestyle=:box,legend=:topleft,xlabel = "Year", ylabel="Temperature (ºF)",label="Central Sierra Snow Pack - Reanalysis Data", title = "Average Temperature from 1981-2015")
plot!(data.year,data.Tmean,smooth=:true, label="Tahoe City, CA - Station Data")
savefig(p2, "./Figures/StationReanalysisTemp.png")


#----------------------------- Data Analysis ------------------------------



decades = [[1981,1989],[1990,1999],[2000,2009],[2010,2015]]

precipByDecadeNorth = zeros(Float32, length(decades), 365)
p1 = plot()
for j=1:length(decades)

    for i=(decades[j][1]:decades[j][2])
        key = "y$(i)pack1"

        precipByDecadeNorth[j,:] = precipByDecadeNorth[j,:] .+ precip[key]

    end
    
    precipByDecadeNorth[j,:] = precipByDecadeNorth[j,:]./(decades[j][2]-decades[j][1]+1)

    model = loess(1:365,  precipByDecadeNorth[j,:], span=0.5)

    us = range(extrema(1:365)...; step = 0.1)
    vs = predict(model, precipByDecadeNorth[j,:])
    plot!(us,vs)
    plot!(1:365, precipByDecadeNorth[j,:], label="Northern Pack - $( trunc(Int8,(decades[j][1]%100)/10))0's" ,smooth=:true)
end
display(p1)


snowdByPack = zeros(Float32, length(lats), 365)
p5 = plot()
for j=1:length(lats)
    for i=1981:2015
        key = "y$(i)pack$(j)"
        snowdByPack[j,:] = snowdByPack[j,:] .+ snowd[key]
    end
    snowdByPack[j,:] = snowdByPack[j,:]./35
    plot!(1:365,snowdByPack[j,:], label="pack$(j)")
end
display(p5)


tempByPack = zeros(Float32, length(lats), 365)
p6 = plot()
for j=1:length(lats)
    for i=1981:2015
        key = "y$(i)pack$(j)"
        tempByPack[j,:] = tempByPack[j,:] .+ airT[key]
    end
    tempByPack[j,:] = tempByPack[j,:]./35
    plot!(1:365,tempByPack[j,:], label="pack$(j)")
end
display(p6)

#--------------------------- functions -------------------------------
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

    #mm
    meanTemp = 0

    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        meanTemp += sum(airT[key][startDay:endDay])
    end

    #INCHES
    meanTemp /= ((endDay-startDay+1)*(endYear-startYear+1))

    return meanTemp
end


function getSnowDepth(startYear, endYear, startDay, endDay, pack)

    #mm
    meanTemp = 0

    for i=startYear:endYear
        key = "y$(i)pack$(pack)"
        meanTemp += sum(airT[key][startDay:endDay])
    end

    #INCHES
    meanTemp /= ((endDay-startDay+1)*(endYear-startYear+1))

    return meanTemp
end
