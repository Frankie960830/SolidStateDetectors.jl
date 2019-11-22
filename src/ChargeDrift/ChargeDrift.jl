struct DriftPath{T <: SSDFloat}
    path::Vector{<:AbstractCoordinatePoint{RealQuantity}}
    timestamps::Vector{RealQuantity}
end

struct EHDriftPath{T <: SSDFloat, TT <: RealQuantity}
    e_path::Vector{<:AbstractCoordinatePoint{T}}
    h_path::Vector{<:AbstractCoordinatePoint{T}}
    timestamps_e::Vector{TT}
    timestamps_h::Vector{TT}
end

_common_length(dp::EHDriftPath{T} where {T <: SSDFloat})::Int = 
    max(length(dp.timestamps_e), length(dp.timestamps_h))
_common_length(dps::Vector{EHDriftPath{T}} where {T <: SSDFloat})::Int = 
    maximum(_common_length.(dps))

function _common_time(dp::EHDriftPath{T, TT})::TT where {T <: SSDFloat, TT<:RealQuantity}  
    max(last(dp.timestamps_e), last(dp.timestamps_h))
end
_common_time(dps::Vector{<:EHDriftPath}) = 
maximum(_common_time.(dps))

function _common_timestamps(dp::Union{<:EHDriftPath{T}, Vector{<:EHDriftPath{T}}}, Δt) where {T} 
    range(zero(Δt), step = Δt, stop = typeof(Δt)(_common_time(dp)) + Δt)
end

function get_velocity_vector(interpolation_field::Interpolations.Extrapolation{<:StaticVector{3}, 3}, point::CartesianPoint{T})::CartesianVector{T} where {T <: SSDFloat}  
    return CartesianVector{T}(interpolation_field(point.x, point.y, point.z))
end

@inline function get_velocity_vector(interpolated_vectorfield, point::CylindricalPoint{T}) where {T <: SSDFloat}
    return CartesianVector{T}(interpolated_vectorfield(point.r, point.φ, point.z))
end

include("ChargeDriftCylindrical.jl")
include("ChargeDriftCartesian.jl")


function _drift_charges(detector::SolidStateDetector{T}, grid::Grid{T, 3}, point_types::PointTypes{T, 3},
                        starting_points::Vector{CartesianPoint{T}}, 
                        velocity_field_e::Interpolations.Extrapolation{<:SVector{3}, 3},
                        velocity_field_h::Interpolations.Extrapolation{<:SVector{3}, 3},
                        Δt::RQ; max_nsteps::Int = 2000, verbose::Bool = true)::Vector{EHDriftPath{T}} where {T <: SSDFloat, RQ <: RealQuantity}

    drift_paths::Vector{EHDriftPath{T}} = Vector{EHDriftPath{T}}(undef, length(starting_points)) 

    dt::T = T(to_internal_units(internal_time_unit, Δt))

    for i in eachindex(starting_points)
        drift_path_e::Vector{CartesianPoint{T}} = zeros(CartesianPoint{T}, max_nsteps )#Vector{CartesianPoint{T}}(undef, max_nsteps)
        drift_path_h::Vector{CartesianPoint{T}} = zeros(CartesianPoint{T}, max_nsteps )#Vector{CartesianPoint{T}}(undef, max_nsteps)
        timestamps_e::Vector{T} = Vector{T}(undef, max_nsteps)
        timestamps_h::Vector{T} = Vector{T}(undef, max_nsteps)
        n_e::Int = _drift_charge!(drift_path_e, timestamps_e, detector, point_types, grid, starting_points[i], dt, velocity_field_e, verbose = verbose)
        n_h::Int = _drift_charge!(drift_path_h, timestamps_h, detector, point_types, grid, starting_points[i], dt, velocity_field_h, verbose = verbose)
        drift_paths[i] = EHDriftPath{T, T}( drift_path_e[1:n_e], drift_path_h[1:n_h], timestamps_e[1:n_e], timestamps_h[1:n_h] )
    end

    return drift_paths 
end

function _drift_charge( detector::SolidStateDetector{T}, grid::Grid{T, 3}, point_types::PointTypes{T, 3},
                       starting_point::CartesianPoint{<:SSDFloat}, 
                       velocity_field_e::Interpolations.Extrapolation{SVector{3, T}, 3},
                       velocity_field_h::Interpolations.Extrapolation{SVector{3, T}, 3},
                       Δt::RealQuantity, max_nsteps::Int = 2000, verbose::Bool = true)::Vector{EHDriftPath{T}} where {T <: SSDFloat}
    return _drift_charges(detector, grid, CartesianPoint{T}.(point_types), [starting_point], velocity_field_e, velocity_field_h, T(Δt.val) * unit(Δt), max_nsteps = max_nsteps, verbose = verbose)
end

