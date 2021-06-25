using Core: ReturnNode, SSAValue, Argument
using Base: length, hash

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
    union!(escapes[escaped], escape_id)
end

function escape_analysis(ir::IRCode, ci::CodeInfo)
    @show ir
    # TODO: at this moment, let's assume the function only has a
    # single giant BaiscBlock

    # a mapping from escaped value to its most recent escape site (idx)
    escapes = Dict{EscapedVal, Set{Int}}()
    len = length(ir.stmts)
    for idx in len:-1:1
        stmt = ir.stmts[idx]
        inst = stmt[:inst]
        # if the current stmt is already escaped
        # mark each of its arg as escaped from this
        if idx in keys(escapes)
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
            end
        end
    end
    return ir
end
