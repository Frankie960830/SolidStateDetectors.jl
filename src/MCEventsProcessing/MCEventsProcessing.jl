include("table_utils.jl")

function simulate_waveforms( mcevents::TypedTables.Table, s::Simulation{T};
                             Δt::RealQuantity = 4u"ns",
                             max_steps::Int = 1000,
                             verbose = false ) where {T <: SSDFloat}
    n_total_physics_events = length(mcevents)
    Δtime = T(to_internal_units(internal_time_unit, Δt)) 
    n_contacts = length(s.detector.contacts)
    S = Val(get_coordinate_system(s.electric_potential.grid))
    contacts = s.detector.contacts;
    wps_interpolated = [interpolated_scalarfield(s.weighting_potentials[contact.id]) for contact in contacts ];
    e_drift_field = get_interpolated_drift_field(s.electron_drift_field);
    h_drift_field = get_interpolated_drift_field(s.hole_drift_field);
    
    @info "Detector has $(n_contacts) contact(s)"
    @info "Table has $(length(mcevents)) physics events ($(length(flatview(mcevents.edep))) single charge depositions)."

    # First simulate drift paths
    drift_paths = _simulate_charge_drifts(mcevents, s, Δt, max_steps, e_drift_field, h_drift_field, verbose)
    # now iterate over contacts and generate the waveform for each contact
    @info "Generating waveforms..."
    waveforms = map( 
        wp ->  map( 
            x -> _generate_waveform(x.dps, to_internal_units.(internal_energy_unit, x.edeps), Δt, Δtime, wp, S),
            TypedTables.Table(dps = drift_paths, edeps = mcevents.edep)
        ),
        wps_interpolated
    )

    mcevents_chns = map(
        i -> add_column(mcevents, :chnid, fill(contacts[i].id, n_total_physics_events)),
        eachindex(contacts)
    )
    mcevents_chns = map(
        i -> add_column(mcevents_chns[i], :waveform, ArrayOfRDWaveforms(waveforms[1])),
        eachindex(waveforms)
    )
    return vcat(mcevents_chns...)  
end


function _simulate_charge_drifts( mcevents::TypedTables.Table, s::Simulation{T},
                                  Δt::RealQuantity, max_steps::Int, 
                                  e_drift_field::Interpolations.Extrapolation, h_drift_field::Interpolations.Extrapolation, 
                                  verbose::Bool ) where {T <: SSDFloat}
    return @showprogress map(mcevents) do phyevt
        _drift_charges(s.detector, s.electric_potential.grid, s.point_types, 
                        CartesianPoint.(to_internal_units.(u"m", phyevt.pos)),
                        e_drift_field, h_drift_field, 
                        Δt, n_steps = max_steps, verbose = verbose)
    end
end



function _generate_waveform( drift_paths::Vector{EHDriftPath{T}}, charges::Vector{T}, Δt::RealQuantity, dt::T,
                             wp::Interpolations.Extrapolation{T, 3}, S::Union{Val{:cylindrical}, Val{:cartesian}}) where {T <: SSDFloat}
    timestamps = _common_timestamps( drift_paths, dt )
    timestamps_with_units = range(zero(Δt), step = Δt, length = length(timestamps))

    signal = zeros(T, length(timestamps))
    add_signal!(signal, timestamps, drift_paths, charges, wp, S)
    RDWaveform( timestamps_with_units, signal )
end


