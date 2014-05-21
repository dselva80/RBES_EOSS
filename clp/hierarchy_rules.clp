(deftemplate value (slot of) (multislot is))
(deftemplate system (slot id) (slot parent))
(deftemplate att-1 (slot of) (slot is))

(defrule MANIFEST::assert-children)