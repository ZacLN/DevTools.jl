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


scatter{T<:Number}(x::Vector{T},y::Vector{T}) = scatter(x=x,y=y,mode="markers",marker=Dict("size"=>5,"opacity"=>0.75))
scatter{T<:Number}(x::Vector{T},y::Vector{T},z::Vector{T}) = scatter3d(x=x,y=y,z=z,mode="markers",marker=Dict("size"=>5,"opacity"=>0.75))

surface{T<:Number}(z::Array{T,2}) = surface(z=z)
surface{T<:Number}(z::Array{T,3}) = Plot(GenericTrace[surface(z=z[:,:,i],opacity = 0.85) for i = 1:size(z,3)],defaultlayout)
surface{T<:Number,N}(z::Array{T,N}) = Plot(GenericTrace[surface(z=z[:,:,i],opacity = 0.85) for i = 1:prod(size(z,(3:N)...))],defaultlayout)

plot{Tx<:Number,Ty<:Number}(x::Vector{Tx},y::Vector{Ty}) = scatter(x=x,y=y,marker=Dict("size"=>2))
plot{T<:Number}(y::Vector{T}) = plot(collect(1:length(y)),y)
plot{T<:Number}(y::Array{T,2}) = plot(collect(1:size(y,1)),y)
plot{Tx<:Number,Ty<:Number}(x::Vector{Tx},y::Array{Ty,2}) = Plot(GenericTrace[scatter(x=x,y=y[:,i],marker=Dict("size"=>1)) for i = 1:size(y,2)],defaultlayout)


histogram{T<:Number}(x::Vector{T}) = histogram(x=x)
histogram{T<:Number}(X::Array{T,2}) = Plot(GenericTrace[histogram(x=X[:,i],opacity=0.75) for i = 1:size(X,2)],defaultlayout)
