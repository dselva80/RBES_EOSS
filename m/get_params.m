function params = get_params
    persistent parameters

    if isempty(parameters) 
        parameters = rbsa.eoss.local.Params(pwd,'CRISP-ATTRIBUTES','test','normal','');
    end
    params = parameters;
end
