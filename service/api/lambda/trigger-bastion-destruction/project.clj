(defproject trigger-bastion-destruction "0.1.0-SNAPSHOT"
  :description "trigger-bastion-destruction"
  :dependencies [[org.clojure/clojure "1.9.0"]
                 [org.clojure/clojurescript "1.10.439"]]
  :plugins [[lein-cljsbuild "1.1.7"]]
  :cljsbuild {:builds [{:source-paths ["src"]
                        :compiler     {:output-to      "target/trigger-bastion-destruction/handler.js"
                                       :output-dir     "target/trigger-bastion-destruction"
                                       :asset-path     ""
                                       :source-map     false
                                       :target         :nodejs
                                       :main           "trigger-bastion-destruction.handler"
                                       :optimizations  :none
                                       :parallel-build true}}]})
