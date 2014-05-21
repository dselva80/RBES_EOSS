function AE = get_AE()
    persistent archEval
    if isempty(archEval)
        archEval = rbsa.eoss.ArchitectureEvaluator.getInstance;
        archEval.init(1);
    end
    AE = archEval;
end
