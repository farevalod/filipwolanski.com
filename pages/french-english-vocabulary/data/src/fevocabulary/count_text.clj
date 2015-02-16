(ns fevocabulary.count-text
  (:require [clojure.data.json :as json]
            [cascalog.logic.ops :as c])
  (:use [cascalog.api]))


(defn stem-count [processed-text-source fields]
  (let [source-stems (conj fields "!stem")
        out-fields (conj fields "!count")]
    (<- out-fields
      ((select-fields processed-text-source source-stems) :>> source-stems)
      (c/count :> !count))))

(defn sampled-stems [processed-text-source fields limit-num]
  (let [source-stems (conj fields "!stem")
        out-fields (conj fields "!s2")
        sampled (conj (vec (repeat (count fields) "_")) "!s2")]
    (<- out-fields
      ((select-fields processed-text-source source-stems) :>> source-stems)
      ((c/fixed-sample-agg limit-num) :<< source-stems :>> sampled))))

(defn fewest-stems [processed-text-source fields]
  (let [min-field (conj (vec (repeat (count fields) "_")) "!min-words")]
    (->
      (with-job-conf {"mapred.child.java.opts" "-Xmx1g"}
        (??<- [!min-words]
              ((c/first-n
                 (stem-count processed-text-source fields)
                 1 :sort ["!count"]) :>> min-field)))
      (first) (first))))

(defn count-stems [processed-text-source fields limited max-stems]
  (let [source-stems (conj fields "!stem")
        out-fields (conj fields "!count" "!distinct")
        get-stem-fn (if limited
                      (partial sampled-stems processed-text-source fields max-stems)
                      (partial select-fields processed-text-source source-stems))]
    (<- out-fields
         ((get-stem-fn) :>> source-stems)
         (c/count :> !count)
         (c/distinct-count !stem :> !distinct))))

(defn count-with-fields [processed-text-source fields max-stems]
  (let [out-fields (conj fields "!count" "!distinct" "!limited-count" "!limited-distinct")]
   (<- out-fields
         ((count-stems processed-text-source fields false max-stems)
          :>> (conj fields "!count" "!distinct"))
         ((count-stems processed-text-source fields true max-stems)
          :>> (conj fields "!limited-count" "!limited-distinct")))))


(defn gen-data [processed-text-source in-file-source fields]
  (let [max-stems (fewest-stems processed-text-source fields)
        count-fields ["!count" "!distinct" "!limited-count" "!limited-distinct"]
        source-fields (into [] (concat fields ["!born" "!died" "!lang"]))
        all-fields (into [] (concat source-fields count-fields))
        key-fields (map (fn [^String x] (keyword ( .substring x 1))) all-fields)]
    (map #(zipmap key-fields %)
         (distinct
           (with-job-conf  {"mapred.child.java.opts" "-Xmx1g"}
             (??<- all-fields
                   ((count-with-fields processed-text-source fields max-stems)
                    :>> (into [] (concat fields count-fields)))
                   ((select-fields in-file-source source-fields) :>> source-fields)))))))

; for testing
; (def in-file-fields ["!lang" "!author" "!born" "!died" "!title" "!filename"])
; (def in-file-source (name-vars (fevocabulary.process-text/into-tuple "test.edn") in-file-fields))
; (def processed-text-fields ["!lang" "!author" "!title" "!word" "!stem"])
; (def processed-text-source
;   (name-vars (hfs-seqfile "processed-text") processed-text-fields))

; 6 - 7 sec
; (time (gen-data processed-text-source in-file-source ["!author"]))

; 1 - 2 sec
; (time (fewest-stems processed-text-source ["!author"]))

; 1 - 2 sec
; (time (??<- [!a !b !c] ((count-stems processed-text-source ["!author"] false) !a !b !c)))

; 2 - 3 sec
; (time (??<- [!a !b !c] ((count-stems processed-text-source ["!author"] true) !a !b !c)))

; 4 sec
; (time (??<- [!a !b !c !d !e] ((count-with-fields processed-text-source ["!author"] 200) !a !b !c !d !e )))


(defn write-count-json [source in-file-source output-file]
  (spit output-file
        (json/write-str
          {:books
           (gen-data source in-file-source ["!author" "!title"])
           :authors
           (gen-data source in-file-source ["!author"])})))
