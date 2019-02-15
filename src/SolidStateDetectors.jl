# This file is a part of SolidStateDetectors.jl, licensed under the MIT License (MIT).

__precompile__(true)

module SolidStateDetectors

using LinearAlgebra
using Random
using Statistics

using ArraysOfArrays
using Interpolations
using IntervalSets
using JSON
using LaTeXStrings
using ParallelProcessingTools
using ProgressMeter
using RecipesBase
using StaticArrays
using Unitful

import Clustering
import Distributions
import Tables
import TypedTables

import Base: size, sizeof, length, getindex, setindex!, axes, range, ndims, eachindex, enumerate, iterate, IndexStyle, eltype, in
import Base: show, print, println, display, +


const SSD = SolidStateDetectors; export SSD
export SolidStateDetector
export SSD_examples


export AbstractChargeDriftModels, get_electron_drift_field, get_hole_drift_field
export VacuumChargeDriftModel, ADLChargeDriftModel
export Grid
export ElectricPotential, PointTypes, ChargeDensity, DielectricDistribution, WeightingPotential
export calculate_electric_potential, calculate_weighting_potential, get_active_volume
export generate_charge_signals!, generate_charge_signals


include("Axes/DiscreteAxis.jl")
include("Grids/Grids.jl")
include("Types/Types.jl")

include("MaterialProperties/MaterialProperties.jl")
include("Geometries/Geometries.jl")
include("Config/Config.jl")
include("DetectorGeometries/DetectorGeometries.jl")
include("GeometryRounding.jl")

include("Config/Config.jl")
include("PotentialSimulation/PotentialSimulation.jl")

include("ElectricField/ElectricField.jl")
include("ChargeDriftModels/ChargeDriftModels.jl")
include("ChargeDrift/ChargeDrift.jl")
include("ChargeStatistics/ChargeStatistics.jl")
include("ChargeClustering/ChargeClustering.jl")

include("IO/IO.jl")

include("examples.jl")

end # module
