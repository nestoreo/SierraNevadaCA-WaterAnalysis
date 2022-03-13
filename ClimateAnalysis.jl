using NetCDF, Statistics, StatsBase, Plots, Distributions, Distributed

ncinfo("./Data/snod.1989.nc") # To find out what variables we have


#Latitudes
lats = [[41,41,41,40,40],[39,38,38],[37,37,36]]
#Longitudes
longs = [[123,122,121,122,121],[121,121,120],[120,119,119]]

f(x) = 181 .+ (-1 .*x .+ 180)
g(x) = x .+ 91

lats = g.(lats)
longs = f.(longs)


snowd = Dict{String, Array{Float32}}()
airT = Dict{String, Array{Float32}}()
precip = Dict{String, Array{Float32}}()


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


precipByPack = zeros(Float32, length(lats), 365)
p6 = plot()
for j=1:length(lats)
    for i=1981:2015
        key = "y$(i)pack$(j)"
        precipByPack[j,:] = precipByPack[j,:] .+ precip[key]
    end
    precipByPack[j,:] = precipByPack[j,:]./35
    plot!(1:365,precipByPack[j,:], label="pack$(j)")
end
display(p6)
