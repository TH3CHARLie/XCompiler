using Core: ReturnNode

function escape_analysis(ir::IRCode, ci::CodeInfo)
    # TODO: at this moment, let's assume the function only has a
    # single giant BaiscBlock
    # a mapping from stmt idx to a set of escape values (represented by idx) at this stmt
    escapes = Dict{Int, Set{Int}}()
    for (idx, inst) in Iterators.reverse(enumerate(ir.stmts))
        stmt = inst[:inst]
        if isa(stmt, ReturnNode)
            nothing
        end
    end
    return ir
end
