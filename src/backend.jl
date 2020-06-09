function samncoffsetscale(data::Array{<:Real})

    dmax = maximum(data); dmin = minimum(data);
    scale = (dmax-dmin) / 65533;
    offset = (dmax+dmin-scale) / 2;

    return scale,offset

end
