(ns fevocabulary.unique
  (:require [clojure.data.json :as json]
            [cascalog.logic.ops :as c]
            [cascalog.logic.vars :as v])
  (:use [fevocabulary.process-text :only [make-processed-text-file into-tuple]]
        [cascalog.api]))

(defn join-fields [f & r]
  (into [] (apply concat f r)))

(defn word-frequency [source fields]
  (let [out-fields (conj fields "!freq")]
    (<- out-fields
        ((select-fields source fields) :>> fields)
        (c/count :> !freq))))

(defmapfn word-diff [target-count all-count]
  (- target-count (- all-count target-count)))

(defn find-highest-freqs [source fields]
  (let [stem-fields ["!stem" "!lang"]
        target-stem-fields (join-fields fields stem-fields)
        all-word-query (partial word-frequency source stem-fields)
        target-word-query (partial word-frequency source target-stem-fields)
        out-fields (conj target-stem-fields "!freq")]
    (<- out-fields
        ((all-word-query) :>> (conj stem-fields "!afreq"))
        ((target-word-query) :>> (conj target-stem-fields "!bfreq"))
        (word-diff :< !bfreq !afreq :> !freq ))))

(defbufferfn first-n-tuples [tuples] (take 10 tuples))

(defn sorted-word-freq [source fields limit]
  (let [freq-fields (join-fields fields ["!stem" "!lang" "!freq"])
        out-fields (join-fields fields ["!s" "!f" "!lang"])]
    (with-job-conf {"mapred.child.java.opts" "-Xmx1g"}
      (??<- out-fields
            ((find-highest-freqs source fields) :>> freq-fields)
            (:sort !freq )
            (:reverse true )
            ((c/limit limit) :< !stem !freq :> !s !f)))))

(defn find-words-for-book [lang author book word-list]
  (map (fn [[a b s f l]] {:word s :score f})
       (filter (fn [[a b s f l]] (and (= l lang) (= author a) (= b book))) word-list)))

(defn process-books [lang author books book-word-list]
    (map (fn [book]
            {:title (:title book)
             :top-words (find-words-for-book lang author (:title book) book-word-list)}) books))

(defn find-words-for-author [lang author word-list]
  (map (fn [[a s f l]] {:word s :score f})
       (filter (fn [[a s f l]] (and (= l lang) (= author a))) word-list)))

(defn process-authors [lang author-word-list book-word-list authors]
  (into {}
        (mapcat
          (fn [[author props]]
            {author {:top-words (find-words-for-author lang author author-word-list )
                     :books (process-books lang author (:books props) book-word-list)}}) authors)))

(defn top-words [text-source in-file top-limit]
  (let [author-top-words (sorted-word-freq text-source ["!author"] top-limit)
        book-top-words (sorted-word-freq text-source ["!author" "!title"] top-limit)
        data-source (read-string (slurp in-file))]
    {:english  (first (map (partial process-authors :english author-top-words book-top-words) (:english data-source)))
     :french (first (map (partial process-authors :french author-top-words book-top-words) (:french data-source)))}))

(defn write-unique-json [processed-source in-file out-file top-limit]
   (spit out-file
        (json/write-str (top-words processed-source in-file top-limit))))

