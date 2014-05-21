;; Preliminary Characterization of SWOT Hydrology
;; Error Budget and Global Capabilities
;; Biancamaria et al, IEEE JOURNAL OF SELECTED TOPICS 
; IN APPLIED EARTH OBSERVATIONS AND REMOTE SENSING, VOL. 3, NO. 1, MARCH 2010

(defrule SWOT-discharge-error-model 
    "Error in discharge comes from model error and river height measurement error"
    ?m <- (REQUIREMENTS::Measurement (Parameter "River height") )
    =>
    ; (bind ?Q (* ?c (exp (- ?Hswot ?H0) ?b) ))
    (bind ?eta 0.2); see paper
    (bind ?b 2); see paper
    (bind ?sigma_D 0.1); 10cm, accuracy of KaRIN
    ;(bind ?D (* 0.27 (exp Q 0.39))); river depth from discharge see paper
    
    (bind ?sigma_Q_over_Q (sqrt (+ (exp ?eta 2) (exp (* b (/ sigma_D D)))))) ; eta is multiplicative model error
    (modify ?m (Total-error ?sigma_Q_over_Q))
    )