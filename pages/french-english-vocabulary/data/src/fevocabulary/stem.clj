(ns fevocabulary.stem
  (:use opennlp.nlp
        opennlp.tools.lazy)
  (:import java.io.File
           com.atlascopco.hunspell.Hunspell))

;; tokenization and counting

(def tokenizers
  {:english (make-tokenizer "/opt/fev/models/en-token.bin")
   :french (make-tokenizer "/opt/fev/models/fr-token.bin")})

(def stemmers
  {:english (Hunspell. "/opt/fev/models/en.dic" "/opt/fev/models/en.aff")
   :french (Hunspell. "/opt/fev/models/fr.dic" "/opt/fev/models/fr.aff")})

(def namefinders-person
  {:a (make-name-finder "/opt/fev/models/namefind/en-ner-person.bin")
   :b (make-name-finder "/opt/fev/models/namefind/fr-ner-person.bin")})

(def namefinders-location
  {:a (make-name-finder "/opt/fev/models/namefind/en-ner-location.bin")
   :b (make-name-finder "/opt/fev/models/namefind/fr-ner-location.bin")})

(def namefinders-static
  {:a (clojure.string/split (slurp "/opt/fev/models/namefind/names.txt") #"\s+" )
   :b (clojure.string/split (slurp "/opt/fev/models/namefind/places.txt") #"\s+" )})

(defn remove-punctuation [s]
    (clojure.string/replace s #"[^a-z'`’\p{L}]]" ""))

(defn split-hyphenation [s]
    (clojure.string/split s #"-"))

(defn tokenize [text lang]
          (map remove-punctuation ((lang tokenizers) text)))

(defn remove-name [word lang]
  (if (empty? ((:a namefinders-person) word ))
    (if (empty? ((:b namefinders-person) word)) (get word 0) "") ""))

(defn remove-location [word lang]
  (if (empty? ((:a namefinders-location) word ))
    (if (empty? ((:b namefinders-location) word)) (get word 0) "") ""))

(defn remove-static [word-u lang]
  (let [word (clojure.string/lower-case word-u)]
    (if (nil? (some #{word} (:a namefinders-static ) ))
      (if (nil?  (some #{word} (:b namefinders-static ) )) word "") "")))

(defn filter-stem [lang token]
  (let [word (remove-name [token] lang)
        word-l (remove-location [word] lang)
        word-s (remove-static word-l lang)
        stem (if (empty? word-s) "" (.stem (lang stemmers) word-s))]
    (if (empty? stem) "" (apply min-key count stem))))

(defn stem-word [token lang]
  (clojure.string/lower-case (filter-stem lang token)))

(defn stem [s lang]
  (map clojure.string/lower-case
       (map (partial filter-stem lang) s)))

