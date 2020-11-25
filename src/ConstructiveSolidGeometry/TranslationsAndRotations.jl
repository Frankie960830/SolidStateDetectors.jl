struct StretchedGeometry{T,P<:AbstractGeometry{T}} <: AbstractGeometry{T}
    p::P
    inv_s::SVector{3,T}
    StretchedGeometry(p::P, s::SVector{3,T}) where {T,P} = new{T,P}(p, inv.(s))
end
in(p::CartesianPoint, g::StretchedGeometry) = in(CartesianPoint(g.inv_s .* p), g.p)
stretch(g::AbstractGeometry, s::SVector{3,T}) where {T} = StretchedGeometry(g, s)
stretch(g::StretchedGeometry, s::SVector{3,T}) where {T} = StretchedGeometry(g.p, g.inv_s .* inv.(s))

struct RotatedGeometry{T,P<:AbstractGeometry{T},RT} <: AbstractGeometry{T}
    p::P
    inv_r::RotMatrix{3,RT,9}
    RotatedGeometry(p::AbstractGeometry{T}, r::RotMatrix{3,RT,9}) where {T,RT} = new{T,typeof(p),RT}(p, inv(r))
end
in(p::CartesianPoint, g::RotatedGeometry) = in(g.inv_r * p, g.p)
rotate(g::AbstractGeometry{T}, r::RotMatrix{3,RT,9}) where {T,RT} = RotatedGeometry(g, r)
rotate(g::RotatedGeometry{T,<:Any,RT}, r::RotMatrix{3,RT,9}) where {T,RT} = RotatedGeometry{T,typeof(g),RT}(g.p, inv(r) * gp.r)


struct TranslatedGeometry{T,P<:AbstractGeometry{T}} <: AbstractGeometry{T}
    p::P
    t::CartesianVector{T}
end
in(p::CartesianPoint, g::TranslatedGeometry) = in(p - g.t, g.p)
translate(g::AbstractGeometry{T}, t::CartesianVector{T}) where {T} = TranslatedGeometry(g, t)
translate(g::TranslatedGeometry{T}, t::CartesianVector{T}) where {T} = TranslatedGeometry(g.p, g.t + t)

