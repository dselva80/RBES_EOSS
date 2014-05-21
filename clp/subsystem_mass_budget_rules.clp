;(require* modules "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\modules.clp")
;(require* templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\templates.clp")
;(require* more-templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\more_templates.clp")
;(require* functions "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\functions.clp")

;; ***************
;; Subsystem design
;;   4 rules
;; ***************

; power

;(batch ".\\clp\\eps_design_rules.clp")

; avionics or obdh
(defrule MASS-BUDGET::design-avionics-subsystem 
    "Computes comm subsystem mass using rules of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (avionics-mass# nil) (payload-mass# ?m&~nil))
    =>
    (bind ?obdh-mass-coeff 0.0983)
    (bind ?obdh-mass (* ?m ?obdh-mass-coeff))
    (modify ?miss (avionics-mass# ?obdh-mass))
    )

; adcs
;(batch ".\\clp\\adcs_design_rules.clp")

; thermal
(defrule MASS-BUDGET::design-thermal-subsystem 
    "Computes thermal subsystem mass using rules of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (thermal-mass# nil) (payload-mass# ?m&~nil))
    =>
    (bind ?thermal-mass-coeff 0.0607)
    (bind ?thermal-mass (* ?m ?thermal-mass-coeff))
    (modify ?miss (thermal-mass# ?thermal-mass))
    )

; propulsion

;(batch ".\\clp\\propulsion_design_rules.clp")

; structure

(defrule MASS-BUDGET::design-structure-subsystem 
    "Computes structure subsystem mass using rules of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (structure-mass# nil) (payload-mass# ?m&~nil) )
    =>
    
    (bind ?struct-mass (* 0.5462 ?m)); 0.75 
    
    (modify ?miss (structure-mass# ?struct-mass))
    )

; adapter

(defrule MASS-BUDGET::add-launch-adapter 
    "Computes launch adapter mass as 1% of satellite dry mass"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (adapter-mass nil) (satellite-dry-mass ?m&~nil) )
    =>
    
    (bind ?adapter-mass (* 0.01 ?m)); 0.75 
    (modify ?miss (adapter-mass ?adapter-mass))
    )

; **************************************
; SUPPORTING QUERIES AND FUNCTIONS
; **************************************


    