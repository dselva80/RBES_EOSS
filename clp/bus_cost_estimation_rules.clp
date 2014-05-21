;(require* templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\templates.clp")
;(require* more-templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\more_templates.clp")
;(require* functions "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\functions.clp")


; ********************
; 2. Spacecraft bus cost
; ***** 4 rules ******
; ********************

(defrule COST-ESTIMATION::compute-bus-cost-CER
    "This rule will compute the bus cost from its dry mass using a cer"
    ?s <- (MANIFEST::SATELLITE (bus-cost nil) (bus nil) (satellite-dry-mass ?m&~nil))
    =>
    (bind ?nrec (/ (* 110.2 ?m) 1000))
    (bind ?rec (/ (* 289.5 (** ?m 0.716)) 1000))
    (bind ?cost (+ ?nrec ?rec))
    (modify ?s (bus-cost ?cost) (bus-non-recurring-cost ?nrec) (bus-recurring-cost ?rec))
    
    )

(defquery COST-ESTIMATION::get-sat-bus-cost
    (declare (variables ?sat))
    (MANIFEST::SATELLITE (bus-cost ?c) (id ?sat))
    )

(deffunction get-sat-bus-cost# (?sat) 
    (bind ?res (run-query* COST-ESTIMATION::get-sat-bus-cost ?sat))
    (if (?res next) then (return (?res getDouble c)) else (return 0.0))
    )

(defrule COST-ESTIMATION::compute-constellation-buses-cost-procurement
    "This rule computes total bus cost of constellations in the procurement mode by 
    adding satellite bus costs. A 95% learning curve is applied for recurring costs only"
    
    ?c <- (MANIFEST::CONSTELLATION (contract-modality procurement) (buses-cost nil) 
        (satellite ?sat&~nil) (num-planes ?np&~nil) (num-sats-per-plane ?ns&~nil) )
    (MANIFEST::SATELLITE (id ?sat) (bus-cost ?cost&~nil) (bus-non-recurring-cost ?nrec&~nil)
         (bus-recurring-cost ?rec&~nil))
    =>
    (bind ?S 0.95); 95% learning curve, means doubling N reduces average cost by 5% (See  SMAD p 809)
    (bind ?N (* ?np ?ns)) 
    (bind ?B (- 1 (/ (log (/ 1 ?S)) (log 2))))
    (bind ?L (** ?N ?B))
    (bind ?r (* ?L ?rec))  
    (bind ?t (+ ?r ?nrec))
    (modify ?c (buses-cost ?t) (buses-non-rec-cost ?nrec) (buses-rec-cost ?r))
    )

(defrule COST-ESTIMATION::compute-constellation-buses-cost-hosted-payloads
    "This rule computes total bus cost of constellations in the hosted payloads mode by 
    setting it to zero"
    
    ?c <- (MANIFEST::CONSTELLATION (contract-modality hosted-payloads) (buses-cost nil))
    
    =>
  
    (modify ?c (buses-cost 0.0) (buses-non-rec-cost 0.0) (buses-rec-cost 0.0))
    )

(defrule COST-ESTIMATION::compute-constellation-buses-cost-commercial
    "This rule computes total bus cost of constellations in the commercial mode by 
    setting it to zero"
    
    ?c <- (MANIFEST::CONSTELLATION (contract-modality commercial) (buses-cost nil))
    
    =>
  
    (modify ?c (buses-cost 0.0) (buses-non-rec-cost 0.0) (buses-rec-cost 0.0))
    )
