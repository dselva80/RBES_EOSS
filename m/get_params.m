function params = get_params()
    persistent parameters
    if isempty(parameters)
        folder = 'C:\Users\DS925\Documents\GitHub\RBES_EOSS';
        parameters = rbsa.eoss.local.Params(folder,'CRISP-ATTRIBUTES','test','normal','');
    end
    params = parameters;
end
