# Get traces
import Base.Profile: StackFrame

type ProfileNode
    line::StackFrame
    count::Int
end

immutable Node{T}
  data::T
  children::Vector{Node{T}}
end

typealias ProfileTree Node{ProfileNode}

Node{T}(x::T) = Node(x, Node{T}[])
Node{T}(x::T, children::Node{T}...) = Node(x, [children...])

Base.push!(parent::Node, child::Node) = push!(parent.children, child)
isleaf(node::Node) = isempty(node.children)

# Profile Trees

ProfileNode(line::StackFrame) = ProfileNode(line, 1)

tree(trace::Vector{StackFrame}) =
  length(trace) ≤ 1 ?
    Node(ProfileNode(trace[1])) :
    Node(ProfileNode(trace[1]), tree(trace[2:end]))

# Conceptually, a trace is a tree with no branches
# We merge trees by (a) increasing the count of the common nodes
# and (b) adding any new nodes as children.
function Base.merge!(node::ProfileTree, trace::Vector{StackFrame})
  @assert !isempty(trace) && node.data.line == trace[1]
  node.data.count += 1
  length(trace) == 1 && return node
  for child in node.children
    if child.data.line == trace[2]
      merge!(child, trace[2:end])
      return node
    end
  end
  push!(node, tree(trace[2:end]))
  return node
end

function tree(traces::Vector{Vector{StackFrame}})
  root = Node(ProfileNode(Profile.UNKNOWN))
  traces = map(trace -> [Profile.UNKNOWN, trace...], traces)
  for trace in traces
    merge!(root, trace)
  end
  return root
end

depth(node::Node) =
  isleaf(node) ? 1 : 1 + maximum(map(depth, node.children))

# Remove redundant lines

childwidths(node::ProfileTree) =
  map(child -> child.data.count/node.data.count, node.children)

function trimroot(tree::ProfileTree)
  validchildren = tree.children[childwidths(tree) .> 0.99]
  length(validchildren) == 1 ? trimroot(validchildren[1]) : tree
end

function sortchildren!(tree::ProfileTree)
  sort!(map!(sortchildren!,tree.children), by = node->node.data.line.line)
  tree
end

# Flatten the tree

function addmerge!(a::Associative, b::Associative)
  for (k, v) in b
    a[k] = haskey(a, k) ? a[k]+b[k] : b[k]
  end
  return a
end

flatlines(tree::ProfileTree; total = tree.data.count) =
  reduce(addmerge!,
         d(tree.data.line=>tree.data.count/total),
         map(t->flatlines(t, total = total), tree.children))



function fetch(c=false)
  data = Profile.fetch()
  isempty(data) && error("You need to do some profiling first.")
  traces = split(data,0,keep=false)
  traces = Vector{StackFrame}[vcat(map(Profile.lookup,x)...) for x in traces]
  !c && (traces = map(x->filter(line->!line.from_c,x),traces))
  traces = map!(reverse,traces)
  traces = filter(t->!isempty(t),traces)

  root = Node(ProfileNode(Profile.UNKNOWN))
  traces = map(trace -> [Profile.UNKNOWN, trace...], traces)
  for trace in traces
    merge!(root, trace)
  end
  root = trimroot(root)
  root = sortchildren!(root)

  while length(root.children)==1 && length(root.children[1].children)==1
      root = root.children[1]
  end
  return root
end
