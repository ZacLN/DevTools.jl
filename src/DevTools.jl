__precompile__()

module DevTools

using Blink, Media, Lazy, Requires

export BlinkDisplay, pin, top, docs, profiler

include("display/BlinkDisplay.jl")
using .BlinkDisplay
include("profile/profile.jl")
include("codemirror.jl")
include("collab.jl")

profiler(c=false) = render(BlinkDisplay._display,ProfileView.fetch(c))

export plot,scatter,surface
export codewarn,codellvm,codenative
end # module
