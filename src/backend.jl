function samncoffsetscale(data::Array{<:Real})

    dmax = maximum(data); dmin = minimum(data);
    scale = (dmax-dmin) / 65533;
    offset = (dmax+dmin-scale) / 2;

    return scale,offset

end

function findids(inc::Integer,nct::Integer,it::Integer=1)

    ids = ((inc-1)*360+it)/nct; if ids != convert(Int64,floor(ids))
          ids = convert(Int64,floor(ids)) + 1;
    else; ids = convert(Int64,floor(ids));
    end

    return ids

end
