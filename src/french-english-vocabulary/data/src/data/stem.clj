(ns data.stem
  (:use opennlp.nlp
        opennlp.tools.lazy)
  (:import java.io.File
           com.atlascopco.hunspell.Hunspell)
  (:gen-class))


;; tokenization and counting

(def tokenizers
  {:english (make-tokenizer "models/en-token.bin")
   :french (make-tokenizer "models/fr-token.bin")})

(def stemmers
  {:english (Hunspell. "models/en.dic" "models/en.aff")
   :french (Hunspell. "models/fr.dic" "models/fr.aff")})


(defn remove-punctuation [s]
    (clojure.string/replace s #"[^a-z'`’\p{L}]]" ""))

(defn split-hyphenation [s]
    (clojure.string/split s #"-"))

(defn tokenize [text lang]
          (map remove-punctuation ((lang tokenizers) text)))

(defn stem [s lang]
  (map clojure.string/lower-case
       (map #(let [stem (if (empty? %) "" (.stem (lang stemmers) %))]
               (if (empty? stem) "" (apply min-key count stem))) s)))


; (defn tokenize [text lang]
;   (remove empty?
;           (map remove-punctuation
;                (mapcat split-hyphenation ((lang tokenizers) text)))))

; (defn stem-and-unique [s lang]
;   (distinct (remove nil? (map #(let [stem (.stem (lang stemmers) %)]
;                     (if (empty? stem) nil (apply min-key count stem))) s))))

