using Core: ReturnNode, SSAValue, Argument
using Base: length, hash
using Printf

const TYP_SSA = 1
const TYP_ARG = 2

struct EscapedVal
    type::Int # 1 for SSAValue, 2 for Argument
    val::Int
end

Base.hash(x::EscapedVal) = Base.hash(x.type, Base.hash(x.val))

function update_escapes!(escapes::Dict{EscapedVal, Set{Int}}, escaped::EscapedVal, escape_id::Int)
    if !haskey(escapes, escaped)
        escapes[escaped] = Set()
    end
    @printf("Escaped! %s %d => Stmt %d\n", escaped.type == 1 ? "SSAValue" : "Argument", escaped.val, escape_id)
    push!(escapes[escaped], escape_id)
end

function in_escapes(escapes::Dict{EscapedVal, Set{Int}}, idx::Int)
    for k in keys(escapes)
        # Argument will never be on the left hand side
        # so only need to check SSA value here
        if k.type == TYP_SSA && k.val == idx
            return true
        end
    end
    return false
end

function produce_escape_trace(escapes::Dict{EscapedVal, Set{Int}}, alloc_idx::Int)
    if in_escapes(escapes, alloc_idx)
        while true
            # TODO: DFS here
            # next_escape = [i for i in escapes[alloc_idx]]
            # if length(next_escape) == 0
            #     break
            # end
            nothing
        end
    else
        @printf("allocation stmt %d is not escaped!\n", alloc_idx)
    end
end

function escape_analysis(ir::IRCode, ci::CodeInfo)
    @show ir
    # TODO: at this moment, let's assume the function only has a
    # single giant BaiscBlock

    # a mapping from escaped value to its most recent escape site (idx)
    escapes = Dict{EscapedVal, Set{Int}}()
    allocations = Set{Int}()
    len = length(ir.stmts)
    for idx in len:-1:1
        stmt = ir.stmts[idx]
        inst = stmt[:inst]
        if isa(inst, Expr) && inst.head === :call
            type = stmt[:type]
            if ismutabletype(type)
                push!(allocations, idx)
                @printf("%d is a mutable allocation!\n", idx)
            end
        end
        # if the current stmt is already escaped
        # mark each of its arg as escaped from this
        if in_escapes(escapes, idx)
            if isa(inst, Expr)
                for arg in inst.args[2:end]
                    if isa(arg, Argument)
                        escaped = EscapedVal(TYP_ARG, arg.n)
                        update_escapes!(escapes, escaped, idx)
                    elseif isa(arg, SSAValue)
                        escaped = EscapedVal(TYP_SSA, arg.id)
                        update_escapes!(escapes, escaped, idx)
                    end
                end
            end
        end
        if isa(inst, ReturnNode) && isdefined(inst, :val)
            if isa(inst.val, SSAValue)
                ssa_val = inst.val
                escaped = EscapedVal(TYP_SSA, ssa_val.id)
                update_escapes!(escapes, escaped, idx)
            elseif isa(inst, Argument)
                escaped = EscapedVal(TYP_ARG, inst.n)
                update_escapes!(escapes, escaped, idx)
            end
        end
    end
    return ir
end
