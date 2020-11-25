
function LineSegments(t::Tube{T})::Vector{AbstractLine{T,3,:cartesian}} where {T <: SSDFloat}
    ls = AbstractLine{T, 3, :cartesian}[]
    translate::CartesianVector{T} = ismissing(t.translate) ? CartesianVector{T}([0, 0, 0]) : t.translate
    for r in (t.r_interval.left == 0 ? [t.r_interval.right] : [t.r_interval.left, t.r_interval.right])
        for z in [t.z_interval.left, t.z_interval.right]
            push!(ls, PartialCircle(r, t.φ_interval.left, t.φ_interval.right, translate + CartesianVector{T}([0, 0, z])))
        end
    end
    for r in [t.r_interval.left, t.r_interval.right]
        if r != 0
            for φ in ((t.φ_interval.right - t.φ_interval.left ≈ 2π) ? [t.φ_interval.left] : [t.φ_interval.left, t.φ_interval.right])
                push!(ls, LineSegment(
                    CartesianPoint{T}(r * cos(φ), r * sin(φ), t.z_interval.left) + translate,
                    CartesianPoint{T}(r * cos(φ), r * sin(φ), t.z_interval.right) + translate))
            end
        end
    end
    for φ in ((t.φ_interval.right - t.φ_interval.left ≈ 2π) ? [] : [t.φ_interval.left, t.φ_interval.right])
        for z in [t.z_interval.left, t.z_interval.right]
            push!(ls, LineSegment(
                CartesianPoint{T}(t.r_interval.left * cos(φ), t.r_interval.left * sin(φ), z) + translate,
                CartesianPoint{T}(t.r_interval.right * cos(φ), t.r_interval.right * sin(φ), z) + translate))
        end
    end
    return ls
end

@recipe function f(t::Tube{T}; n = 30, seriescolor = :green, SSD_style = :wireframe, world_size = missing, geometry_negative = [], alpha_factor = 1) where {T}
    linewidth --> 2
    n --> n
    @series begin
        seriescolor --> seriescolor
        label --> "Tube"
        []
    end
    label := ""
    seriescolor := seriescolor
    α = 1
    st = :path
    if SSD_style == :wireframe
        plotobject = LineSegments(t)
    elseif SSD_style == :samplesurface
        st = :scatter
        if ismissing(world_size)
            r_size = t.r_interval.right*width(t.φ_interval)/(π/2) >= width(t.r_interval) ? t.r_interval.right :  width(t.r_interval)
            max_dim = max(r_size, width(t.z_interval))
            world_size = CylindricalVector{T}(max_dim, width(t.φ_interval)/2, max_dim)
        end
        points = 100
        if typeof(world_size) == CylindricalVector{T}
            sampling_vector = Array{T}(world_size/points)
            plotobject = CylindricalPoint.(sample(t, sampling_vector))
        elseif typeof(world_size) == CartesianVector{T}
            sampling_vector = T.([sqrt(world_size.x^2+world_size.y^2), π, world_size.z]/points)
            plotobject = CartesianPoint.(sample(t, sampling_vector))
        end
        for neg_geo in geometry_negative
            filter!(x -> !(x in neg_geo), plotobject)
        end
        α = min(alpha_factor*max(1-length(plotobject)/3000,0.05),1)
    end
    seriestype  :=  st
    markerstrokewidth := 0
    seriesalpha := α
    plotobject
end


function LineSegments(c::Cone{T})::Vector{AbstractLine{T, 3, :cartesian}} where {T <: SSDFloat}
    ls = AbstractLine{T, 3, :cartesian}[]
    translate::CartesianVector{T} = ismissing(c.translate) ? CartesianVector{T}([0, 0, 0]) : c.translate
    for r in [c.rStart1, c.rStop1]
        push!(ls, PartialCircle(r, c.φStart, c.φStop, translate + CartesianVector{T}([0, 0, c.zStart])))
    end
    for r in [c.rStart2, c.rStop2]
        push!(ls, PartialCircle(r, c.φStart, c.φStop, translate + CartesianVector{T}([0, 0, c.zStop])))

    end
    for φ in ((c.φStop - c.φStart ≈ 2π) ? [c.φStart] : [c.φStart, c.φStop])
        push!(ls, LineSegment(
            CartesianPoint{T}(c.rStart1 * cos(φ), c.rStart1 * sin(φ), c.zStart) + translate,
            CartesianPoint{T}(c.rStart2 * cos(φ), c.rStart2 * sin(φ), c.zStop) + translate))
        push!(ls, LineSegment(
            CartesianPoint{T}(c.rStop1 * cos(φ), c.rStop1 * sin(φ), c.zStart) + translate,
            CartesianPoint{T}(c.rStop2 * cos(φ), c.rStop2 * sin(φ), c.zStop) + translate))
    end
    for φ in ((c.φStop - c.φStart ≈ 2π) ? [c.φStart] : [c.φStart, c.φStop])
        push!(ls, LineSegment(
            CartesianPoint{T}(c.rStart1 * cos(φ),  c.rStart1 * sin(φ),  c.zStart) + translate,
            CartesianPoint{T}(c.rStop1 * cos(φ),   c.rStop1 * sin(φ), c.zStart) + translate))
        push!(ls, LineSegment(
            CartesianPoint{T}(c.rStart2 * cos(φ),  c.rStart2 * sin(φ),  c.zStop) + translate,
            CartesianPoint{T}(c.rStop2 * cos(φ),   c.rStop2 * sin(φ), c.zStop) + translate))
    end
    return ls
end

@recipe function f(c::Cone{T}; n = 30, seriescolor = :orange, SSD_style = :wireframe, world_size = missing, geometry_negative = [], alpha_factor = 1) where {T}
    linewidth --> 2
    n --> n
    @series begin
        seriescolor --> seriescolor
        label --> "Cone"
        []
    end
    seriescolor := seriescolor
    label := ""
    α = 1
    st = :path
    if SSD_style == :wireframe
        plotobject = LineSegments(c)
    elseif SSD_style == :samplesurface
        st = :scatter
        if ismissing(world_size)
            r_max = max(c.rStop1, c.rStop2)
            r_size = r_max*width(c.φ_interval)/(π/2) >= abs(r_max - min(c.rStart1, c.rStart2)) ? r_max :  abs(r_max - min(c.rStart1, c.rStart2))
            max_dim = max(r_size, abs(c.zStop-c.zStart))
            world_size = CylindricalVector{T}(max_dim, width(t.φ_interval)/2, max_dim)
        end
        points = 100
        if typeof(world_size) == CylindricalVector{T}
            sampling_vector = Array{T}(world_size/points)
            plotobject = CylindricalPoint.(sample(c, sampling_vector))
        elseif typeof(world_size) == CartesianVector{T}
            sampling_vector = T.([sqrt(world_size.x^2+world_size.y^2), π, world_size.z]/points)
            plotobject = CartesianPoint.(sample(c, sampling_vector))
        end
        for neg_geo in geometry_negative
            filter!(x -> !(x in neg_geo), plotobject)
        end
        α = min(alpha_factor*max(1-length(plotobject)/3000,0.05),1)
    end
    seriestype  :=  st
    markerstrokewidth := 0
    seriesalpha := α
    plotobject
end

function LineSegments(t::Torus{T})::Vector{AbstractLine{T,3,:cartesian}} where {T <: SSDFloat}
    ls = AbstractLine{T, 3, :cartesian}[]
    translate::CartesianVector{T} = ismissing(t.translate) ? CartesianVector{T}([0, 0, 0]) : t.translate
    for r_tube in (t.r_tube_interval.left == 0 ? [t.r_tube_interval.right] : [t.r_tube_interval.left, t.r_tube_interval.right])
        θ_circles = (t.θ_interval.right - t.θ_interval.left) ≈ 2π ? [t.θ_interval.left] : [t.θ_interval.left, t.θ_interval.right]
        π in OpenInterval(t.θ_interval) ? push!(θ_circles, π) : nothing
        for θ in θ_circles
            r = r_tube*cos(θ) + t.r_torus
            z = r_tube*sin(θ)
            push!(ls, PartialCircle(r, t.φ_interval.left, t.φ_interval.right, translate + CartesianVector{T}([0, 0, z])))
        end
    end
    for φ in (t.φ_interval.right - t.φ_interval.left ≈ 2π ? [t.φ_interval.left] : [t.φ_interval.left, t.φ_interval.right])
        for r_tube in (t.r_tube_interval.left == 0 ? [t.r_tube_interval.right] : [t.r_tube_interval.left, t.r_tube_interval.right])
            r = r_tube
            push!(ls, PartialCircle(r, t.θ_interval.left, t.θ_interval.right, translate + CartesianVector{T}([t.r_torus*cos(φ), t.r_torus*sin(φ), 0]), RotZ{T}(φ)*RotX{T}(π/2)))
        end
        for θ in (t.θ_interval.right - t.θ_interval.left ≈ 2π ? [] : [t.θ_interval.left, t.θ_interval.right])
            push!(ls, LineSegment(
                RotZ{T}(φ)*RotY{T}(-θ)*CartesianPoint{T}(t.r_tube_interval.left, 0, 0) + CartesianVector{T}([t.r_torus*cos(φ), t.r_torus*sin(φ), 0]) + translate,
                RotZ{T}(φ)*RotY{T}(-θ)*CartesianPoint{T}(t.r_tube_interval.right, 0, 0) + CartesianVector{T}([t.r_torus*cos(φ), t.r_torus*sin(φ), 0]) + translate))
        end
    end
    return ls
end

@recipe function f(t::Torus{T}; n = 30, seriescolor = :red, SSD_style = :wireframe, world_size = missing, geometry_negative = [], alpha_factor = 1) where {T}
    linewidth --> 2
    n --> n
    @series begin
        seriescolor --> seriescolor
        label --> "Torus"
        []
    end
    label := ""
    seriescolor := seriescolor
    α = 1
    st = :path
    if SSD_style == :wireframe
        plotobject = LineSegments(t)
    elseif SSD_style == :samplesurface
        st = :scatter
        own_world = false
        if ismissing(world_size)
            own_world = true
            r_size = (t.r_torus+t.r_tube_interval.right)*width(t.φ_interval)/(π/2) > max(t.r_tube_interval.right*width(t.θ_interval)/(π/2), width(t.r_tube_interval)) ?  t.r_torus+t.r_tube_interval.right : t.r_tube_interval.right
            world_size = CylindricalVector{T}(r_size, width(t.φ_interval)/2, width(t.θ_interval)/2)
        end
        points = 100
        if typeof(world_size) == CylindricalVector{T}
            sampling_vector = Array{T}(world_size/points)
            own_world ? nothing : sampling_vector[3] = π/points
            plotobject = CylindricalPoint.(sample(t, sampling_vector))
        elseif typeof(world_size) == CartesianVector{T}
            sampling_vector = T.([sqrt(world_size.x^2+world_size.y^2), π, π]/points)
            plotobject = CartesianPoint.(sample(t, sampling_vector))
        end
        for neg_geo in geometry_negative
            filter!(x -> !(x in neg_geo), plotobject)
        end
        α = min(alpha_factor*max(1-length(plotobject)/3000,0.05),1)
    end
    seriestype  :=  st
    markerstrokewidth := 0
    seriesalpha := α
    plotobject
end
