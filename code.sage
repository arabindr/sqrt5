F.<a> = NumberField(x^2-x-1)

def quadratic_twists(E, B):
    """
    Return iterator over all pairs `(d, E^d)`, where the `E^d` run
    over all quadratic twists of `E` with norm conductor at most `B`.

    INPUT:

    - E -- an elliptic curve over F=Q(sqrt(5))
    - B -- positive integer

    AUTHOR: William Stein
    """
    N = E.conductor()
    K = E.base_field()
    P1 = prime_divisors(N)
    v = [p for p, e in N.factor() if e==1]
    if len(v) == 0:
        C = 1
    else:
        C = prod(v).norm()
    B2 = int(sqrt(B/C))
    P2 = [(p, p.norm()) for p in sum([K.primes_above(p) for p in primes(B2+1)],[]) if p.norm() <= B2] 
    for s in [-1,1]:
        for eps in [0,1]:
            for Z in subsets(P1):
                d1 = prod(Z).gens_reduced()[0] if Z else K(1)
                for W in subsets(P2):
                    if prod(n for _, n in W) <= B2:
                        d2 = prod([p for p,_ in W]).gens_reduced()[0] if W else K(1)
                        d = d2*d1*s*K.gen()^eps
                        if d != 1:
                            Ed = E.quadratic_twist(d).global_minimal_model()
                            if Ed.conductor().norm() <= B:
                                yield Ed, d


def aplist(E, B):
    from psage.ellcurve.lseries.aplist_sqrt5 import aplist
    return aplist(E,B)

def LSeries(E):
    from psage.lseries.eulerprod import LSeries
    return LSeries(E)

def primes_of_bounded_norm(B):
    from psage.number_fields.sqrt5 import primes_of_bounded_norm
    return primes_of_bounded_norm(B)

def p_isogenous_curves(E, p):
    E = E.change_ring(F)
    
    if p in [2,3,5,7,13]:
        return [S.codomain() for S in E.isogenies_prime_degree(p)]
        
    E = E.short_weierstrass_model()
    dp = E.division_polynomial(p).change_ring(F)
    v = []
    for f in [f for f in divisors(dp) if f.degree() == (p-1)/2]:
        try:
            G = E.isogeny(f).codomain()
            # some G need not actually be correct, because the checking
            # of validity of isogenies is broken.
            if E.is_isogenous(G):
                v.append(G)
        except ValueError:
            pass
    v = [canonical_model(G.change_ring(F).global_minimal_model()) for G in v]
    return v

def _plstar1(E, q):
    R.<x> = F[] 
    t12 = 2048*x^12 -6144*x^10 + 6912*x^8 -3584*x^6 + 840*x^4 -72*x^2 + 1
    t12p = 2048*x^6 -6144*x^5 + 6912*x^4 -3584*x^3 + 840*x^2 -72*x + 1
    t24 = 2*(t12)^2 - 1 
    #this is only for primes that have no ramification and have good reduction
    if len(F.primes_above(q)) == 1:
        w1 = 1 - 2*(q^12)*t12(x/(2*q)) + q^24
        t1 = E.change_ring(F.ideal(q).residue_field()).trace_of_frobenius()
        w = w1(t1)
        m = []
        for zee in factor(ZZ(w)):
            m.append(zee[0])
        return m    
    else:
        v = F.primes_above(q)
        t1 = E.change_ring(v[0].residue_field()).trace_of_frobenius()
        t2 = E.change_ring(v[1].residue_field()).trace_of_frobenius()
        w1 = t12p(x^2/(4*q))
        w = 1 - 4*(q^12)*w1(t1)*w1(t2) - 2*(q^24)*(1- 2*(w1(t1)^2 + w1(t2)^2))- 4*(q^36)*w1(t1)*w1(t2) + q^48
        m = []
        for zee in factor(ZZ(w)):
            m.append(zee[0])
        return m

def _plstar12(E, q):
    #same caveat, only for unramified and good reduction
    if len(F.primes_above(q)) == 1:
       t1 = E.change_ring(F.prime_above(q).residue_field()).trace_of_frobenius()
       m = [q]
       try:
           for v in factor(t1):
               m.append(v[0])
           for v in factor(t1^2 - q^2):
               m.append(v[0])
           for v in factor(t1^2 - 4*q^2):
               m.append(v[0])
           for v in factor(t1^2 - 3*q^2):
               m.append(v[0])
           s1 = set(m)
           m = list(s1)
           return m
       except ArithmeticError:
           return 0
    else:
       t1 = E.change_ring(F.primes_above(q)[0].residue_field()).trace_of_frobenius()
       t2 = E.change_ring(F.primes_above(q)[1].residue_field()).trace_of_frobenius()
       m = [q]
       try:
           for v in factor((t1^2 + t2^2 - q^2)^2 - 3*(t1^2)*(t2^2)):
               m.append(v[0])
           for v in factor(t1^2 - t2^2):
               m.append(v[0])
           for v in factor(t1^2 +t2^2 - 4*q^2):
               m.append(v[0])
           for v in factor((t1^2 + t2^2 - 3*q^2)^2 - (t1*t2)^2):
               m.append(v[0])
           s1 = set(m)
           m = list(s1)
           return m
       except ArithmeticError:
           return 0     


def billerey_primes(E):
    ans = set([])
    Bad = [v[0] for v in E.conductor().norm().factor()]
    Pr = prime_range(1000)
    num = 0
    i = 0
    X = [set([3])]
    while num < 3:
        if not Pr[i] in Bad and Pr[i] != 5:
            try:
                X.append(set(_plstar1(E, Pr[i]) + _plstar12(E, Pr[i])))
                num += 1
            except TypeError:
                pass
        i += 1
    ans = (X[1].intersection(X[2])).intersection(X[3])                
    ans = ans.union(set(Bad)).union(set([2,3,5]))
    return list(sorted(ans))

def potential_isogeny_degrees(E, B=None, C=100):
    Z = billerey_primes(E) if B is None else prime_range(B)

    # 1. compute the charpolys of frobenius at good primes less than C
    v = aplist(E, C)
    R = ZZ['X']; X = R.gen()
    w = [X^2 - v[i]*X + p.norm() for i, p in enumerate(primes_of_bounded_norm(C))
            if E.has_good_reduction(p.sage_ideal())]

    # 2. for each prime ell up to B, check to see if all
    # the polys in w are reducible modulo ell.
    r = []
    for ell in Z:
        k = GF(ell)
        if all(not f.change_ring(k).is_irreducible() for f in w):
            r.append(ell)
    return r

def isogeny_class(E):            # Returns isogeny class and adjacency matrix
    E = E.change_ring(F)
    curve_list = [E]
    i = 0
    Adj = matrix(50)
    ins = 1
    P = potential_isogeny_degrees(E)
    while i < len(curve_list):
        for p in P:
            for Ep in p_isogenous_curves(curve_list[i],p):
                bool = True
                for G in curve_list:
                    if Ep.is_isomorphic(G):
                        bool = False
                        Adj[i,curve_list.index(G)]=p         #if a curve in the isogeny class computation is isom
                        Adj[curve_list.index(G),i]=p         #to a curve already in the list, we want a line
                if bool:
                    curve_list.append(Ep)
                    Adj[i,ins]=p
                    Adj[ins,i]=p
                    ins += 1
        i+=1  
    Adj = Adj.submatrix(nrows=len(curve_list),ncols=len(curve_list))
    return curve_list, Adj 



def canonical_model(E):
    E = E.change_ring(F).global_minimal_model()  # needed?
    from psage.ellcurve.minmodel.sqrt5 import canonical_model
    return canonical_model(E)


