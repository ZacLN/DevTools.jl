
type box{D}
    lower::Vector{Float64}
    upper::Vector{Float64}
end

function box{D,BF}(G::NGrid{D,BF},i::Int)
    lower = Array(Float64,D)
    upper = Array(Float64,D)
    for d = 1:D
        p = SparseGrids.position(G.grid[i,d])
        lower[d] = clamp(G.grid[i,d]-1/2^(p[1]-1),0,1)+eps(Float64)
        upper[d] = clamp(G.grid[i,d]+1/2^(p[1]-1),0,1)-eps(Float64)
    end
    return box{D}(lower,upper)
end

function box(X::Vector{Float64})
    D = length(X)
    lower = Array(Float64,D)
    upper = Array(Float64,D)
    for d = 1:D
        p = SparseGrids.position(X[d])
        lower[d] = clamp(X[d]-1/2^(p[1]-1),0,1)+eps(Float64)
        upper[d] = clamp(X[d]+1/2^(p[1]-1),0,1)-eps(Float64)
    end
    return box{D}(lower,upper)
end

function Base.intersect{D}(a::box{D},b::box{D})
    nool = a.lower[1] > b.upper[1] ||
           b.lower[1] > a.upper[1]
    for d = 2:D
        nool = nool ||
           a.lower[d] > b.upper[d] ||
           b.lower[d] > a.upper[d]
       end
    return !nool
end

function getparents(G::NGrid)
    T = Array(Bool,length(G),length(G))
    for i = 1:length(G)
        for j = 1:i
            x = intersect(box(G,i),box(G,j))
            T[i,j] = x
            i!=j && (T[j,i] = x)
        end
    end
    return Vector{Int}[find(T[i,:]) for i = 1:length(G)]
end


function Base.intersect(A::Vector{Int}, B::Vector{Int},n::Int)
    ret = zeros(Int,n)
    na,nb = length(A),length(B)
    cnt = 1
    for ia = 1:na
        a = A[ia]
        ib = ia
        b = B[ib]
        if a<=b
            while a!=b && ib<nb
                ib-=1
                b = B[ib]
            end
            a==B[ib] && (ret[cnt] = b;cnt+=1)

        else
            while a!=b && ib<nb
                ib+=1
                b = B[ib]
            end
            a==B[ib] && (ret[cnt] = b;cnt+=1)
        end
        cnt>n && break
    end
    ret
end


function plot(G::NGrid)
    layout = PlotlyJS.Layout(Dict{Symbol,Any}(:showlegend=>false,:paper_bgcolor => "rgb(45, 45, 45)",:plot_bgcolor => "rgb(45, 45, 45)"),font=Dict("color"=>"rgb(255,255,255)"),xaxis=Dict("showgrid"=>false),yaxis=Dict("showgrid"=>false))

    g = SparseGrids.getstruct(G)
    P = Plot(PlotlyJS.GenericTrace[],layout);
    push!(P.data,scatter(x=[0],y=[0],text = "Grid",mode="text"))
    lev = unique(map(level,g))
    nl = maximum(level(G))+1
    for i = 1:nl
        cl = nl-i-(nl-1)/2
        lev = filter(n->level(n)==i-1,g)
        push!(P.data,scatter(x=[1],y=[cl],text="level $(i-1)",mode="text"))
        push!(P.data,scatter(x=[0.1,0.8],y=[0,cl],marker=Dict("color"=>"yellow")))

        covs = unique([p.l for p in lev],1)
        nc = length(covs)
        for j = 1:nc
            cov = filter(n->n.l==covs[j],lev)
            cc = (nc*2-1)/(nc*2)-(j-1)/nc-0.5
            push!(P.data,scatter(x=[2],y=[cl+cc],text=string(map(Int,covs[j])),mode="text"))
            push!(P.data,scatter(x=[1.2,1.9],y=[cl,cl+cc],marker=Dict("color"=>"yellow")))

            np = length(cov)

            for k = 1:np
                p = cov[k].x
                cp = ((np*2-1)/(np*2)-(k-1)/np-0.5)*(1/nc)
                push!(P.data,scatter(x=[2.2,3],y=[cl+cc,cl+cc+cp],mode="line",line=Dict("width"=>0.2,"color"=>"yellow"),text=string(p)))
            end
        end
    end
    P
end

function plot(G::NGrid,j::Int)
    squares = Dict{String,Any}[]
    centres = PlotlyJS.GenericTrace[]
    index = map(level,G.grid)
    pid = find(all(index.==G.covers[j,:]',2))
    N = length(pid)

    cs = linspace(colorant"red",colorant"green",N)

    for i = 1:N
        push!(centres,scatter(x=[G.grid[pid[i],1]],y=[G.grid[pid[i],2]],text="$i",mode="text"))
        push!(squares,Dict("type"=>"rect","x0"=>clamp(G.grid[pid[i],1]-1/2.025^(G.covers[j,1]-1),0,1),
                                          "x1"=>clamp(G.grid[pid[i],1]+1/2.025^(G.covers[j,1]-1),0,1),
                                          "y0"=>clamp(G.grid[pid[i],2]-1/2.025^(G.covers[j,2]-1),0,1),
                                          "y1"=>clamp(G.grid[pid[i],2]+1/2.025^(G.covers[j,2]-1),0,1),
                                          "fillcolor"=>cs[i],
                                          "opacity" => 0.5,
                                          "line"=>Dict("color"=>cs[i],"width"=>0)))
    end

    Plot(centres,PlotlyJS.Layout(Dict{Symbol,Any}(:title=>"level: "*string(level(G)[pid[1]]-1),:autosize=>false,:width=>400,:height=>400,:showlegend=>false,:paper_bgcolor => "rgb(45, 45, 45)",:plot_bgcolor => "rgb(45, 45, 45)"),font=Dict("color"=>"rgb(255,255,255)"),xaxis=Dict("showgrid"=>false),yaxis=Dict("showgrid"=>false),shapes=squares))
end


function plot(G::NGrid,J::AbstractArray{Int})
    squares = Dict{String,Any}[]
    centres = PlotlyJS.GenericTrace[]
    pid = find(all(G.index.==G.covers[J,:]',2))
    N = length(pid)


    cs = linspace(colorant"red",colorant"green",N)

    for i = 1:N
        push!(centres,scatter(x=[G.grid[pid[i],1]],y=[G.grid[pid[i],2]],text="$i",mode="text"))
        push!(squares,Dict("type"=>"rect","x0"=>clamp(G.grid[pid[i],1]-1/2.025^(G.covers[j,1]-1),0,1),
                                          "x1"=>clamp(G.grid[pid[i],1]+1/2.025^(G.covers[j,1]-1),0,1),
                                          "y0"=>clamp(G.grid[pid[i],2]-1/2.025^(G.covers[j,2]-1),0,1),
                                          "y1"=>clamp(G.grid[pid[i],2]+1/2.025^(G.covers[j,2]-1),0,1),
                                          "fillcolor"=>cs[i],
                                          "opacity" => 0.5,
                                          "line"=>Dict("color"=>cs[i],"width"=>0)))
    end

    Plot(centres,PlotlyJS.Layout(Dict{Symbol,Any}(:autosize=>false,:width=>400,:height=>400,:showlegend=>false,:paper_bgcolor => "rgb(45, 45, 45)",:plot_bgcolor => "rgb(45, 45, 45)"),font=Dict("color"=>"rgb(255,255,255)"),xaxis=Dict("showgrid"=>false),yaxis=Dict("showgrid"=>false),shapes=squares))
end

function plot(a::box{2})
    squares = Dict{String,Any}[]
    centres = PlotlyJS.GenericTrace[]
        push!(centres,scatter(x=[0.0,1.0],y=[0.0,1.0],text=" ",mode="text"))
        push!(squares,Dict("type"=>"rect","x0"=>a.lower[1],
                                          "x1"=>a.upper[1],
                                          "y0"=>a.lower[2],
                                          "y1"=>a.upper[2],
                                          "fillcolor"=>"red",
                                          "opacity" => 0.5,
                                          "line"=>Dict("color"=>"yellow","width"=>0)))

    Plot(centres,PlotlyJS.Layout(Dict{Symbol,Any}(:autosize=>false,:width=>400,:height=>400,:showlegend=>false,:paper_bgcolor => "rgb(45, 45, 45)",:plot_bgcolor => "rgb(45, 45, 45)"),font=Dict("color"=>"rgb(255,255,255)"),xaxis=Dict("showgrid"=>false),yaxis=Dict("showgrid"=>false),shapes=squares))
end

function plot(a::Vector{box{2}})
    squares = Dict{String,Any}[]
    centres = PlotlyJS.GenericTrace[]
    push!(centres,scatter(x=[0.0,1.0],y=[0.0,1.0],text=" ",mode="text"))
    for i = 1:length(a)
        push!(squares,Dict("type"=>"rect","x0"=>a[i].lower[1],
                                          "x1"=>a[i].upper[1],
                                          "y0"=>a[i].lower[2],
                                          "y1"=>a[i].upper[2],
                                          "fillcolor"=>"orange",
                                          "opacity" => 0.4,
                                          "line"=>Dict("color"=>"yellow","width"=>0.5)))
    end

    Plot(centres,PlotlyJS.Layout(Dict{Symbol,Any}(:autosize=>false,:width=>400,:height=>400,:showlegend=>false,:paper_bgcolor => "rgb(45, 45, 45)",:plot_bgcolor => "rgb(45, 45, 45)"),xaxis=Dict("showgrid"=>false),yaxis=Dict("showgrid"=>false),shapes=squares))
end
