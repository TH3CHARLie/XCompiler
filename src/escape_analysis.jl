using Core: ReturnNode, SSAValue

function escape_analysis(ir::IRCode, ci::CodeInfo)
    # TODO: at this moment, let's assume the function only has a
    # single giant BaiscBlock
    # a mapping from stmt idx to a set of escape values (represented by idx) at this stmt
    escapes = Dict{Int, Set{Int}}()
    for (idx, inst) in Iterators.reverse(enumerate(ir.stmts))
        stmt = inst[:inst]
        if idx in escapes
            if isa(stmt, Expr)
                union!(escapes[idx])
            end
        end
        if isa(stmt, ReturnNode) && isdefined(stmt, :val)
            escapes[idx] = Set()
            if isa(stmt.val, SSAValue)
                ssa_val = stmt.val
                union!(escapes[ssa_val.val], [idx])
        end
    end
    return ir
end
