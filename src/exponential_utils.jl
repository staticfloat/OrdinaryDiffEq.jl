# exponential_utils.jl
# Contains functions related to the evaluation of scalar/matrix phi functions 
# that are used by the exponential integrators.
#
# TODO: write a version of `expm!` that is non-allocating.

###################################################
# Dense algorithms

"""
    phi(z,k[;cache]) -> [phi_0(z),phi_1(z),...,phi_k(z)]

Compute the scalar phi functions for all orders up to k.

The phi functions are defined as

```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

Instead of using the recurrence relation, which is numerically unstable, a 
formula given by Sidje is used (Sidje, R. B. (1998). Expokit: a software 
package for computing matrix exponentials. ACM Transactions on Mathematical 
Software (TOMS), 24(1), 130-156. Theorem 1).
"""
function phi(z::T, k::Integer; cache=nothing) where {T <: Number}
  # Construct the matrix
  if cache == nothing
    cache = zeros(T, k+1, k+1)
  else
    fill!(cache, zero(T))
  end
  cache[1,1] = z
  for i = 1:k
    cache[i,i+1] = one(T)
  end
  P = Base.LinAlg.expm!(cache)
  return P[1,:]
end

"""
    phimv_dense(A,v,k[;cache]) -> [phi_0(A)v phi_1(A)v ... phi_k(A)v]

Compute the matrix-phi-vector products for small, dense `A`.

The phi functions are defined as

```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

Instead of using the recurrence relation, which is numerically unstable, a 
formula given by Sidje is used (Sidje, R. B. (1998). Expokit: a software 
package for computing matrix exponentials. ACM Transactions on Mathematical 
Software (TOMS), 24(1), 130-156. Theorem 1).
"""
function phimv_dense(A, v, k; cache=nothing)
  w = Matrix{eltype(A)}(length(v), k+1)
  phimv_dense!(w, A, v, k; cache=cache)
end
"""
    phimv_dense!(w,A,v,k[;cache]) -> w

Non-allocating version of `phimv_dense`.
"""
function phimv_dense!(w::AbstractMatrix{T}, A::AbstractMatrix{T}, 
  v::AbstractVector{T}, k::Integer; cache=nothing) where {T <: Number}
  @assert size(w, 1) == size(A, 1) == size(A, 2) == length(v) "Dimension mismatch"
  @assert size(w, 2) == k+1 "Dimension mismatch"
  m = length(v)
  # Construct the extended matrix
  if cache == nothing
    cache = zeros(T, m+k, m+k)
  else
    @assert size(cache) == (m+k, m+k) "Dimension mismatch"
    fill!(cache, zero(T))
  end
  cache[1:m, 1:m] = A
  cache[1:m, m+1] = v
  for i = m+1:m+k-1
    cache[i, i+1] = one(T)
  end
  P = Base.LinAlg.expm!(cache)
  # Extract results
  @views A_mul_B!(w[:, 1], P[1:m, 1:m], v)
  @inbounds for i = 1:k
    @inbounds for j = 1:m
      w[j, i+1] = P[j, m+i]
    end
  end
  return w
end

"""
    phim(A,k[;cache]) -> [phi_0(A),phi_1(A),...,phi_k(A)]

Compute the matrix phi functions for all orders up to k.

The phi functions are defined as
  
```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

Calls `phimv_dense` on each of the basis vectors to obtain the answer.
"""
phim(x::Number, k) = phi(x, k) # fallback
function phim(A, k; caches=nothing)
  m = size(A, 1)
  out = [Matrix{eltype(A)}(m, m) for i = 1:k+1]
  phim!(out, A, k; caches=caches)
end
"""
    phim!(out,A,k[;caches]) -> out

Non-allocating version of `phim`.
"""
function phim!(out::Vector{Matrix{T}}, A::AbstractMatrix{T}, k::Integer; caches=nothing) where {T <: Number}
  m = size(A, 1)
  @assert length(out) == k + 1 && all(P -> size(P) == (m,m), out) "Dimension mismatch"
  if caches == nothing
    e = Vector{T}(m)
    W = Matrix{T}(m, k+1)
    C = Matrix{T}(m+k, m+k)
  else
    e, W, C = caches
    @assert size(e) == (m,) && size(W) == (m, k+1) && size(C) == (m+k, m+k) "Dimension mismatch"
  end
  @inbounds for i = 1:m
    fill!(e, zero(T)); e[i] = one(T) # e is the ith basis vector
    phimv_dense!(W, A, e, k; cache=C) # W = [phi_0(A)*e phi_1(A)*e ... phi_k(A)*e]
    @inbounds for j = 1:k+1
      @inbounds for s = 1:m
        out[j][s, i] = W[s, j]
      end
    end
  end
  return out
end

##############################################
# Krylov algorithms

"""
    arnoldi(A,b,m) -> V,H

Performs `m` anoldi iterations to obtain the Krylov subspace K_m(A,b).

The output is the n x m unitary basis vectors `V` and the m x m upper 
Heisenberg matrix `H`. They are related by the recurrence formula

```
v_1=b,\\quad Av_j = \\sum_{i=1}^{j+1}h_{ij}v_i\\quad(j = 1,2,\\ldots,m)
```
"""
function arnoldi(A, b, m; cache=nothing)
  V = Matrix{eltype(b)}(length(b), m)
  H = Matrix{eltype(b)}(m, m)
  arnoldi!(V, H, A, b, m; cache=cache)
end
"""
    arnoldi!(V,H,A,b,m) -> V,H

Non-allocating version of `arnoldi`.
"""
function arnoldi!(V::Matrix{T}, H::Matrix{T}, A, b::AbstractVector{T}, 
  m::Integer; cache=nothing) where {T <: Number}
  n = length(b)
  @assert size(V,1) == size(A,1) == size(A,2) == n "Dimension mismatch"
  @assert size(V,2) == size(H,1) == size(H,2) == m "Dimension mismatch"
  if cache == nothing
    cache = similar(b)
  else
    @assert size(cache) == (n,)
  end
  V[:, 1] = normalize(b)
  @inbounds for j = 1:m-1
    A_mul_B!(cache, A, @view(V[:, j]))
    @inbounds for i = 1:j
      alpha = dot(@view(V[:, i]), cache)
      H[i, j] = alpha
      Base.axpy!(-alpha, @view(V[:, i]), cache)
    end
    beta = norm(cache)
    H[j+1, j] = beta
    @inbounds for i = 1:n
      V[i, j+1] = cache[i] / beta
    end
  end
  # Last iteration (j = m)
  A_mul_B!(cache, A, @view(V[:, m-1]))
  @inbounds for i = 1:m
    alpha = dot(@view(V[:, i]), cache)
    H[i, m] = alpha
    Base.axpy!(-alpha, @view(V[:, i]), cache)
  end
  return V, H
end

"""
    phimv(A,b,k,m) -> [phi_0(A)*b phi_1(A)*b ... phi_k(A)*b]

Compute the matrix-phi-vector products using Krylov.

The phi functions are defined as

```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

A size-`m` Krylov subspace is constructed using `arnoldi` and `phimv_dense` is 
called on the Heisenberg matrix.
"""
_phimv(A, b, k, m; caches=nothing) = _phimv!(Matrix{eltype(b)}(length(b), k+1), 
  A, b, k, m; caches=caches)
"""
    phimv!(w,A,b,k,m[;caches]) -> w

Non-allocating version of 'phimv'
"""
function _phimv!(w::Matrix{T}, A, b::AbstractVector{T}, k::Integer, m::Integer; 
  caches=nothing) where {T <: Number}
  @assert size(w, 2) == k + 1 "Dimension mismatch"
  if caches == nothing
    c1 = similar(b)
    c2 = Vector{T}(m)
    C3 = Matrix{T}(m + k, m + k)
    C4 = Matrix{T}(m, k + 1)
    V, H = arnoldi(A, b, m; cache=c1)
  else
    V, H, c1, c2, C3, C4 = caches
    arnoldi!(V, H, A, b, m; cache=c1)
  end
  fill!(c2, zero(T)); c2[1] = one(T) # c1 == e1
  phimv_dense!(C4, H, c2, k; cache=C3)
  scale!(norm(b), A_mul_B!(w, V, C4))
end