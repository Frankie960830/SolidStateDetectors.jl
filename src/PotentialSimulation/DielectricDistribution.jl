struct DielectricDistribution{T, N, S} <: AbstractArray{T, N}
    data::Array{T, N}
    grid::Grid{T, N, S}
end

@inline size(ϵ::DielectricDistribution{T, N, S}) where {T, N, S} = size(ϵ.data)
@inline length(ϵ::DielectricDistribution{T, N, S}) where {T, N, S} = length(ϵ.data)
@inline getindex(ϵ::DielectricDistribution{T, N, S}, I::Vararg{Int, N}) where {T, N, S} = getindex(ϵ.data, I...)
@inline getindex(ϵ::DielectricDistribution{T, N, S}, i::Int) where {T, N, S} = getindex(ϵ.data, i)
@inline getindex(ϵ::DielectricDistribution{T, N, S}, s::Symbol) where {T, N, S} = getindex(ϵ.grid, s)


function DielectricDistribution(fss::PotentialSimulationSetup{T, N, S})::DielectricDistribution{T, N, S} where {T, N, S}
    return DielectricDistribution{T, N, S}( fss.ϵ, fss.grid )
end

@recipe function f( ϵ::DielectricDistribution{T, 3, :Cylindrical};
                    r = missing,
                    θ = missing,
                    z = missing ) where {T}
    g::Grid{T, 3, :Cylindrical} = ϵ.grid
   
    # seriescolor --> :viridis
    st --> :heatmap
    aspect_ratio --> 1
    foreground_color_border --> nothing
    tick_direction --> :out
       
    cross_section::Symbol, idx::Int = if ismissing(θ) && ismissing(r) && ismissing(z)
        :θ, 1
    elseif !ismissing(θ) && ismissing(r) && ismissing(z)
        θ_rad::T = T(deg2rad(θ))
        while !(g[:θ].interval.left <= θ_rad <= g[:θ].interval.right)
            if θ_rad > g[:θ].interval.right
                θ_rad -= g[:θ].interval.right - g[:θ].interval.left
            elseif θ_rad < g[:θ].interval.left
                θ_rad += g[:θ].interval.right - g[:θ].interval.left
            end
        end
        :θ, searchsortednearest(g[:θ], θ_rad)
    elseif ismissing(θ) && !ismissing(r) && ismissing(z)
        :r, searchsortednearest(g[:r], T(r))
    elseif ismissing(θ) && ismissing(r) && !ismissing(z)
        :z, searchsortednearest(g[:z], T(z))
    else
        error(ArgumentError, ": Only one of the keywords `r, θ, z` is allowed.")
    end
    value::T = if cross_section == :θ
        g[:θ][idx]
    elseif cross_section == :r    
        g[:r][idx]
    elseif cross_section == :z
        g[:z][idx]
    end

    @series begin
        if cross_section == :θ
            title --> "Dielectric Distribution @$(cross_section) = $(round(rad2deg(value), sigdigits = 2))"
            xlabel --> "r / m"
            ylabel --> "z / m"
            size --> ( 400, 350 / (g[:r][end] - g[:r][1]) * (g[:z][end] - g[:z][1]) )
            g[:r], g[:z], ϵ.data[:, idx,:]'
        elseif cross_section == :r
            title --> "Dielectric Distribution @$(cross_section) = $(round(value, sigdigits = 2))"
            g[:θ], g[:z], ϵ.data[idx,:,:]'
        elseif cross_section == :z
            title --> "Dielectric Distribution @$(cross_section) = $(round(value, sigdigits = 2))"
            proj --> :polar
            g[:θ], g[:r], ϵ.data[:,:,idx]
        end
    end
end


@recipe function f( ϵ::DielectricDistribution{T, 3, :Cartesian};
                    x = missing,
                    y = missing,
                    z = missing ) where {T}
    g::Grid{T, 3, :Cartesian} = ϵ.grid
   
    seriescolor --> :viridis
    st --> :heatmap
    aspect_ratio --> 1
    foreground_color_border --> nothing
    tick_direction --> :out
       
    cross_section::Symbol, idx::Int = if ismissing(x) && ismissing(y) && ismissing(z)
        :x, 1
    elseif !ismissing(x) && ismissing(y) && ismissing(z)
        :x, searchsortednearest(g[:x], T(x))
    elseif ismissing(x) && !ismissing(y) && ismissing(z)
        :y, searchsortednearest(g[:y], T(y))
    elseif ismissing(x) && ismissing(y) && !ismissing(z)
        :z, searchsortednearest(g[:z], T(z))
    else
        error(ArgumentError, ": Only one of the keywords `r, y, z` is allowed.")
    end
    value::T = if cross_section == :x
        g[:x][idx]
    elseif cross_section == :y
        g[:y][idx]
    elseif cross_section == :z
        g[:z][idx]
    end
    @series begin
            title --> "Dielectric Distribution @$(cross_section) = $(round(value, sigdigits = 2))"
        if cross_section == :x
            xlabel --> "y / m"
            ylabel --> "z / m"
            xlims --> (g[:y][1], g[:y][end])
            ylims --> (g[:z][1], g[:z][end])
            g[:y], g[:z], ϵ.data[idx, :, :]'
        elseif cross_section == :y
            xlabel --> "x / m"
            ylabel --> "z / m"
            xlims --> (g[:x][1], g[:x][end])
            ylims --> (g[:z][1], g[:z][end])
            g[:x], g[:z], ϵ.data[:, idx, :]'
        elseif cross_section == :z
            xlabel --> "x / m"
            ylabel --> "y / m"
            xlims --> (g[:x][1], g[:x][end])
            ylims --> (g[:y][1], g[:y][end])
            g[:x], g[:y], ϵ.data[:, :, idx]
        end
    end
end

