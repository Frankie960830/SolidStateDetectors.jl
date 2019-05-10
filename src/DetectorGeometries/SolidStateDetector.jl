"""
    mutable struct SolidStateDetector{T <: SSDFloat, CS} <: AbstractConfig{T}

CS: Coordinate System: -> :cartesian / :cylindrical
"""
mutable struct SolidStateDetector{T <: SSDFloat, CS} <: AbstractConfig{T}
    name::String  # optional
    inputunits::Dict{String, Unitful.Units}
    world::World{T, 3}

    config_dict::Dict

    medium::NamedTuple # this should become a struct at some point

    semiconductors::Vector{Semiconductor{T}}
    contacts::Vector{Contact{T}}
    passives::Vector{Passive{T}}

    SolidStateDetector{T, CS}() where {T <: SSDFloat, CS} = new{T, CS}()
end

get_precision_type(d::SolidStateDetector{T}) where {T} = T
get_coordinate_system(d::SolidStateDetector{T, CS}) where {T, CS} = CS

function construct_units(config_file_dict::Dict)
    dunits::Dict{String, Unitful.Units} = Dict{String, Unitful.Units}(  
        "length" => u"m", # change this to u"m" ? SI Units
        "potential" => u"V", 
        "angle" => u"°", 
        "temperature" => u"K"
    )
    if haskey(config_file_dict, "setup")
        if haskey(config_file_dict["setup"], "units")
            d = config_file_dict["setup"]["units"]
            if haskey(d, "length") dunits["length"] = unit_conversion[d["length"]] end
            if haskey(d, "angle") dunits["angle"] = unit_conversion[d["angle"]] end
            if haskey(d, "potential") dunits["potential"] = unit_conversion[d["potential"]] end
            if haskey(d, "temperature") dunits["temperature"] = unit_conversion[d["temperature"]] end
        end
    end
    dunits
end


function construct_semiconductor(T, sc::Dict, inputunit_dict::Dict{String, Unitful.Units})
    Semiconductor{T}(sc, inputunit_dict)
end

function construct_passive(T, pass::Dict, inputunit_dict::Dict{String, Unitful.Units})
    Passive{T}(pass, inputunit_dict)
end

function construct_contact(T, contact::Dict, inputunit_dict::Dict{String, Unitful.Units})
    Contact{T}(contact, inputunit_dict)
end

function construct_objects(T, objects::Vector, semiconductors, contacts, passives, inputunit_dict)::Nothing
    for obj in objects
        if obj["type"] == "semiconductor"
            push!(semiconductors, construct_semiconductor(T, obj, inputunit_dict))
        elseif obj["type"] == "contact"
            push!(contacts, construct_contact(T, obj, inputunit_dict))
        elseif obj["type"] == "passive"
            push!(passives, construct_passive(T, obj, inputunit_dict))
        else
            @warn "please spcify the calss to bei either a \"semiconductor\", a \"contact\", or \"passive\""
        end
    end
    nothing
end

function get_world_limits_from_objects(S::Val{:cylindrical}, s::Vector{Semiconductor{T}}, c::Vector{Contact{T}}, p::Vector{Passive{T}}) where {T <: SSDFloat}
    ax1l::T, ax1r::T, ax2l::T, ax2r::T, ax3l::T, ax3r::T = 0, 1, 0, 1, 0, 1
    imps_1::Vector{T} = []
    imps_3::Vector{T} = []
    for objects in [s, c, p]
        for object in objects
            for posgeo in object.geometry_positive
                append!(imps_1, get_important_points( posgeo, Val{:r}()))
                append!(imps_3, get_important_points( posgeo, Val{:z}()))
            end
        end
    end
    imps_1 = uniq(sort(imps_1))
    imps_3 = uniq(sort(imps_3))
    if length(imps_1) > 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1)
    elseif length(imps_1) == 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1) + 1
    end
    if length(imps_3) > 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3)
    elseif length(imps_3) == 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3) + 1
    end
    return ax1l, ax1r, ax2l, ax2r, ax3l, ax3r
end
function get_world_limits_from_objects(S::Val{:cartesian}, s::Vector{Semiconductor{T}}, c::Vector{Contact{T}}, p::Vector{Passive{T}}) where {T <: SSDFloat}
    ax1l::T, ax1r::T, ax2l::T, ax2r::T, ax3l::T, ax3r::T = 0, 1, 0, 1, 0, 1
    imps_1::Vector{T} = []
    imps_2::Vector{T} = []
    imps_3::Vector{T} = []
    for objects in [s, c, p]
        for object in objects
            for posgeo in object.geometry_positive
                append!(imps_1, get_important_points( posgeo, Val{:x}()))
                append!(imps_2, get_important_points( posgeo, Val{:y}()))
                append!(imps_3, get_important_points( posgeo, Val{:z}()))
            end
        end
    end
    imps_1 = uniq(sort(imps_1))
    imps_2 = uniq(sort(imps_2))
    imps_3 = uniq(sort(imps_3))
    if length(imps_1) > 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1)
    elseif length(imps_1) == 1
        ax1l = minimum(imps_1)
        ax1r = maximum(imps_1) + 1
    end
    if length(imps_2) > 1
        ax2l = minimum(imps_2)
        ax2r = maximum(imps_2)
    elseif length(imps_2) == 1
        ax2l = minimum(imps_2)
        ax2r = maximum(imps_2) + 1
    end
    if length(imps_3) > 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3)
    elseif length(imps_3) == 1
        ax3l = minimum(imps_3)
        ax3r = maximum(imps_3) + 1
    end
    return ax1l, ax1r, ax2l, ax2r, ax3l, ax3r
end

function SolidStateDetector{T}(config_file::Dict)::SolidStateDetector{T} where{T <: SSDFloat}
    grid_type::Symbol = :cartesian
    semiconductors::Vector{Semiconductor{T}}, contacts::Vector{Contact{T}}, passives::Vector{Passive{T}} = [], [], []
    medium::NamedTuple = material_properties[materials["vacuum"]]
    inputunits = dunits::Dict{String, Unitful.Units} = Dict{String, Unitful.Units}(  
        "length" => u"m", # change this to u"m" ? SI Units
        "potential" => u"V", 
        "angle" => u"°", 
        "temperature" => u"K"
    )
    world = if haskey(config_file, "setup")
        inputunits = construct_units(config_file)
        @show inputunits
        if haskey(config_file["setup"], "medium")
            medium = material_properties[materials[config_file["setup"]["medium"]]]
        end
        @show medium.name

        if haskey(config_file["setup"], "objects")
            construct_objects(T, config_file["setup"]["objects"], semiconductors, contacts, passives, inputunits)
        end

        if haskey(config_file["setup"], "grid")
            if isa(config_file["setup"]["grid"], Dict)
                grid_type = Symbol(config_file["setup"]["grid"]["coordinates"])
                World(T, config_file["setup"]["grid"], inputunits)
            elseif isa(config_file["setup"]["grid"], String)
                grid_type = Symbol(config_file["setup"]["grid"])
                world_limits = get_world_limits_from_objects(Val(grid_type), semiconductors, contacts, passives)
                World(Val(grid_type), world_limits)
            end
        else
            world_limits = get_world_limits_from_objects(Val(grid_type), semiconductors, contacts, passives )
            World(Val(grid_type), world_limits)
        end
    else
        world_limits = get_world_limits_from_objects(Val(grid_type), semiconductors, contacts, passives )
        World(Val(grid_type), world_limits)
    end

    c = SolidStateDetector{T, grid_type}()
    c.name = haskey(config_file, "name") ? config_file["name"] : "NoNameDetector"
    c.config_dict = config_file
    c.semiconductors = semiconductors
    c.contacts = contacts
    c.passives = passives
    c.inputunits = inputunits
    c.medium = medium
    c.world = world
    return c
end

function SolidStateDetector(parsed_dict::Dict)
    SolidStateDetector{Float32}(parsed_dict)
end

function Base.sort!(v::AbstractVector{<:AbstractGeometry})
    hierarchies::Vector{Int} = map(x->x.hierarchy,v)
    v_result::typeof(v) = []
    for idx in sort!(unique!(hierarchies))
        push!(v_result,filter(x->x.hierarchy == hierarchies[idx],v)...)
    end
    return v_result
end

function SolidStateDetector{T}(parsed_dict::Dict) where T
    SolidStateDetector{T}(parsed_dict)
end

function contains(c::SolidStateDetector, point::AbstractCoordinatePoint{T,3})::Bool where T
    for contact in c.contacts
        if point in contact
            return true
        end
    end
    for sc in c.semiconductors
        if point in sc
            return true
        end
    end
    return false
end

function println(io::IO, d::SolidStateDetector{T, CS}) where {T <: SSDFloat, CS}
    println("________"*d.name*"________\n")
    # println("Class: ",d.class)
    println("---General Properties---")
    println("-Environment Material: \t $(d.medium.name)")
    println("-Grid Type: \t $(CS)")
    println()
    println("# Semiconductors: $(length(d.semiconductors))")
    for (isc, sc)  in enumerate(d.semiconductors)
        println("\t_____Semiconductor $(isc)_____\n")
        println(sc)
    end
    println()
    println("# Contacts: $(length(d.contacts))")
    if length(d.contacts)<=5
        for c in d.contacts
            println(c)
        end
    end
    println()
    println("# Passives: $(length(d.passives))")
    if length(d.passives)<=5
        for p in d.passives
            # println(c)
        end
    end
end

function show(io::IO, d::SolidStateDetector{T}) where {T <: SSDFloat} println(d) end
function print(io::IO, d::SolidStateDetector{T}) where {T <: SSDFloat} println(d) end
function display(io::IO, d::SolidStateDetector{T} ) where {T <: SSDFloat} println(d) end
function show(io::IO,::MIME"text/plain", d::SolidStateDetector) where {T <: SSDFloat}
    show(io, d)
end


# ToDo: Test it
function generate_random_startpositions(d::SolidStateDetector{T}, n::Int, Volume::NamedTuple=bounding_box(d), rng::AbstractRNG = MersenneTwister(), min_dist_from_boundary = 0.0001) where T
    delta = T(min_dist_from_boundary)
    n_filled::Int = 0
    positions = Vector{CartesianPoint{T}}(undef,n)
    while n_filled < n
        sample=CylindricalPoint{T}(rand(rng,Volume[:r_range].left:0.00001:Volume[:r_range].right),rand(rng,Volume[:φ_range].left:0.00001:Volume[:φ_range].right),rand(rng,Volume[:z_range].left:0.00001:Volume[:z_range].right))
        if !(sample in d.contacts) && contains(d,sample) && contains(d,CylindricalPoint{T}(sample.r+delta,sample.φ,sample.z))&& contains(d,CylindricalPoint{T}(sample.r-delta,sample.φ,sample.z))&& contains(d,CylindricalPoint{T}(sample.r,sample.φ,sample.z+delta))&& contains(d,CylindricalPoint{T}(sample.r,sample.φ,sample.z-delta))
            n_filled += 1
            positions[n_filled]=CartesianPoint(sample)
        end
    end
    positions
end
