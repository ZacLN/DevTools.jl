# function Base.display(P::PlotlyJS.Plot)
#     display(HTML(PlotlyJS.html_body(P)))
#     return
# end
#
# function display(t::GenericTrace)
#     display(HTML(PlotlyJS.html_body(Plot(t,defaultlayout))))
#     return
# end
#
# function display(v::Vector{GenericTrace})
#     display(HTML(PlotlyJS.html_body(Plot(v,defaultlayout))))
#     return
# end
import PlotlyJS:Plot,GenericTrace,scatter,surface,scatter3d


const defaultlayout = PlotlyJS.Layout(Dict{Symbol,Any}(:paper_bgcolor => "rgb(45, 45, 45)",
                                     :plot_bgcolor => "rgb(45, 45, 45)"),font=Dict("color"=>"rgb(255,255,255)"))


Base.display(s::HTML) = render(s)
function Base.display(P::Plot)
    display(HTML(PlotlyJS.html_body(P)))
    return
end
function Base.display(t::GenericTrace)
    display(HTML(PlotlyJS.html_body(Plot(t,defaultlayout))))
    return
end
function Base.display(v::Vector{GenericTrace})
    display(HTML(PlotlyJS.html_body(Plot(v,defaultlayout))))
    return
end

scatter{T<:Number}(x::Vector{T},y::Vector{T},z::Vector{T}) = scatter3d(x=x,y=y,z=z,mode="markers",marker=Dict("size"=>5,"opacity"=>0.75))

scatter{T<:Number}(x::Vector{T},y::Vector{T}) = scatter(x=x,y=y,mode="markers",marker=Dict("size"=>5,"opacity"=>0.75))

surface{T<:Number}(z::Array{T,2}) = surface(z=z)

function surface{T<:Number}(z::Array{T,3})
    p = Plot(PlotlyJS.GenericTrace[PlotlyJS.surface(z=z[:,:,i],opacity = 0.85) for i = 1:size(z,3)])
end

function surface{T<:Number,N}(z::Array{T,N})
    p = Plot(PlotlyJS.GenericTrace[PlotlyJS.surface(z=z[:,:,i],opacity = 0.85) for i = 1:prod(size(z,(3:N)...))])
    show(p)
    return p
end

plot{Tx<:Number,Ty<:Number}(x::Vector{Tx},y::Vector{Ty}) = scatter(x=x,y=y,marker=Dict("size"=>2))

plot{T<:Number}(y::Vector{T}) = plot(collect(1:length(y)),y)
plot{T<:Number}(y::Array{T,2}) = plot(collect(1:size(y,1)),y)

function plot{Tx<:Number,Ty<:Number}(x::Vector{Tx},y::Array{Ty,2})
    @assert length(x) == size(y,1)
    T = PlotlyJS.GenericTrace[PlotlyJS.scatter(x=x,y=y[:,i]) for i = 1:size(y,2)]
    [T[i]["opacity"]=1 for i = 1:size(y,2)]
    [T[i]["marker.size"]=2 for i = 1:size(y,2)]
    T
end

export plot,scatter,surface


macro codewarn(ex0)
    Base.gen_call_with_extracted_types(Expr(:quote,codewarn), ex0)
end
function codewarn(f::Function,argstype)
    iob = IOBuffer()
    code_warntype(iob,f,argstype)
    s=takebuf_string(iob)
    close(iob)
    jl2html(s)
end

macro codellvm(ex0)
    Base.gen_call_with_extracted_types(Expr(:quote,codellvm), ex0)
end
function codellvm(f::Function,argstype)
    iob = IOBuffer()
    code_llvm(iob,f,argstype)
    s=takebuf_string(iob)
    close(iob)
    jl2html(s)
end

macro codenative(ex0)
    Base.gen_call_with_extracted_types(Expr(:quote,codenative), ex0)
end
function codenative(f::Function,argstype)
    iob = IOBuffer()
    code_native(iob,f,argstype)
    s=takebuf_string(iob)
    close(iob)
    jl2html(s)
end

function stripflc(s0::AbstractString)
    s = deepcopy(s0)
    lcnt=length(matchall(r"\n",s))
    loc0 = 1
    cnt=0
    while cnt<lcnt*10 && loc0<length(s)
        cnt+=1
        loc1 = search(s,'#',loc0)
        if loc1≠length(s) && s[loc1+1] == ' '
            loc2 = search(s,':',loc1)
            s = replace(s,s[loc1+1:loc2],"")
            loc0 = 1
        else
            loc0=loc1+1
        end
    end
    s
end

function jl2html(s::AbstractString)
    s1 = stripflc(s)
    s1 = replace(s1,"\n","""<br>""")
    s1 = replace(s1,"=", """<font color = yellow>=</font>""")
    s1 = replace(s1,"::","""<font color = yellow>::</font>""")
    s1 = replace(s1,"Any","""<font color="#ff0000">Any</font>""")
    s1 = replace(s1,"Base.box","""<font color="#ff0000">Base.box</font>""")
    s1 = replace(s1,"""[1m[31m""","")
    s1 = replace(s1,"""[31m""","")
    s1 = replace(s1,"""[0m""","")
    HTML(s1)
end

export codewarn,codellvm,codenative


function html(ex::Expr)
    if ex.head == :for
        title = "for $(string(ex.args[1]))"
        sublist = prod(map(s->"<li>"*html(s)*"</li>",ex.args[2].args))
        return """
        $title
        <ul>
        $sublist
        </ul>
        end
        """
    elseif ex.head == :function
        title = html(ex.args[1])
        sublist = prod(map(s->"<li>"*html(s)*"</li>",ex.args[2].args))
        return """
        $title
        <ul>
        $sublist
        </ul>
        end
        """
    elseif ex.head == :macrocall
        title = html(ex.args[1])
        sublist = prod(map(s->"<li>"*html(s)*"</li>",ex.args[2:end]))
        return """
        $title
        <ul>
        $sublist
        </ul>
        @
        """
    elseif ex.head == :(=)
        return """
        <li>
        <div style="color:yellow">$(html(ex.args[1]))</div>  =  $(html(ex.args[2]))
        </li>
        """
    elseif ex.head == :ref
        return html(ex.args[1])*"<sub>"*prod(map(s->html(s)*",",ex.args[2:end]))[1:end-1]*"</sub>"
    elseif ex.head == :block
        return prod(map(html,ex.args))
    elseif ex.head == :line
        return ""
    elseif ex.head == :.
        return html(ex.args[1])*"."*html(ex.args[2].value)
    elseif ex.head == :call && in(ex.args[1],[:+,:*,:^,:/,:-]) && length(ex.args)==3
        return """($(html(ex.args[2]))) $(html(ex.args[1])) ($(html(ex.args[3])))"""
    elseif ex.head == :call && ex.args[1]==:- && length(ex.args)==2
        return """-($(html(ex.args[2])))"""
    elseif ex.head == :call
        return """ $(html(ex.args[1]))($(prod(map(s->html(s)*",",ex.args[2:end]))[1:end-1])) """
    else
        return """<li>
        $(string(ex))
        </li>"""
    end
end
html(x) = string(x)

Base.HTML(ex::Expr)=HTML(replace(html(ex),"<li></li>",""))

ex = :(@inbounds sdf A.X[i] = d)
HTML(html(ex))
