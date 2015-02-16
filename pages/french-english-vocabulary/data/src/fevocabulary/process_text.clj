(ns fevocabulary.process-text
  (:require [cascalog.logic  [vars :as v] [ops :as c]]
            [cascalog.cascading.io :as io])
  (:use [fevocabulary.download :only [get-book-filename]]
        [fevocabulary.stem :only [tokenize stem-word]]
        [cascalog.api]))

;; methods for flattening the texts data structure

(defn generate-book-tuple [lang author dates book]
  {:lang lang
   :author author
   :born (first dates)
   :died (second dates)
   :title (:title book)
   :filename (get-book-filename lang book)})

(defn flatten-authors [lang authors]
    (mapcat #(map (partial generate-book-tuple lang (first %) (:dates (second %)))
               (:books (second %))) authors))

(defn flatten-data [in-file]
  (mapcat #(flatten-authors
          (first %)
          (first (second %)))
       (read-string (slurp in-file))))


(defn into-tuple [in-file]
  (into '[] (map #(into '[] (vals %)) (flatten-data  in-file))))

;; tuples of filename and lines

(defmapcatfn tokenize-textline [line lang]
  (tokenize line lang))

(deffilterfn remove-blank [string]
  ((complement clojure.string/blank?) string))

(defmapfn stem-token [token lang] (stem-word token lang))

(defn make-tokens-and-stems [sink folder in-file]
  (with-job-conf {"mapred.child.java.opts" "-Xmx1g -XX:-UseGCOverheadLimit"}
    (?<- sink
         [!lang !author !title !token !stem]
         ((hfs-seqfile folder) !line !filename)
         ((into-tuple in-file) !lang !author !born !died !title !filename )
         (tokenize-textline !line !lang :> !token )
         (stem-token !token !lang :> !stem )
         (remove-blank !stem))))

(defn make-processed-text-file [sink-folder source-folder in-file]
  (make-tokens-and-stems (hfs-seqfile sink-folder) source-folder in-file))

