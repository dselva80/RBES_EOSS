;(require* modules "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\modules.clp")
;(require* templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\templates.clp")
;(require* more-templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\more_templates.clp")
;(require* functions "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\functions.clp")

; 0 RULES
;; ******************************************
;;              PRELIM MASS BUDGET
;; 7 (prelim) + 2 (clean)  + 3 (update) rules
;; ******************************************

(defrule PRELIM-MASS-BUDGET::estimate-bus-mass-from-payload-mass
    "This rule computes the dry mass of the bus as a linear function of the payload mass.
     Use a factor 4.0 from TDRS 7, in new SMAD page 952. Note that this rule and 
    import-bus-mass-from-DB are never applicable at the same time."
    
    ?f <- (MANIFEST::Mission (bus nil) (bus-mass nil) (payload-mass# ?m&~nil))
    =>
    (bind ?bm (* 4.0 ?m))
    (modify ?f  (bus-mass ?bm))    
    )


(defrule PRELIM-MASS-BUDGET::estimate-satellite-dry-mass
    "This rule computes the dry mass as the sum of bus and payload mass
    (including antennae mass)."
    
    ?f <- (MANIFEST::Mission (satellite-dry-mass nil) (bus-mass ?bm&~nil) (payload-mass# ?m&~nil))
    =>
    (modify ?f  (satellite-dry-mass (+ ?m ?bm)))    
    )

(defrule MANIFEST::calculate-satellite-payload-dimensions
    "This rule calculates the total payload dimensions of a satellite"
    ?f <- (MANIFEST::Mission (instruments $?payls) (payload-dimensions $?pdims))
    (test (eq (length$ ?pdims) 0))
    =>
    (bind ?dims (create$ 0.0 0.0 0.0))
    (foreach ?payl ?payls 
        (bind ?dims (.+$ ?dims (get-payload-dimensions# ?payl))))
    (modify ?f (payload-dimensions ?dims))
)

(deffunction get-payload-dimensions# (?payl)
    (bind ?res (run-query* DATABASE::get-payload-dimensions ?payl))
    (if (?res next) then (return (create$ (?res get x) (?res get y) (?res get z)) else (return (create$ 0.0 0.0 0.0)))
    )
	)
	
(defquery DATABASE::get-payload-dimensions
    (declare (variables ?name))
    (DATABASE::Instrument (Name ?name) (dimension-x# ?x) (dimension-y# ?y) (dimension-z# ?z))
    )
	

(defrule PRELIM-MASS-BUDGET::estimate-dimensions
    "Estimate dimensions assuming a perfect cube of size given 
    by average density, see SMAD page 337"
    ?sat <- (MANIFEST::Mission (satellite-dry-mass ?m&~nil) 
        (satellite-dimensions $?dim&:(eq (length$ $?dim) 0)))
    
    =>
   
    (bind ?r (* 0.25 (** ?m (/ 1 3))))
    (modify ?sat (satellite-dimensions (create$ ?r ?r ?r)))
    )

(defrule PRELIM-MASS-BUDGET::estimate-moments-of-inertia
    "Guess moments of inertia assuming a perfect box"
    ?sat <- (MANIFEST::Mission (satellite-dry-mass ?m&~nil) 
        (satellite-dimensions $?dim&:(> (length$ $?dim) 0)))
    
    =>
   
    (modify ?sat (moments-of-inertia (box-moment-of-inertia ?m $?dim)))
    )


;; ******************************************
; MASS BUDGET
;; ******************************************

;(batch (str-cat ?*app_path* ".\\clp\\subsystem_mass_budget_rules.clp"))
;(batch (str-cat ?*app_path* ".\\clp\\deltaV_budget_rules.clp"))

;; ******************************************
;; UPDATE MASS BUDGET
;; ******************************************


(defrule CLEAN2::clean
    (declare (no-loop TRUE))
    ?sat <- (MANIFEST::Mission)
    =>
    (modify ?sat (satellite-dry-mass nil) (satellite-wet-mass nil) 
        (satellite-dimensions (create$ )) (moments-of-inertia (create$ )))
    
    )

(defrule CLEAN1::clean
    (declare (no-loop TRUE))
    ?sat <- (MANIFEST::Mission)
    =>
    (modify ?sat (delta-V-ADCS nil) (satellite-BOL-power# nil)
        (delta-V-injection nil) (delta-V-drag nil) (delta-V-deorbit nil) (delta-V nil)
        (propellant-mass-injection nil) (propellant-mass-ADCS nil) (drag-coefficient nil)
        (ADCS-mass# nil) (EPS-mass# nil) (structure-mass# nil) (thermal-mass# nil) (avionics-mass# nil)
        )
    
    )

(defrule UPDATE-MASS-BUDGET::update-dry-mass
    "Computes the sum of subsystem masses"
    ?miss <- (MANIFEST::Mission (propulsion-mass# ?prop-mass&~nil) 
        (structure-mass# ?struct-mass&~nil) (adapter-mass ?adap-mass&~nil)
        (avionics-mass# ?av-mass&~nil) (ADCS-mass# ?adcs-mass&~nil) 
        (EPS-mass# ?eps-mass&~nil) (thermal-mass# ?thermal-mass&~nil)
         (payload-mass# ?payload&~nil)
 (propellant-mass-ADCS ?mp1&~nil) (propellant-mass-injection ?mp2&~nil))
    =>
    
    (bind ?sat-mass (+ ?prop-mass ?struct-mass ?eps-mass ?adcs-mass ?av-mass ?payload ?thermal-mass)); dry mass
    (modify ?miss (satellite-dry-mass ?sat-mass ?mp) 
        (satellite-wet-mass (+ ?sat-mass ?mp1 ?mp2))
        (satellite-launch-mass (+ ?sat-mass ?mp1 ?mp2 ?adap-mass))); wet mass
    )

(defrule UPDATE-MASS-BUDGET::update-dimensions
    "Estimate dimensions assuming a perfect cube of size given 
    by average density"
    ?sat <- (MANIFEST::Mission (satellite-dry-mass ?m&~nil))
    
    =>
   
    (bind ?r (* 0.25 (** ?m (/ 1 3))))
    (modify ?sat (satellite-dimensions (create$ ?r ?r ?r)))
    )



(defrule UPDATE-MASS-BUDGET::update-moments-of-inertia
    "Guess moments of inertia assuming a perfect box"
    ?sat <- (MANIFEST::Mission (satellite-dry-mass ?m&~nil) 
        (solar-array-area ?Aa&~nil) (solar-array-mass ?msa&~nil)  
        (moments-of-inertia $?mom&:(eq (length$ $?mom) 0))
        (satellite-dimensions $?dim&:(> (length$ $?dim) 0)))
    
    =>
    
    (bind ?La (+ (* 1.5 (nth$ 1 $?dim)) (* 0.5 (sqrt (* 0.5 ?Aa)))))
    (bind ?Ix (* 0.01 (** ?m (/ 5 3))))
    (bind ?Iz (+ ?Ix (* ?msa (** ?La 2))))
    (bind ?moments (create$ ?Ix ?Ix ?Iz))
    (modify ?sat (moments-of-inertia ?moments))
    )

; *********** Supporting queries and functions


(defquery MASS-BUDGET::get-mass-budget
    (declare (variables ?name))
    ?miss <- (MANIFEST::Mission (Name ?name) (adapter-mass ?adap&~nil) (propulsion-mass# ?prop-mass&~nil) (structure-mass# ?struct-mass&~nil)
        (avionics-mass# ?av-mass&~nil) (ADCS-mass# ?adcs-mass&~nil) (EPS-mass# ?eps-mass&~nil) (propellant-mass-injection ?mp1) (propellant-mass-ADCS ?mp2)
        (thermal-mass# ?thermal-mass&~nil) (payload-mass# ?payload&~nil) (satellite-dry-mass ?dry) (satellite-wet-mass ?wet) (satellite-launch-mass ?launch)
        )
    )

