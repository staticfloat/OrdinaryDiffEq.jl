function ode_solve{uType<:Number,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{BS3,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  a21,a32,a41,a42,a43,c1,c2,b1,b2,b3,b4  = constructBS3(uEltypeNoUnits)
  local k1::rateType
  local k2::rateType
  local k3::rateType
  local k4::rateType
  local utilde::uType
  integrator.fsalfirst = f(t,uprev) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      k1 = integrator.fsalfirst
      k2 = f(t+c1*dt,uprev+dt*a21*k1)
      k3 = f(t+c2*dt,uprev+dt*a32*k2)
      u = uprev+dt*(a41*k1+a42*k2+a43*k3)
      k4 = f(t+dt,u); integrator.fsallast = k4
      if integrator.opts.adaptive
        utilde = uprev + dt*(b1*k1 + b2*k2 + b3*k3 + b4*k4)
        integrator.EEst = abs( ((utilde-u)/(integrator.opts.abstol+max(abs(uprev),abs(u))*integrator.opts.reltol)))
      end
      if integrator.opts.calck
        k = integrator.fsallast
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end

function ode_solve{uType<:AbstractArray,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{BS3,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  a21,a32,a41,a42,a43,c1,c2,b1,b2,b3,b4  = constructBS3(uEltypeNoUnits)
  uidx = eachindex(uprev)


  @unpack k1,k2,k3,k4,utilde,tmp,atmp = integrator.cache

  integrator.k = k4
  integrator.fsalfirst = k1  # done by pointers, no copying
  integrator.fsallast = k4

  f(t,uprev,integrator.fsalfirst) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      for i in uidx
        tmp[i] = uprev[i]+dt*a21*k1[i]
      end
      f(t+c1*dt,tmp,k2)
      for i in uidx
        tmp[i] = uprev[i]+dt*a32*k2[i]
      end
      f(t+c2*dt,tmp,k3)
      for i in uidx
        u[i] = uprev[i]+dt*(a41*k1[i]+a42*k2[i]+a43*k3[i])
      end
      f(t+dt,u,k4)
      if integrator.opts.adaptive
        for i in uidx
          utilde[i] = uprev[i] + dt*(b1*k1[i] + b2*k2[i] + b3*k3[i] + b4*k4[i])
          atmp[i] = ((utilde[i]-u[i])/(integrator.opts.abstol+max(abs(uprev[i]),abs(u[i]))*integrator.opts.reltol))
        end
        integrator.EEst = integrator.opts.internalnorm(atmp)
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end

function ode_solve{uType<:Number,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{BS5,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  c1,c2,c3,c4,c5,a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a72,a73,a74,a75,a76,a81,a83,a84,a85,a86,a87,bhat1,bhat3,bhat4,bhat5,bhat6,btilde1,btilde2,btilde3,btilde4,btilde5,btilde6,btilde7,btilde8 = constructBS5(uEltypeNoUnits)
  local k1::rateType
  local k2::rateType
  local k3::rateType
  local k4::rateType
  local k5::rateType
  local k6::rateType
  local k7::rateType
  local k8::rateType
  local utilde::uType
  local EEst2::uEltypeNoUnits
  integrator.kshortsize = 8
  k = ksEltype(integrator.kshortsize)
  integrator.k = k
  integrator.fsalfirst = f(t,uprev) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      k1 = integrator.fsalfirst
      k2 = f(t+c1*dt,uprev+dt*a21*k1)
      k3 = f(t+c2*dt,uprev+dt*(a31*k1+a32*k2))
      k4 = f(t+c3*dt,uprev+dt*(a41*k1+a42*k2+a43*k3))
      k5 = f(t+c4*dt,uprev+dt*(a51*k1+a52*k2+a53*k3+a54*k4))
      k6 = f(t+c5*dt,uprev+dt*(a61*k1+a62*k2+a63*k3+a64*k4+a65*k5))
      k7 = f(t+dt,uprev+dt*(a71*k1+a72*k2+a73*k3+a74*k4+a75*k5+a76*k6))
      u = uprev+dt*(a81*k1+a83*k3+a84*k4+a85*k5+a86*k6+a87*k7)
      integrator.fsallast = f(t+dt,u); k8 = integrator.fsallast
      if integrator.opts.adaptive
        uhat   = dt*(bhat1*k1 + bhat3*k3 + bhat4*k4 + bhat5*k5 + bhat6*k6)
        utilde = uprev + dt*(btilde1*k1 + btilde2*k2 + btilde3*k3 + btilde4*k4 + btilde5*k5 + btilde6*k6 + btilde7*k7 + btilde8*k8)
        EEst1 = abs( sum(((uhat)./(integrator.opts.abstol+max(abs(uprev),abs(u))*integrator.opts.reltol))))
        EEst2 = abs( sum(((utilde-u)./(integrator.opts.abstol+max(abs(uprev),abs(u))*integrator.opts.reltol))))
        integrator.EEst = max(EEst1,EEst2)
      end
      if integrator.opts.calck
        k[1]=k1; k[2]=k2; k[3]=k3;k[4]=k4;k[5]=k5;k[6]=k6;k[7]=k7;k[8]=k8
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end

function ode_solve{uType<:AbstractArray,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{BS5,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  c1,c2,c3,c4,c5,a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a72,a73,a74,a75,a76,a81,a83,a84,a85,a86,a87,bhat1,bhat3,bhat4,bhat5,bhat6,btilde1,btilde2,btilde3,btilde4,btilde5,btilde6,btilde7,btilde8 = constructBS5(uEltypeNoUnits)
  integrator.kshortsize = 8
  local EEst2::uEltypeNoUnits
  uidx = eachindex(uprev)


  @unpack k1,k2,k3,k4,k5,k6,k7,k8,utilde,uhat,tmp,atmp,atmptilde = integrator.cache

  integrator.k = ksEltype(integrator.kshortsize)
  integrator.k[1]=k1; integrator.k[2]=k2; integrator.k[3]=k3; integrator.k[4]=k4;
  integrator.k[5]=k5; integrator.k[6]=k6; integrator.k[7]=k7; integrator.k[8]=k8

  integrator.fsalfirst = k1; integrator.fsallast = k8  # setup pointers
  f(t,uprev,k1) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      for i in uidx
        tmp[i] = uprev[i]+dt*a21*k1[i]
      end
      f(t+c1*dt,tmp,k2)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a31*k1[i]+a32*k2[i])
      end
      f(t+c2*dt,tmp,k3)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a41*k1[i]+a42*k2[i]+a43*k3[i])
      end
      f(t+c3*dt,tmp,k4)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a51*k1[i]+a52*k2[i]+a53*k3[i]+a54*k4[i])
      end
      f(t+c4*dt,tmp,k5)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a61*k1[i]+a62*k2[i]+a63*k3[i]+a64*k4[i]+a65*k5[i])
      end
      f(t+c5*dt,tmp,k6)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a71*k1[i]+a72*k2[i]+a73*k3[i]+a74*k4[i]+a75*k5[i]+a76*k6[i])
      end
      f(t+dt,tmp,k7)
      for i in uidx
        u[i] = uprev[i]+dt*(a81*k1[i]+a83*k3[i]+a84*k4[i]+a85*k5[i]+a86*k6[i]+a87*k7[i])
      end
      f(t+dt,u,k8)
      if integrator.opts.adaptive
        for i in uidx
          uhat[i]   = dt*(bhat1*k1[i] + bhat3*k3[i] + bhat4*k4[i] + bhat5*k5[i] + bhat6*k6[i])
          utilde[i] = uprev[i] + dt*(btilde1*k1[i] + btilde2*k2[i] + btilde3*k3[i] + btilde4*k4[i] + btilde5*k5[i] + btilde6*k6[i] + btilde7*k7[i] + btilde8*k8[i])
          atmp[i] = ((uhat[i])./(integrator.opts.abstol+max(abs(uprev[i]),abs(u[i]))*integrator.opts.reltol))
          atmptilde[i] = ((utilde[i]-u[i])./(integrator.opts.abstol+max(abs(uprev[i]),abs(u[i]))*integrator.opts.reltol))
        end
        EEst1 = integrator.opts.internalnorm(atmp)
        EEst2 = integrator.opts.internalnorm(atmptilde)
        integrator.EEst = max(EEst1,EEst2)
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end

function ode_solve{uType<:Number,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{Tsit5,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  c1,c2,c3,c4,c5,c6,a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a72,a73,a74,a75,a76,b1,b2,b3,b4,b5,b6,b7 = constructTsit5(uEltypeNoUnits)
  local k1::rateType
  local k2::rateType
  local k3::rateType
  local k4::rateType
  local k5::rateType
  local k6::rateType
  local k7::rateType
  local utilde::uType
  integrator.kshortsize = 7
  k = ksEltype(integrator.kshortsize)
  integrator.k = k
  integrator.fsalfirst = f(t,uprev) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      k1 = integrator.fsalfirst
      k2 = f(t+c1*dt,uprev+dt*(a21*k1))
      k3 = f(t+c2*dt,uprev+dt*(a31*k1+a32*k2))
      k4 = f(t+c3*dt,uprev+dt*(a41*k1+a42*k2+a43*k3))
      k5 = f(t+c4*dt,uprev+dt*(a51*k1+a52*k2+a53*k3+a54*k4))
      k6 = f(t+dt,uprev+dt*(a61*k1+a62*k2+a63*k3+a64*k4+a65*k5))
      u = uprev+dt*(a71*k1+a72*k2+a73*k3+a74*k4+a75*k5+a76*k6)
      integrator.fsallast = f(t+dt,u); k7 = integrator.fsallast
      if integrator.opts.adaptive
        utilde = uprev + dt*(b1*k1 + b2*k2 + b3*k3 + b4*k4 + b5*k5 + b6*k6 + b7*k7)
        integrator.EEst = abs(((utilde-u)/(integrator.opts.abstol+max(abs(uprev),abs(u))*integrator.opts.reltol)))
      end
      if integrator.opts.calck
        k[1] = k1
        k[2] = k2
        k[3] = k3
        k[4] = k4
        k[5] = k5
        k[6] = k6
        k[7] = k7
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end

function ode_solve{uType<:AbstractArray,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{Tsit5,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  c1,c2,c3,c4,c5,c6,a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a72,a73,a74,a75,a76,b1,b2,b3,b4,b5,b6,b7 = constructTsit5(uEltypeNoUnits)
  integrator.kshortsize = 7
  uidx = eachindex(uprev)


  @unpack k1,k2,k3,k4,k5,k6,k7,utilde,tmp,atmp = integrator.cache

  integrator.fsalfirst = k1; integrator.fsallast = k7 # setup pointers

  k = ksEltype(integrator.kshortsize)
  integrator.k = k
  # Setup k pointers
  integrator.k[1] = k1
  integrator.k[2] = k2
  integrator.k[3] = k3
  integrator.k[4] = k4
  integrator.k[5] = k5
  integrator.k[6] = k6
  integrator.k[7] = k7


  f(t,uprev,k1) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      for i in uidx
        tmp[i] = uprev[i]+dt*(a21*k1[i])
      end
      f(t+c1*dt,tmp,k2)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a31*k1[i]+a32*k2[i])
      end
      f(t+c2*dt,tmp,k3)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a41*k1[i]+a42*k2[i]+a43*k3[i])
      end
      f(t+c3*dt,tmp,k4)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a51*k1[i]+a52*k2[i]+a53*k3[i]+a54*k4[i])
      end
      f(t+c4*dt,tmp,k5)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a61*k1[i]+a62*k2[i]+a63*k3[i]+a64*k4[i]+a65*k5[i])
      end
      f(t+dt,tmp,k6)
      for i in uidx
        u[i] = uprev[i]+dt*(a71*k1[i]+a72*k2[i]+a73*k3[i]+a74*k4[i]+a75*k5[i]+a76*k6[i])
      end
      f(t+dt,u,k7)
      if integrator.opts.adaptive
        for i in uidx
          utilde[i] = uprev[i] + dt*(b1*k1[i] + b2*k2[i] + b3*k3[i] + b4*k4[i] + b5*k5[i] + b6*k6[i] + b7*k7[i])
          atmp[i] = ((utilde[i]-u[i])./(integrator.opts.abstol+max(abs(uprev[i]),abs(u[i]))*integrator.opts.reltol))
        end
        integrator.EEst = integrator.opts.internalnorm(atmp)
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end

function ode_solve{uType<:Number,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{DP5,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a73,a74,a75,a76,b1,b3,b4,b5,b6,b7,c1,c2,c3,c4,c5,c6 = constructDP5(uEltypeNoUnits)
  local k1::rateType
  local k2::rateType
  local k3::rateType
  local k4::rateType
  local k5::rateType
  local k6::rateType
  local k7::rateType
  local update::rateType
  local bspl::rateType
  integrator.kshortsize = 4
  d1,d3,d4,d5,d6,d7 = DP5_dense_ds(uEltypeNoUnits)
  integrator.k = ksEltype(integrator.kshortsize)
  local utilde::uType
  integrator.fsalfirst = f(t,uprev) # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      k1 = integrator.fsalfirst
      k2 = f(t+c1*dt,uprev+dt*(a21*k1))
      k3 = f(t+c2*dt,uprev+dt*(a31*k1+a32*k2))
      k4 = f(t+c3*dt,uprev+dt*(a41*k1+a42*k2+a43*k3))
      k5 = f(t+c4*dt,uprev+dt*(a51*k1+a52*k2+a53*k3+a54*k4))
      k6 = f(t+dt,uprev+dt*(a61*k1+a62*k2+a63*k3+a64*k4+a65*k5))
      update = a71*k1+a73*k3+a74*k4+a75*k5+a76*k6
      u = uprev+dt*update
      integrator.fsallast = f(t+dt,u); k7 = integrator.fsallast

      if integrator.opts.adaptive
        utilde = uprev + dt*(b1*k1 + b3*k3 + b4*k4 + b5*k5 + b6*k6 + b7*k7)
        integrator.EEst = abs( ((utilde-u)/(integrator.opts.abstol+max(abs(uprev),abs(u))*integrator.opts.reltol)))
      end
      if integrator.opts.calck
        integrator.k[1] = update
        bspl = k1 - update
        integrator.k[2] = bspl
        integrator.k[3] = update - k7 - bspl
        integrator.k[4] = (d1*k1+d3*k3+d4*k4+d5*k5+d6*k6+d7*k7)
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end


function ode_solve{uType<:AbstractArray,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O}(integrator::ODEIntegrator{DP5,uType,tType,tstopsType,tTypeNoUnits,ksEltype,SolType,rateType,F,ProgressType,CacheType,ECType,O})
  @ode_preamble
  a21,a31,a32,a41,a42,a43,a51,a52,a53,a54,a61,a62,a63,a64,a65,a71,a73,a74,a75,a76,b1,b3,b4,b5,b6,b7,c1,c2,c3,c4,c5,c6 = constructDP5(uEltypeNoUnits)
  d1,d3,d4,d5,d6,d7 = DP5_dense_ds(uEltypeNoUnits)


  @unpack k1,k2,k3,k4,k5,k6,k7,dense_tmp3,dense_tmp4,update,bspl,utilde,tmp,atmp = integrator.cache

  uidx = eachindex(uprev)
  integrator.kshortsize = 4
  integrator.k = [update,bspl,dense_tmp3,dense_tmp4]
  integrator.fsalfirst = k1; integrator.fsallast = k7
  f(t,uprev,integrator.fsalfirst);  # Pre-start fsal
  @inbounds while !isempty(integrator.tstops)
    while integrator.tdir*t < integrator.tdir*top(integrator.tstops)
      @ode_loopheader
      for i in uidx
        tmp[i] = uprev[i]+dt*(a21*k1[i])
      end
      f(t+c1*dt,tmp,k2)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a31*k1[i]+a32*k2[i])
      end
      f(t+c2*dt,tmp,k3)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a41*k1[i]+a42*k2[i]+a43*k3[i])
      end
      f(t+c3*dt,tmp,k4)
      for i in uidx
        tmp[i] =uprev[i]+dt*(a51*k1[i]+a52*k2[i]+a53*k3[i]+a54*k4[i])
      end
      f(t+c4*dt,tmp,k5)
      for i in uidx
        tmp[i] = uprev[i]+dt*(a61*k1[i]+a62*k2[i]+a63*k3[i]+a64*k4[i]+a65*k5[i])
      end
      f(t+dt,tmp,k6)
      for i in uidx
        update[i] = a71*k1[i]+a73*k3[i]+a74*k4[i]+a75*k5[i]+a76*k6[i]
        u[i] = uprev[i]+dt*update[i]
      end
      f(t+dt,u,k7);
      if integrator.opts.adaptive
        for i in uidx
          utilde[i] = uprev[i] + dt*(b1*k1[i] + b3*k3[i] + b4*k4[i] + b5*k5[i] + b6*k6[i] + b7*k7[i])
          atmp[i] = ((utilde[i]-u[i])/(integrator.opts.abstol+max(abs(uprev[i]),abs(u[i]))*integrator.opts.reltol))
        end
        integrator.EEst = integrator.opts.internalnorm(atmp)
      end
      if integrator.opts.calck
        for i in uidx
          bspl[i] = k1[i] - update[i]
          integrator.k[3][i] = update[i] - k7[i] - bspl[i]
          integrator.k[4][i] = (d1*k1[i]+d3*k3[i]+d4*k4[i]+d5*k5[i]+d6*k6[i]+d7*k7[i])
        end
      end
      @pack_integrator
      ode_loopfooter!(integrator)
      @unpack_integrator
      if isempty(integrator.tstops)
        break
      end
    end
    !isempty(integrator.tstops) && pop!(integrator.tstops)
  end
  ode_postamble!(integrator)
  nothing
end
