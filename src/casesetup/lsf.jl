"""
This file creates large-scale-forcing files (lsf) for potential temperature tendency (tp), specific humidity tendency (q), as well as large-scale u-, v- and w- winds.

Features include:
    - Specification of either vertical or pressure coordinates (default is pressure)
    - Default distribution of vertical levels is that of ECMWF reanalysis output
    - Can specify multiple large-scale forcings/tendencies, but note that later ones will override earlier ones

Limitations:
    - Yet to implement hybrid-sigma coordinates for vertical level specification
"""

function lsfinit(
    nvert::Integer=0;
    ispre::Bool=true, isvert::Bool=false, ishybrid::Bool=false
)

    if nvert == 0
        lsf = zeros(37,7); lsf[:,1] .= -999.0
        lsf[:,2] .= [
            1000.0,975.0,950.0,925.0,900.0,875.0,850.0,825.0,800.0,775.0,750.0,
            700.0,650.0,600.0,550.0,500.0,450.0,400.0,350.0,300.0,250.0,
            225.0,200.0,175.0,150.0,125.0,100.0,
            70.0,50.0,30.0,20.0,10.0,7.0,5.0,3.0,2.0,1.0
        ]
    else
        lsf = zeros(nvert,7); lsf[:,1] .= -999.0
    end

    return lsf

end

function lsfprint(flsf::AbstractString,lsf::Array{<:Real,2},p::Real)

    nz = size(lsf,1)

    open(flsf,"w") do io
        @printf(io,"  z[m] p[mb] tpls[K/s] qls[kg/kg/s] uls_hor vls_hor wls[m/s]\n")
        @printf(io,"%10.2f, %10d, %10.2f\n",0.00,nz,p)
    end

    open(flsf,"a") do io
        for iz = 1 : nz
            @printf(
                io,"%16.8f, %16.0f, %16.8e, %16.8e, %16.8f, %16.8f, %16.8f\n",
                lsf[iz,1],lsf[iz,2],lsf[iz,3],
                lsf[iz,4],lsf[iz,5],lsf[iz,6],lsf[iz,7]
            )
        end
    end

    open(flsf,"a") do io
        @printf(io,"%10.2f, %10d, %10.2f\n",10000.00,nz,p)
    end

    open(flsf,"a") do io
        for iz = 1 : nz
            @printf(
                io,"%16.8f, %16.0f, %16.8e, %16.8e, %16.8f, %16.8f, %16.8f\n",
                lsf[iz,1],lsf[iz,2],lsf[iz,3],
                lsf[iz,4],lsf[iz,5],lsf[iz,6],lsf[iz,7]
            )
        end
    end

end
