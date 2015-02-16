(ns fevocabulary.write-example
  (:require [clojure.data.json :as json])
  (:use [fevocabulary.stem :only [tokenizers tokenize stem]]))

;; some text

(def moby "Call me Ishmael. Some years ago — never mind how long precisely — having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen, and regulating the circulation. Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul; whenever I find myself involuntarily pausing before coffin warehouses, and bringing up the rear of every funeral I meet; and especially whenever my hypos get such an upper hand of me, that it requires a strong moral principle to prevent me from deliberately stepping into the street, and methodically knocking people’s hats off — then, I account it high time to get to sea as soon as I can. This is my substitute for pistol and ball.")
(def proust "Longtemps, je me suis couché de bonne heure. Parfois, à peine ma bougie éteinte, mes yeux se fermaient si vite que je n’avais pas le temps de me dire : « Je m’endors. » Et, une demi-heure après, la pensée qu’il était temps de chercher le sommeil m’éveillait ; je voulais poser le volume que je croyais avoir encore dans les mains et souffler ma lumière ; je n’avais pas cessé en dormant de faire des réflexions sur ce que je venais de lire, mais ces réflexions avaient pris un tour un peu particulier ; il me semblait que j’étais moi-même ce dont parlait l’ouvrage : une église, un quatuor, la rivalité de François Ier et de Charles-Quint. Cette croyance survivait pendant quelques secondes à mon réveil ; elle ne choquait pas ma raison, mais pesait comme des écailles sur mes yeux et les empêchait de se rendre compte que le bougeoir n’était pas allumé.")

(defn build-tree [lang text]
  (let [words ((lang tokenizers) text)
        tokens (tokenize text lang)
        stems (stem tokens lang)]
      (map (fn [w t s] {:word w :token t :stem s}) words tokens stems)))

(defn find-dupes [tokens]
  (loop [token (first tokens)
         remain (rest tokens)
         pool-words `()
         pool-tokens `()
         pool-stems `()
         all `()]
    (let [unique-word (not-any? (partial = (:word token)) pool-words)
          unique-token (not-any? (partial = (:token token)) pool-tokens)
          unique-stems (not-any? (partial = (:stem token)) pool-stems)]
      (if (empty? remain)
        (reverse all)
        (recur (first remain)
                (rest remain)
                (if unique-word (conj pool-words (:word token)) pool-words)
                (if unique-token (conj pool-tokens (:token token)) pool-tokens)
                (if unique-stems (conj pool-stems (:stem token)) pool-stems)
                (conj all (assoc token
                                 :unique-word unique-word
                                 :unique-token unique-token
                                 :unique-stem unique-stems)))))))

(defn write-example-json [output-file]
  (spit output-file
        (json/write-str {:english  (find-dupes (build-tree :english moby))
                         :french (find-dupes (build-tree :french proust))})))

(write-example-json "example.json")
 (find-dupes (build-tree :french proust))
