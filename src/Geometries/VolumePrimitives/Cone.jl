struct Cone{T} <: AbstractVolumePrimitive{T, 3} ## Only upright Cones at the moment, Convention: counterclockwise \alpha \beta γ; γ is the 90 deg angle,
    rStart1::T
    rStop1::T
    rStart2::T
    rStop2::T
    φStart::T
    φStop::T
    zStart::T
    zStop::T
    translate::Union{CartesianVector{T},Missing}
    rotate::Rotations.RotXYZ{T}
end



function Cone{T}( rStart1::T, rStop1::T, rStart2::T, rStop2::T, φStart::T, φStop::T, zStart::T, zStop::T, translate::Union{CartesianVector{T},Missing}, rotX::T, rotY::T, rotZ::T) where {T}
    rotationMatrix::Rotations.RotXYZ{T} = RotXYZ{T}(rotX, rotY, rotZ)
    Cone{T}(rStart1, rStop1, rStart2, rStop2, φStart, φStop, zStart, zStop, translate, rotationMatrix)
end

function in(point::CylindricalPoint{T}, cone::Cone{T})::Bool where {T <: SSDFloat}
    (ismissing(cone.translate) || cone.translate == CartesianVector{T}(0.0, 0.0, 0.0)) ? nothing : point = CylindricalPoint(CartesianPoint(point) - cone.translate)
    return point.z in ClosedInterval{T}(cone.zStart,cone.zStop) && 
            point.φ in ClosedInterval{T}(cone.φStart,cone.φStop) && 
            point.r in ClosedInterval{T}(get_intersection_rs_for_given_z(point.z,cone)...)
end

function get_intersection_rs_for_given_z(z::T, c::Cone{T}) where {T <: SSDFloat}
    r1::T = ( (c.rStart1*c.zStop - c.zStart*c.rStart2) * (T(0.0) - T(1.0)) - (c.rStart1 - c.rStart2) * (T(0.0)*z - z*T(1.0)) ) / ( (c.rStart1 - c.rStart2) * (z - z) - (c.zStart - c.zStop) * (T(0.0) - T(1.0)) )
    r2::T = ( (c.rStop1*c.zStop - c.zStart*c.rStop2) * (T(0.0) - T(1.0)) - (c.rStop1 - c.rStop2) * (T(0.0)*z - z*T(1.0)) ) / ( (c.rStop1 - c.rStop2) * (z - z) - (c.zStart - c.zStop) * (T(0.0) - T(1.0)) )
    r1,r2
end

function in(point::CartesianPoint{T}, cone::Cone{T})::Bool where {T <: SSDFloat}
    ismissing(cone.translate) ? nothing : point -= cone.translate
    point = CylindricalPoint(point)
    return point.z in ClosedInterval{T}(cone.zStart,cone.zStop) && 
            point.φ in ClosedInterval{T}(cone.φStart,cone.φStop) && 
            point.r in ClosedInterval{T}(get_intersection_rs_for_given_z(point.z,cone)...)
end

function Cone{T}(dict::Union{Dict{Any, Any},Dict{String,Any}}, inputunit_dict::Dict{String,Unitful.Units})::Cone{T} where {T <: SSDFloat}

    rotX::T = haskey(dict, "rotX") ? geom_round(ustrip(uconvert(u"rad", T(dict["rotX"]) * inputunit_dict["angle"]))) : T(0.0)
    rotY::T = haskey(dict, "rotY") ? geom_round(ustrip(uconvert(u"rad", T(dict["rotY"]) * inputunit_dict["angle"]))) : T(0.0)
    rotZ::T = haskey(dict, "rotZ") ? geom_round(ustrip(uconvert(u"rad", T(dict["rotZ"]) * inputunit_dict["angle"]))) : T(0.0)

    z_offset::T = 0.0

    if haskey(dict, "translate")
        translate = CartesianVector{T}( haskey(dict["translate"],"x") ? geom_round(ustrip(uconvert(u"m", T(dict["translate"]["x"]) * inputunit_dict["length"] ))) : 0.0,
                                        haskey(dict["translate"],"y") ? geom_round(ustrip(uconvert(u"m", T(dict["translate"]["y"]) * inputunit_dict["length"] ))) : 0.0,
                                        haskey(dict["translate"],"z") ? geom_round(ustrip(uconvert(u"m", T(dict["translate"]["z"]) * inputunit_dict["length"] ))) : 0.0)
        if translate[1] == T(0.0) && translate[2] == T(0.0)
            translate = missing
            z_offset = geom_round(ustrip(uconvert(u"m", T(dict["translate"]["z"]) * inputunit_dict["length"] )))
        end
    else
        translate = missing
    end

    if haskey(dict,"h")
        zStart, zStop = z_offset, geom_round(z_offset + ustrip(uconvert(u"m", T(dict["h"]) * inputunit_dict["length"] )))
    elseif haskey(dict,"z")
        zStart, zStop = geom_round(z_offset + ustrip(uconvert(u"m", T(dict["z"]["from"]) * inputunit_dict["length"] ))), geom_round(z_offset + ustrip(uconvert(u"m", T(dict["z"]["to"]) * inputunit_dict["length"])))
    end


    return Cone{T}(
        geom_round(ustrip(uconvert(u"m", T(dict["r"]["bottom"]["from"]) * inputunit_dict["length"] ))),
        geom_round(ustrip(uconvert(u"m", T(dict["r"]["bottom"]["to"]) * inputunit_dict["length"]))),
        geom_round(ustrip(uconvert(u"m", T(dict["r"]["top"]["from"]) * inputunit_dict["length"] ))),
        geom_round(ustrip(uconvert(u"m", T(dict["r"]["top"]["to"]) * inputunit_dict["length"]))),
        geom_round(T(ustrip(uconvert(u"rad", T(dict["phi"]["from"]) * inputunit_dict["angle"])))),
        geom_round(T(ustrip(uconvert(u"rad", T(dict["phi"]["to"]) * inputunit_dict["angle"])))),
        zStart,
        zStop,
        translate, 
        rotX, rotY, rotZ)
end

function Geometry(T::DataType, t::Val{:cone}, dict::Dict{Any, Any}, inputunit_dict::Dict{String,Unitful.Units})
    return Cone{T}(dict, inputunit_dict)
end

function get_important_points(c::Cone{T}, ::Val{:r})::Vector{T} where {T <: SSDFloat}
    return geom_round.(T[c.rStart1, c.rStop1, c.rStart2, c.rStop2])
end
function get_important_points(c::Cone{T}, ::Val{:x})::Vector{T} where {T <: SSDFloat}
    return geom_round.(T[-c.rStart1, -c.rStop1, -c.rStart2, -c.rStop2, c.rStart1, c.rStop1, c.rStart2, c.rStop2])
end
function get_important_points(c::Cone{T}, ::Val{:y})::Vector{T} where {T <: SSDFloat}
    return geom_round.(T[-c.rStart1, -c.rStop1, -c.rStart2, -c.rStop2, c.rStart1, c.rStop1, c.rStart2, c.rStop2])
end

function get_important_points(c::Cone{T}, ::Val{:φ})::Vector{T} where {T <: SSDFloat}
    return geom_round.(T[c.φStart, c.φStop])
end

function get_important_points(c::Cone{T}, ::Val{:z})::Vector{T} where {T <: SSDFloat}
    return geom_round.(T[c.zStart, c.zStop])
end

function sample(c::Cone{T}, stepsize::Vector{T}) where {T <: SSDFloat}
    samples = CylindricalPoint[]
    for z in c.zStart:stepsize[3]:c.zStop
        for φ in c.φStart:stepsize[2]:c.φStop
            for r in get_intersection_rs_for_given_z(z,c)[1]:stepsize[1]:get_intersection_rs_for_given_z(z,c)[2]
                push!(samples, CylindricalPoint{T}(r,φ,z))
            end
        end
    end
    ismissing(c.translate) ? nothing : samples = map(x -> CylindricalPoint(CartesianPoint(x) + c.translate), samples)
    return samples
end

function (+)(c::Cone{T}, translate::Union{CartesianVector{T},Missing})::Cone{T} where {T <: SSDFloat}
    if ismissing(translate)
        return c
    elseif ismissing(c.translate)
        return Cone(c.rStart1, c.rStop1, c.rStart2, c.rStop2, c.φStart, c.φStop, c.zStart, c.zStop, translate, c.rotate)
    else
        return Cone(c.rStart1, c.rStop1, c.rStart2, c.rStop2, c.φStart, c.φStop, c.zStart, c.zStop, c.translate + translate, c.rotate)
    end
 end
